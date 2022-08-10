// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Predeploys } from "../libraries/Predeploys.sol";
import { StandardBridge } from "../universal/StandardBridge.sol";
import { Semver } from "../universal/Semver.sol";

/**
 * @custom:proxied
 * @title L1StandardBridge
 * @notice The L1StandardBridge is responsible for transfering ETH and ERC20 tokens between L1 and
 *         L2. ERC20 tokens deposited into L2 are escrowed within this contract until withdrawal.
 *         ETH is transferred to and escrowed within the OptimismPortal contract.
 */
contract L1StandardBridge is StandardBridge, Semver {
    /**
     * @custom:legacy
     * @notice Emitted whenever a deposit of ETH from L1 into L2 is initiated.
     *
     * @param from      Address of the depositor.
     * @param to        Address of the recipient on L2.
     * @param amount    Amount of ETH deposited.
     * @param extraData Extra data attached to the deposit.
     */
    event ETHDepositInitiated(
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @custom:legacy
     * @notice Emitted whenever a withdrawal of ETH from L2 to L1 is finalized.
     *
     * @param from      Address of the withdrawer.
     * @param to        Address of the recipient on L1.
     * @param amount    Amount of ETH withdrawn.
     * @param extraData Extra data attached to the withdrawal.
     */
    event ETHWithdrawalFinalized(
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @custom:legacy
     * @notice Emitted whenever an ERC20 deposit is initiated.
     *
     * @param l1Token   Address of the token on L1.
     * @param l2Token   Address of the corresponding token on L2.
     * @param from      Address of the depositor.
     * @param to        Address of the recipient on L2.
     * @param amount    Amount of the ERC20 deposited.
     * @param extraData Extra data attached to the deposit.
     */
    event ERC20DepositInitiated(
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @custom:legacy
     * @notice Emitted whenever an ERC20 withdrawal is finalized.
     *
     * @param l1Token   Address of the token on L1.
     * @param l2Token   Address of the corresponding token on L2.
     * @param from      Address of the withdrawer.
     * @param to        Address of the recipient on L1.
     * @param amount    Amount of the ERC20 withdrawn.
     * @param extraData Extra data attached to the withdrawal.
     */
    event ERC20WithdrawalFinalized(
        address indexed l1Token,
        address indexed l2Token,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @custom:semver 0.0.1
     *
     * @param _messenger Address of the L1CrossDomainMessenger.
     */
    constructor(address payable _messenger) Semver(0, 0, 1) {
        initialize(_messenger);
    }

    /**
     * @custom:legacy
     * @notice Finalizes a withdrawal of ERC20 tokens from L2.
     *
     * @param _l1Token   Address of the token on L1.
     * @param _l2Token   Address of the corresponding token on L2.
     * @param _from      Address of the withdrawer on L2.
     * @param _to        Address of the recipient on L1.
     * @param _amount    Amount of ETH to withdraw.
     * @param _extraData Optional data forwarded from L2.
     */
    function finalizeERC20Withdrawal(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _extraData
    ) external onlyOtherBridge {
        emit ERC20WithdrawalFinalized(_l1Token, _l2Token, _from, _to, _amount, _extraData);
        finalizeBridgeERC20(_l1Token, _l2Token, _from, _to, _amount, _extraData);
    }

    /**
     * @custom:legacy
     * @notice Deposits some amount of ETH into the sender's account on L2.
     *
     * @param _minGasLimit Minimum gas limit for the deposit message on L2.
     * @param _extraData   Optional data to forward to L2. Data supplied here will not be used to
     *                     execute any code on L2 and is only emitted as extra data for the
     *                     convenience of off-chain tooling.
     */
    function depositETH(uint32 _minGasLimit, bytes calldata _extraData) external payable onlyEOA {
        _initiateETHDeposit(msg.sender, msg.sender, _minGasLimit, _extraData);
    }

    /**
     * @custom:legacy
     * @notice Deposits some amount of ETH into a target account on L2.
     *         Note that if ETH is sent to a contract on L2 and the call fails, then that ETH will
     *         be locked in the L2StandardBridge. ETH may be recoverable if the call can be
     *         successfully replayed by increasing the amount of gas supplied to the call. If the
     *         call will fail for any amount of gas, then the ETH will be locked permanently.
     *
     * @param _to          Address of the recipient on L2.
     * @param _minGasLimit Minimum gas limit for the deposit message on L2.
     * @param _extraData   Optional data to forward to L2. Data supplied here will not be used to
     *                     execute any code on L2 and is only emitted as extra data for the
     *                     convenience of off-chain tooling.
     */
    function depositETHTo(
        address _to,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external payable {
        _initiateETHDeposit(msg.sender, _to, _minGasLimit, _extraData);
    }

    /**
     * @custom:legacy
     * @notice Deposits some amount of ERC20 tokens into the sender's account on L2.
     *
     * @param _l1Token     Address of the L1 token being deposited.
     * @param _l2Token     Address of the corresponding token on L2.
     * @param _amount      Amount of the ERC20 to deposit.
     * @param _minGasLimit Minimum gas limit for the deposit message on L2.
     * @param _extraData   Optional data to forward to L2. Data supplied here will not be used to
     *                     execute any code on L2 and is only emitted as extra data for the
     *                     convenience of off-chain tooling.
     */
    function depositERC20(
        address _l1Token,
        address _l2Token,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external virtual onlyEOA {
        _initiateERC20Deposit(
            _l1Token,
            _l2Token,
            msg.sender,
            msg.sender,
            _amount,
            _minGasLimit,
            _extraData
        );
    }

    /**
     * @custom:legacy
     * @notice Deposits some amount of ERC20 tokens into a target account on L2.
     *
     * @param _l1Token     Address of the L1 token being deposited.
     * @param _l2Token     Address of the corresponding token on L2.
     * @param _to          Address of the recipient on L2.
     * @param _amount      Amount of the ERC20 to deposit.
     * @param _minGasLimit Minimum gas limit for the deposit message on L2.
     * @param _extraData   Optional data to forward to L2. Data supplied here will not be used to
     *                     execute any code on L2 and is only emitted as extra data for the
     *                     convenience of off-chain tooling.
     */
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external virtual {
        _initiateERC20Deposit(
            _l1Token,
            _l2Token,
            msg.sender,
            _to,
            _amount,
            _minGasLimit,
            _extraData
        );
    }

    /**
     * @custom:legacy
     * @notice Finalizes a withdrawal of ETH from L2.
     *
     * @param _from      Address of the withdrawer on L2.
     * @param _to        Address of the recipient on L1.
     * @param _amount    Amount of ETH to withdraw.
     * @param _extraData Optional data forwarded from L2.
     */
    function finalizeETHWithdrawal(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _extraData
    ) external payable onlyOtherBridge {
        emit ETHWithdrawalFinalized(_from, _to, _amount, _extraData);
        finalizeBridgeETH(_from, _to, _amount, _extraData);
    }

    /**
     * @custom:legacy
     * @notice Retrieves the access of the corresponding L2 bridge contract.
     *
     * @return Address of the corresponding L2 bridge contract.
     */
    function l2TokenBridge() external view returns (address) {
        return address(otherBridge);
    }

    /**
     * @notice Initializer.
     *
     * @param _messenger Address of the L1CrossDomainMessenger.
     */
    function initialize(address payable _messenger) public initializer {
        __StandardBridge_init(_messenger, payable(Predeploys.L2_STANDARD_BRIDGE));
    }

    /**
     * @notice Internal function for initiating an ETH deposit.
     *
     * @param _from        Address of the sender on L1.
     * @param _to          Address of the recipient on L2.
     * @param _minGasLimit Minimum gas limit for the deposit message on L2.
     * @param _extraData   Optional data to forward to L2.
     */
    function _initiateETHDeposit(
        address _from,
        address _to,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) internal {
        emit ETHDepositInitiated(_from, _to, msg.value, _extraData);
        _initiateBridgeETH(_from, _to, msg.value, _minGasLimit, _extraData);
    }

    /**
     * @notice Internal function for initiating an ERC20 deposit.
     *
     * @param _l1Token     Address of the L1 token being deposited.
     * @param _l2Token     Address of the corresponding token on L2.
     * @param _from        Address of the sender on L1.
     * @param _to          Address of the recipient on L2.
     * @param _amount      Amount of the ERC20 to deposit.
     * @param _minGasLimit Minimum gas limit for the deposit message on L2.
     * @param _extraData   Optional data to forward to L2.
     */
    function _initiateERC20Deposit(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) internal {
        emit ERC20DepositInitiated(_l1Token, _l2Token, _from, _to, _amount, _extraData);
        _initiateBridgeERC20(_l1Token, _l2Token, _from, _to, _amount, _minGasLimit, _extraData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Predeploys
 * @notice Contains constant addresses for contracts that are pre-deployed to the L2 system.
 */
library Predeploys {
    /**
     * @notice Address of the L2ToL1MessagePasser predeploy.
     */
    address internal constant L2_TO_L1_MESSAGE_PASSER = 0x4200000000000000000000000000000000000000;

    /**
     * @notice Address of the L2CrossDomainMessenger predeploy.
     */
    address internal constant L2_CROSS_DOMAIN_MESSENGER =
        0x4200000000000000000000000000000000000007;

    /**
     * @notice Address of the L2StandardBridge predeploy.
     */
    address internal constant L2_STANDARD_BRIDGE = 0x4200000000000000000000000000000000000010;

    /**
     * @notice Address of the SequencerFeeWallet predeploy.
     */
    address internal constant SEQUENCER_FEE_WALLET = 0x4200000000000000000000000000000000000011;

    /**
     * @notice Address of the OptimismMintableERC20Factory predeploy.
     */
    address internal constant OPTIMISM_MINTABLE_ERC20_FACTORY =
        0x4200000000000000000000000000000000000012;

    /**
     * @notice Address of the L1Block predeploy.
     */
    address internal constant L1_BLOCK_ATTRIBUTES = 0x4200000000000000000000000000000000000015;

    /**
     * @custom:legacy
     * @notice Address of the L1MessageSender predeploy. Deprecated. Use L2CrossDomainMessenger
     *         or access tx.origin (or msg.sender) in a L1 to L2 transaction instead.
     */
    address internal constant L1_MESSAGE_SENDER = 0x4200000000000000000000000000000000000001;

    /**
     * @custom:legacy
     * @notice Address of the DeployerWhitelist predeploy. No longer active.
     */
    address internal constant DEPLOYER_WHITELIST = 0x4200000000000000000000000000000000000002;

    /**
     * @custom:legacy
     * @notice Address of the LegacyERC20ETH predeploy. Deprecated. Balances are migrated to the
     *         state trie as of the Bedrock upgrade. Contract has been locked and write functions
     *         can no longer be accessed.
     */
    address internal constant LEGACY_ERC20_ETH = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;

    /**
     * @custom:legacy
     * @notice Address of the L1BlockNumber predeploy. Deprecated. Use the L1Block predeploy
     *         instead, which exposes more information about the L1 state.
     */
    address internal constant L1_BLOCK_NUMBER = 0x4200000000000000000000000000000000000013;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IRemoteToken, IL1Token } from "./SupportedInterfaces.sol";
import { CrossDomainMessenger } from "./CrossDomainMessenger.sol";
import { OptimismMintableERC20 } from "./OptimismMintableERC20.sol";

/**
 * @title StandardBridge
 * @notice StandardBridge is a base contract for the L1 and L2 standard ERC20 bridges.
 */
abstract contract StandardBridge is Initializable {
    using SafeERC20 for IERC20;

    /**
     * @notice The L2 gas limit set when eth is depoisited using the receive() function.
     */
    uint32 internal constant RECEIVE_DEFAULT_GAS_LIMIT = 200_000;

    /**
     * @notice Messenger contract on this domain.
     */
    CrossDomainMessenger public messenger;

    /**
     * @notice Corresponding bridge on the other domain.
     */
    StandardBridge public otherBridge;

    /**
     * @notice Mapping that stores deposits for a given pair of local and remote tokens.
     */
    mapping(address => mapping(address => uint256)) public deposits;

    /**
     * @notice Emitted when an ETH bridge is initiated to the other chain.
     *
     * @param from      Address of the sender.
     * @param to        Address of the receiver.
     * @param amount    Amount of ETH sent.
     * @param extraData Extra data sent with the transaction.
     */
    event ETHBridgeInitiated(
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @notice Emitted when an ETH bridge is finalized on this chain.
     *
     * @param from      Address of the sender.
     * @param to        Address of the receiver.
     * @param amount    Amount of ETH sent.
     * @param extraData Extra data sent with the transaction.
     */
    event ETHBridgeFinalized(
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @notice Emitted when an ERC20 bridge is initiated to the other chain.
     *
     * @param localToken  Address of the ERC20 on this chain.
     * @param remoteToken Address of the ERC20 on the remote chain.
     * @param from        Address of the sender.
     * @param to          Address of the receiver.
     * @param amount      Amount of ETH sent.
     * @param extraData   Extra data sent with the transaction.
     */
    event ERC20BridgeInitiated(
        address indexed localToken,
        address indexed remoteToken,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @notice Emitted when an ERC20 bridge is finalized on this chain.
     *
     * @param localToken  Address of the ERC20 on this chain.
     * @param remoteToken Address of the ERC20 on the remote chain.
     * @param from        Address of the sender.
     * @param to          Address of the receiver.
     * @param amount      Amount of ETH sent.
     * @param extraData   Extra data sent with the transaction.
     */
    event ERC20BridgeFinalized(
        address indexed localToken,
        address indexed remoteToken,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @notice Emitted when an ERC20 bridge to this chain fails.
     *
     * @param localToken  Address of the ERC20 on this chain.
     * @param remoteToken Address of the ERC20 on the remote chain.
     * @param from        Address of the sender.
     * @param to          Address of the receiver.
     * @param amount      Amount of ETH sent.
     * @param extraData   Extra data sent with the transaction.
     */
    event ERC20BridgeFailed(
        address indexed localToken,
        address indexed remoteToken,
        address indexed from,
        address to,
        uint256 amount,
        bytes extraData
    );

    /**
     * @notice Only allow EOAs to call the functions. Note that this is not safe against contracts
     *         calling code within their constructors, but also doesn't really matter since we're
     *         just trying to prevent users accidentally depositing with smart contract wallets.
     */
    modifier onlyEOA() {
        require(
            !Address.isContract(msg.sender),
            "StandardBridge: function can only be called from an EOA"
        );
        _;
    }

    /**
     * @notice Ensures that the caller is a cross-chain message from the other bridge.
     */
    modifier onlyOtherBridge() {
        require(
            msg.sender == address(messenger) &&
                messenger.xDomainMessageSender() == address(otherBridge),
            "StandardBridge: function can only be called from the other bridge"
        );
        _;
    }

    /**
     * @notice Ensures that the caller is this contract.
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "StandardBridge: function can only be called by self");
        _;
    }

    /**
     * @notice Allows EOAs to deposit ETH by sending directly to the bridge.
     */
    receive() external payable onlyEOA {
        _initiateBridgeETH(msg.sender, msg.sender, msg.value, RECEIVE_DEFAULT_GAS_LIMIT, bytes(""));
    }

    /**
     * @notice Sends ETH to the sender's address on the other chain.
     *
     * @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function bridgeETH(uint32 _minGasLimit, bytes calldata _extraData) public payable onlyEOA {
        _initiateBridgeETH(msg.sender, msg.sender, msg.value, _minGasLimit, _extraData);
    }

    /**
     * @notice Sends ETH to a receiver's address on the other chain. Note that if ETH is sent to a
     *         smart contract and the call fails, the ETH will be temporarily locked in the
     *         StandardBridge on the other chain until the call is replayed. If the call cannot be
     *         replayed with any amount of gas (call always reverts), then the ETH will be
     *         permanently locked in the StandardBridge on the other chain.
     *
     * @param _to          Address of the receiver.
     * @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function bridgeETHTo(
        address _to,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) public payable {
        _initiateBridgeETH(msg.sender, _to, msg.value, _minGasLimit, _extraData);
    }

    /**
     * @notice Sends ERC20 tokens to the sender's address on the other chain. Note that if the
     *         ERC20 token on the other chain does not recognize the local token as the correct
     *         pair token, the ERC20 bridge will fail and the tokens will be returned to sender on
     *         this chain.
     *
     * @param _localToken  Address of the ERC20 on this chain.
     * @param _remoteToken Address of the corresponding token on the remote chain.
     * @param _amount      Amount of local tokens to deposit.
     * @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function bridgeERC20(
        address _localToken,
        address _remoteToken,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) public virtual onlyEOA {
        _initiateBridgeERC20(
            _localToken,
            _remoteToken,
            msg.sender,
            msg.sender,
            _amount,
            _minGasLimit,
            _extraData
        );
    }

    /**
     * @notice Sends ERC20 tokens to a receiver's address on the other chain. Note that if the
     *         ERC20 token on the other chain does not recognize the local token as the correct
     *         pair token, the ERC20 bridge will fail and the tokens will be returned to sender on
     *         this chain.
     *
     * @param _localToken  Address of the ERC20 on this chain.
     * @param _remoteToken Address of the corresponding token on the remote chain.
     * @param _to          Address of the receiver.
     * @param _amount      Amount of local tokens to deposit.
     * @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) public virtual {
        _initiateBridgeERC20(
            _localToken,
            _remoteToken,
            msg.sender,
            _to,
            _amount,
            _minGasLimit,
            _extraData
        );
    }

    /**
     * @notice Finalizes an ETH bridge on this chain. Can only be triggered by the other
     *         StandardBridge contract on the remote chain.
     *
     * @param _from      Address of the sender.
     * @param _to        Address of the receiver.
     * @param _amount    Amount of ETH being bridged.
     * @param _extraData Extra data to be sent with the transaction. Note that the recipient will
     *                   not be triggered with this data, but it will be emitted and can be used
     *                   to identify the transaction.
     */
    function finalizeBridgeETH(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _extraData
    ) public payable onlyOtherBridge {
        require(msg.value == _amount, "StandardBridge: amount sent does not match amount required");
        require(_to != address(this), "StandardBridge: cannot send to self");

        emit ETHBridgeFinalized(_from, _to, _amount, _extraData);
        (bool success, ) = _to.call{ value: _amount }(new bytes(0));
        require(success, "StandardBridge: ETH transfer failed");
    }

    /**
     * @notice Finalizes an ERC20 bridge on this chain. Can only be triggered by the other
     *         StandardBridge contract on the remote chain.
     *
     *
     * @param _localToken  Address of the ERC20 on this chain.
     * @param _remoteToken Address of the corresponding token on the remote chain.
     * @param _from        Address of the sender.
     * @param _to          Address of the receiver.
     * @param _amount      Amount of ETH being bridged.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function finalizeBridgeERC20(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _extraData
    ) public onlyOtherBridge {
        try this.completeOutboundTransfer(_localToken, _remoteToken, _to, _amount) {
            emit ERC20BridgeFinalized(_localToken, _remoteToken, _from, _to, _amount, _extraData);
        } catch {
            // Something went wrong during the bridging process, return to sender.
            // Can happen if a bridge UI specifies the wrong L2 token.
            // We reverse the to and from addresses to make sure the tokens are returned to the
            // sender on the other chain and preserve the accuracy of accounting based on emitted
            // events.
            _initiateBridgeERC20Unchecked(
                _localToken,
                _remoteToken,
                _to,
                _from,
                _amount,
                0, // _minGasLimit, 0 is fine here
                _extraData
            );
            emit ERC20BridgeFailed(_localToken, _remoteToken, _from, _to, _amount, _extraData);
        }
    }

    /**
     * @notice Completes an outbound token transfer. Public function, but can only be called by
     *         this contract. It's security critical that there be absolutely no way for anyone to
     *         trigger this function, except by explicit trigger within this contract. Used as a
     *         simple way to be able to try/catch any type of revert that could occur during an
     *         ERC20 mint/transfer.
     *
     * @param _localToken  Address of the ERC20 on this chain.
     * @param _remoteToken Address of the corresponding token on the remote chain.
     * @param _to          Address of the receiver.
     * @param _amount      Amount of ETH being bridged.
     */
    function completeOutboundTransfer(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount
    ) public onlySelf {
        // Make sure external function calls can't be used to trigger calls to
        // completeOutboundTransfer. We only make external (write) calls to _localToken.
        require(_localToken != address(this), "StandardBridge: local token cannot be self");

        if (_isOptimismMintableERC20(_localToken)) {
            require(
                _isCorrectTokenPair(_localToken, _remoteToken),
                "StandardBridge: wrong remote token for Optimism Mintable ERC20 local token"
            );

            OptimismMintableERC20(_localToken).mint(_to, _amount);
        } else {
            deposits[_localToken][_remoteToken] = deposits[_localToken][_remoteToken] - _amount;
            IERC20(_localToken).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice Initializer.
     *
     * @param _messenger   Address of CrossDomainMessenger on this network.
     * @param _otherBridge Address of the other StandardBridge contract.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __StandardBridge_init(address payable _messenger, address payable _otherBridge)
        internal
        onlyInitializing
    {
        messenger = CrossDomainMessenger(_messenger);
        otherBridge = StandardBridge(_otherBridge);
    }

    /**
     * @notice Initiates a bridge of ETH through the CrossDomainMessenger.
     *
     * @param _from        Address of the sender.
     * @param _to          Address of the receiver.
     * @param _amount      Amount of ETH being bridged.
     * @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function _initiateBridgeETH(
        address _from,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes memory _extraData
    ) internal {
        emit ETHBridgeInitiated(_from, _to, _amount, _extraData);

        messenger.sendMessage{ value: _amount }(
            address(otherBridge),
            abi.encodeWithSelector(
                this.finalizeBridgeETH.selector,
                _from,
                _to,
                _amount,
                _extraData
            ),
            _minGasLimit
        );
    }

    /**
     * @notice Sends ERC20 tokens to a receiver's address on the other chain.
     *
     * @param _localToken  Address of the ERC20 on this chain.
     * @param _remoteToken Address of the corresponding token on the remote chain.
     * @param _to          Address of the receiver.
     * @param _amount      Amount of local tokens to deposit.
     * @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function _initiateBridgeERC20(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) internal {
        // Make sure external function calls can't be used to trigger calls to
        // completeOutboundTransfer. We only make external (write) calls to _localToken.
        require(_localToken != address(this), "StandardBridge: local token cannot be self");

        if (_isOptimismMintableERC20(_localToken)) {
            require(
                _isCorrectTokenPair(_localToken, _remoteToken),
                "StandardBridge: wrong remote token for Optimism Mintable ERC20 local token"
            );

            OptimismMintableERC20(_localToken).burn(_from, _amount);
        } else {
            IERC20(_localToken).safeTransferFrom(_from, address(this), _amount);
            deposits[_localToken][_remoteToken] = deposits[_localToken][_remoteToken] + _amount;
        }

        _initiateBridgeERC20Unchecked(
            _localToken,
            _remoteToken,
            _from,
            _to,
            _amount,
            _minGasLimit,
            _extraData
        );
    }

    /**
     * @notice Sends ERC20 tokens to a receiver's address on the other chain WITHOUT doing any
     *         validation. Be EXTREMELY careful when using this function.
     *
     * @param _localToken  Address of the ERC20 on this chain.
     * @param _remoteToken Address of the corresponding token on the remote chain.
     * @param _to          Address of the receiver.
     * @param _amount      Amount of local tokens to deposit.
     * @param _minGasLimit Minimum amount of gas that the bridge can be relayed with.
     * @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
     *                     not be triggered with this data, but it will be emitted and can be used
     *                     to identify the transaction.
     */
    function _initiateBridgeERC20Unchecked(
        address _localToken,
        address _remoteToken,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) internal {
        messenger.sendMessage(
            address(otherBridge),
            abi.encodeWithSelector(
                this.finalizeBridgeERC20.selector,
                // Because this call will be executed on the remote chain, we reverse the order of
                // the remote and local token addresses relative to their order in the
                // finalizeBridgeERC20 function.
                _remoteToken,
                _localToken,
                _from,
                _to,
                _amount,
                _extraData
            ),
            _minGasLimit
        );

        emit ERC20BridgeInitiated(_localToken, _remoteToken, _from, _to, _amount, _extraData);
    }

    /**
     * @notice Checks if a given address is an OptimismMintableERC20. Not perfect, but good enough.
     *         Just the way we like it.
     *
     * @param _token Address of the token to check.
     *
     * @return True if the token is an OptimismMintableERC20.
     */
    function _isOptimismMintableERC20(address _token) internal view returns (bool) {
        return ERC165Checker.supportsInterface(_token, type(IL1Token).interfaceId);
    }

    /**
     * @notice Checks if the "other token" is the correct pair token for the OptimismMintableERC20.
     *
     * @param _mintableToken OptimismMintableERC20 to check against.
     * @param _otherToken    Pair token to check.
     *
     * @return True if the other token is the correct pair token for the OptimismMintableERC20.
     */
    function _isCorrectTokenPair(address _mintableToken, address _otherToken)
        internal
        view
        returns (bool)
    {
        return _otherToken == OptimismMintableERC20(_mintableToken).l1Token();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Semver
 * @notice Semver is a simple contract for managing contract versions.
 */
contract Semver {
    /**
     * @notice Contract version number (major).
     */
    // solhint-disable-next-line var-name-mixedcase
    uint256 private immutable MAJOR_VERSION;

    /**
     * @notice Contract version number (minor).
     */
    // solhint-disable-next-line var-name-mixedcase
    uint256 private immutable MINOR_VERSION;

    /**
     * @notice Contract version number (patch).
     */
    // solhint-disable-next-line var-name-mixedcase
    uint256 private immutable PATCH_VERSION;

    /**
     * @param _major Version number (major).
     * @param _minor Version number (minor).
     * @param _patch Version number (patch).
     */
    constructor(
        uint256 _major,
        uint256 _minor,
        uint256 _patch
    ) {
        MAJOR_VERSION = _major;
        MINOR_VERSION = _minor;
        PATCH_VERSION = _patch;
    }

    /**
     * @notice Returns the full semver contract version.
     *
     * @return Semver contract version as a string.
     */
    function version() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    Strings.toString(MAJOR_VERSION),
                    ".",
                    Strings.toString(MINOR_VERSION),
                    ".",
                    Strings.toString(PATCH_VERSION)
                )
            );
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import this here to make it available just by importing this file
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRemoteToken {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function remoteToken() external;
}

interface IL1Token {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function l1Token() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { ExcessivelySafeCall } from "excessively-safe-call/src/ExcessivelySafeCall.sol";
import { Hashing } from "../libraries/Hashing.sol";
import { Encoding } from "../libraries/Encoding.sol";

/**
 * @title CrossDomainMessenger
 * @notice CrossDomainMessenger is a base contract that provides the core logic for the L1 and L2
 *         cross-chain messenger contracts. It's designed to be a universal interface that only
 *         needs to be extended slightly to provide low-level message passing functionality on each
 *         chain it's deployed on. Currently only designed for message passing between two paired
 *         chains and does not support one-to-many interactions.
 */
abstract contract CrossDomainMessenger is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @notice Current message version identifier.
     */
    uint16 public constant MESSAGE_VERSION = 1;

    /**
     * @notice Constant overhead added to the base gas for a message.
     */
    uint32 public constant MIN_GAS_CONSTANT_OVERHEAD = 200_000;

    /**
     * @notice Numerator for dynamic overhead added to the base gas for a message.
     */
    uint32 public constant MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR = 1016;

    /**
     * @notice Denominator for dynamic overhead added to the base gas for a message.
     */
    uint32 public constant MIN_GAS_DYNAMIC_OVERHEAD_DENOMINATOR = 1000;

    /**
     * @notice Extra gas added to base gas for each byte of calldata in a message.
     */
    uint32 public constant MIN_GAS_CALLDATA_OVERHEAD = 16;

    /**
     * @notice Minimum amount of gas required to relay a message.
     */
    uint256 internal constant RELAY_GAS_REQUIRED = 45_000;

    /**
     * @notice Amount of gas held in reserve to guarantee that relay execution completes.
     */
    uint256 internal constant RELAY_GAS_BUFFER = RELAY_GAS_REQUIRED - 5000;

    /**
     * @notice Initial value for the xDomainMsgSender variable. We set this to a non-zero value
     *         because performing an SSTORE on a non-zero value is significantly cheaper than on a
     *         zero value.
     */
    address internal constant DEFAULT_XDOMAIN_SENDER = 0x000000000000000000000000000000000000dEaD;

    /**
     * @notice Mapping of message hashes to boolean receipt values. Note that a message will only
     *         be present in this mapping if it failed to be relayed on this chain at least once.
     *         If a message is successfully relayed on the first attempt, then it will only be
     *         present within the successfulMessages mapping.
     */
    mapping(bytes32 => bool) public successfulMessages;

    /**
     * @notice Address of the sender of the currently executing message on the other chain. If the
     *         value of this variable is the default value (0x00000000...dead) then no message is
     *         currently being executed. Use the xDomainMessageSender getter which will throw an
     *         error if this is the case.
     */
    address internal xDomainMsgSender;

    /**
     * @notice Nonce for the next message to be sent, without the message version applied. Use the
     *         messageNonce getter which will insert the message version into the nonce to give you
     *         the actual nonce to be used for the message.
     */
    uint240 internal msgNonce;

    /**
     * @notice Address of the paired CrossDomainMessenger contract on the other chain.
     */
    address public otherMessenger;

    /**
     * @notice Mapping of message hashes to boolean receipt values. Note that a message will only
     *         be present in this mapping if it failed to be relayed on this chain at least once.
     *         If a message is successfully relayed on the first attempt, then it will only be
     *         present within the successfulMessages mapping.
     */
    mapping(bytes32 => bool) public receivedMessages;

    /**
     * @notice Mapping of blocked system addresses. Note that this is NOT a mapping of blocked user
     *         addresses and cannot be used to prevent users from sending or receiving messages.
     *         This is ONLY used to prevent the execution of messages to specific system addresses
     *         that could cause security issues, e.g., having the CrossDomainMessenger send
     *         messages to itself.
     */
    mapping(address => bool) public blockedSystemAddresses;

    /**
     * @notice Emitted whenever a message is sent to the other chain.
     *
     * @param target       Address of the recipient of the message.
     * @param sender       Address of the sender of the message.
     * @param message      Message to trigger the recipient address with.
     * @param messageNonce Unique nonce attached to the message.
     * @param gasLimit     Minimum gas limit that the message can be executed with.
     */
    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );

    /**
     * @notice Additional event data to emit, required as of Bedrock. Cannot be merged with the
     *         SentMessage event without breaking the ABI of this contract, this is good enough.
     *
     * @param sender Address of the sender of the message.
     * @param value  ETH value sent along with the message to the recipient.
     */
    event SentMessageExtension1(address indexed sender, uint256 value);

    /**
     * @notice Emitted whenever a message is successfully relayed on this chain.
     *
     * @param msgHash Hash of the message that was relayed.
     */
    event RelayedMessage(bytes32 indexed msgHash);

    /**
     * @notice Emitted whenever a message fails to be relayed on this chain.
     *
     * @param msgHash Hash of the message that failed to be relayed.
     */
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /**
     * @notice Allows the owner of this contract to temporarily pause message relaying. Backup
     *         security mechanism just in case. Owner should be the same as the upgrade wallet to
     *         maintain the security model of the system as a whole.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allows the owner of this contract to resume message relaying once paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sends a message to some target address on the other chain.
     *
     * @param _target      Target contract or wallet address.
     * @param _message     Message to trigger the target address with.
     * @param _minGasLimit Minimum gas limit that the message can be executed with.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _minGasLimit
    ) external payable {
        // Triggers a message to the other messenger. Note that the amount of gas provided to the
        // message is the amount of gas requested by the user PLUS the base gas value. We want to
        // guarantee the property that the call to the target contract will always have at least
        // the minimum gas limit specified by the user.
        _sendMessage(
            otherMessenger,
            baseGas(_message, _minGasLimit),
            msg.value,
            abi.encodeWithSelector(
                this.relayMessage.selector,
                messageNonce(),
                msg.sender,
                _target,
                msg.value,
                _minGasLimit,
                _message
            )
        );

        emit SentMessage(_target, msg.sender, _message, messageNonce(), _minGasLimit);
        emit SentMessageExtension1(msg.sender, msg.value);

        unchecked {
            ++msgNonce;
        }
    }

    /**
     * @notice Relays a message that was sent by the other CrossDomainMessenger contract. Can only
     *         be executed via cross-chain call from the other messenger OR if the message was
     *         already received once and is currently being replayed.
     *
     * @param _nonce       Nonce of the message being relayed.
     * @param _sender      Address of the user who sent the message.
     * @param _target      Address that the message is targeted at.
     * @param _value       ETH value to send with the message.
     * @param _minGasLimit Minimum amount of gas that the message can be executed with.
     * @param _message     Message to send to the target.
     */
    function relayMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes calldata _message
    ) external payable nonReentrant whenNotPaused {
        bytes32 versionedHash = Hashing.hashCrossDomainMessage(
            _nonce,
            _sender,
            _target,
            _value,
            _minGasLimit,
            _message
        );

        if (_isOtherMessenger()) {
            // Should never happen.
            require(msg.value == _value, "CrossDomainMessenger: mismatched message value");
        } else {
            require(
                msg.value == 0,
                "CrossDomainMessenger: value must be zero unless message is from a system address"
            );

            require(
                receivedMessages[versionedHash],
                "CrossDomainMessenger: message cannot be replayed"
            );
        }

        require(
            blockedSystemAddresses[_target] == false,
            "CrossDomainMessenger: cannot send message to blocked system address"
        );

        require(
            successfulMessages[versionedHash] == false,
            "CrossDomainMessenger: message has already been relayed"
        );

        require(
            gasleft() >= _minGasLimit + RELAY_GAS_REQUIRED,
            "CrossDomainMessenger: insufficient gas to relay message"
        );

        xDomainMsgSender = _sender;
        (bool success, ) = ExcessivelySafeCall.excessivelySafeCall(
            _target,
            gasleft() - RELAY_GAS_BUFFER,
            _value,
            0,
            _message
        );
        xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

        if (success == true) {
            successfulMessages[versionedHash] = true;
            emit RelayedMessage(versionedHash);
        } else {
            receivedMessages[versionedHash] = true;
            emit FailedRelayedMessage(versionedHash);
        }
    }

    /**
     * @notice Retrieves the address of the contract or wallet that initiated the currently
     *         executing message on the other chain. Will throw an error if there is no message
     *         currently being executed. Allows the recipient of a call to see who triggered it.
     *
     * @return Address of the sender of the currently executing message on the other chain.
     */
    function xDomainMessageSender() external view returns (address) {
        require(
            xDomainMsgSender != DEFAULT_XDOMAIN_SENDER,
            "CrossDomainMessenger: xDomainMessageSender is not set"
        );

        return xDomainMsgSender;
    }

    /**
     * @notice Retrieves the next message nonce. Message version will be added to the upper two
     *         bytes of the message nonce. Message version allows us to treat messages as having
     *         different structures.
     *
     * @return Nonce of the next message to be sent, with added message version.
     */
    function messageNonce() public view returns (uint256) {
        return Encoding.encodeVersionedNonce(msgNonce, MESSAGE_VERSION);
    }

    /**
     * @notice Computes the amount of gas required to guarantee that a given message will be
     *         received on the other chain without running out of gas. Guaranteeing that a message
     *         will not run out of gas is important because this ensures that a message can always
     *         be replayed on the other chain if it fails to execute completely.
     *
     * @param _message     Message to compute the amount of required gas for.
     * @param _minGasLimit Minimum desired gas limit when message goes to target.
     *
     * @return Amount of gas required to guarantee message receipt.
     */
    function baseGas(bytes calldata _message, uint32 _minGasLimit) public pure returns (uint32) {
        return
            // Dynamic overhead
            ((_minGasLimit * MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR) /
                MIN_GAS_DYNAMIC_OVERHEAD_DENOMINATOR) +
            // Calldata overhead
            (uint32(_message.length) * MIN_GAS_CALLDATA_OVERHEAD) +
            // Constant overhead
            MIN_GAS_CONSTANT_OVERHEAD;
    }

    /**
     * @notice Intializer.
     *
     * @param _otherMessenger         Address of the CrossDomainMessenger on the paired chain.
     * @param _blockedSystemAddresses List of system addresses that need to be blocked to prevent
     *                                certain security issues. Exact list depends on the network
     *                                where this contract is deployed. See note attached to the
     *                                blockedSystemAddresses variable in this contract for more
     *                                detailed information about what this block list can and
     *                                cannot be used for.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __CrossDomainMessenger_init(
        address _otherMessenger,
        address[] memory _blockedSystemAddresses
    ) internal onlyInitializing {
        xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;
        otherMessenger = _otherMessenger;
        for (uint256 i = 0; i < _blockedSystemAddresses.length; i++) {
            blockedSystemAddresses[_blockedSystemAddresses[i]] = true;
        }

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    /**
     * @notice Sends a low-level message to the other messenger. Needs to be implemented by child
     *         contracts because the logic for this depends on the network where the messenger is
     *         being deployed.
     */
    function _sendMessage(
        address _to,
        uint64 _gasLimit,
        uint256 _value,
        bytes memory _data
    ) internal virtual;

    /**
     * @notice Checks whether the message is coming from the other messenger. Implemented by child
     *         contracts because the logic for this depends on the network where the messenger is
     *         being deployed.
     */
    function _isOtherMessenger() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SupportedInterfaces.sol";

/**
 * @title OptimismMintableERC20
 * @notice OptimismMintableERC20 is a standard extension of the base ERC20 token contract designed
 *         to allow the StandardBridge contracts to mint and burn tokens. This makes it possible to
 *         use an OptimismMintablERC20 as the L2 representation of an L1 token, or vice-versa.
 *         Designed to be backwards compatible with the older StandardL2ERC20 token which was only
 *         meant for use on L2.
 */
contract OptimismMintableERC20 is ERC20 {
    /**
     * @notice Address of the corresponding version of this token on the remote chain.
     */
    address public remoteToken;

    /**
     * @notice Address of the StandardBridge on this network.
     */
    address public bridge;

    /**
     * @notice Emitted whenever tokens are minted for an account.
     *
     * @param account Address of the account tokens are being minted for.
     * @param amount  Amount of tokens minted.
     */
    event Mint(address indexed account, uint256 amount);

    /**
     * @notice Emitted whenever tokens are burned from an account.
     *
     * @param account Address of the account tokens are being burned from.
     * @param amount  Amount of tokens burned.
     */
    event Burn(address indexed account, uint256 amount);

    /**
     * @notice A modifier that only allows the bridge to call
     */
    modifier onlyBridge() {
        require(msg.sender == bridge, "OptimismMintableERC20: only bridge can mint and burn");
        _;
    }

    /**
     * @param _bridge      Address of the L2 standard bridge.
     * @param _remoteToken Address of the corresponding L1 token.
     * @param _name        ERC20 name.
     * @param _symbol      ERC20 symbol.
     */
    constructor(
        address _bridge,
        address _remoteToken,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        remoteToken = _remoteToken;
        bridge = _bridge;
    }

    /**
     * @notice Allows the StandardBridge on this network to mint tokens.
     *
     * @param _to     Address to mint tokens to.
     * @param _amount Amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external virtual onlyBridge {
        _mint(_to, _amount);
        emit Mint(_to, _amount);
    }

    /**
     * @notice Allows the StandardBridge on this network to burn tokens.
     *
     * @param _from   Address to burn tokens from.
     * @param _amount Amount of tokens to burn.
     */
    function burn(address _from, uint256 _amount) external virtual onlyBridge {
        _burn(_from, _amount);
        emit Burn(_from, _amount);
    }

    /**
     * @notice ERC165 interface check function.
     *
     * @param _interfaceId Interface ID to check.
     *
     * @return Whether or not the interface is supported by this contract.
     */
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        bytes4 iface1 = type(IERC165).interfaceId;
        bytes4 iface2 = type(IL1Token).interfaceId;
        bytes4 iface3 = type(IRemoteToken).interfaceId;
        return _interfaceId == iface1 || _interfaceId == iface2 || _interfaceId == iface3;
    }

    /**
     * @custom:legacy
     * @notice Legacy getter for the remote token. Use remoteToken going forward.
     */
    function l1Token() public view returns (address) {
        return remoteToken;
    }

    /**
     * @custom:legacy
     * @notice Legacy getter for the bridge. Use bridge going forward.
     */
    function l2Bridge() public view returns (address) {
        return bridge;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _value The value in wei to send to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint256 _value,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
        internal
        pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Types } from "./Types.sol";
import { Encoding } from "./Encoding.sol";

/**
 * @title Hashing
 * @notice Hashing handles Optimism's various different hashing schemes.
 */
library Hashing {
    /**
     * @notice Computes the hash of the RLP encoded L2 transaction that would be generated when a
     *         given deposit is sent to the L2 system. Useful for searching for a deposit in the L2
     *         system.
     *
     * @param _tx User deposit transaction to hash.
     *
     * @return Hash of the RLP encoded L2 deposit transaction.
     */
    function hashDepositTransaction(Types.UserDepositTransaction memory _tx)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(Encoding.encodeDepositTransaction(_tx));
    }

    /**
     * @notice Computes the deposit transaction's "source hash", a value that guarantees the hash
     *         of the L2 transaction that corresponds to a deposit is unique and is
     *         deterministically generated from L1 transaction data.
     *
     * @param _l1BlockHash Hash of the L1 block where the deposit was included.
     * @param _logIndex    The index of the log that created the deposit transaction.
     *
     * @return Hash of the deposit transaction's "source hash".
     */
    function hashDepositSource(bytes32 _l1BlockHash, uint256 _logIndex)
        internal
        pure
        returns (bytes32)
    {
        bytes32 depositId = keccak256(abi.encode(_l1BlockHash, _logIndex));
        return keccak256(abi.encode(bytes32(0), depositId));
    }

    /**
     * @notice Hashes the cross domain message based on the version that is encoded into the
     *         message nonce.
     *
     * @param _nonce    Message nonce with version encoded into the first two bytes.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Hashed cross domain message.
     */
    function hashCrossDomainMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes32) {
        (, uint16 version) = Encoding.decodeVersionedNonce(_nonce);
        if (version == 0) {
            return hashCrossDomainMessageV0(_target, _sender, _data, _nonce);
        } else if (version == 1) {
            return hashCrossDomainMessageV1(_nonce, _sender, _target, _value, _gasLimit, _data);
        } else {
            revert("Hashing: unknown cross domain message version");
        }
    }

    /**
     * @notice Hashes a cross domain message based on the V0 (legacy) encoding.
     *
     * @param _target Address of the target of the message.
     * @param _sender Address of the sender of the message.
     * @param _data   Data to send with the message.
     * @param _nonce  Message nonce.
     *
     * @return Hashed cross domain message.
     */
    function hashCrossDomainMessageV0(
        address _target,
        address _sender,
        bytes memory _data,
        uint256 _nonce
    ) internal pure returns (bytes32) {
        return keccak256(Encoding.encodeCrossDomainMessageV0(_target, _sender, _data, _nonce));
    }

    /**
     * @notice Hashes a cross domain message based on the V1 (current) encoding.
     *
     * @param _nonce    Message nonce.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Hashed cross domain message.
     */
    function hashCrossDomainMessageV1(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes32) {
        return
            keccak256(
                Encoding.encodeCrossDomainMessageV1(
                    _nonce,
                    _sender,
                    _target,
                    _value,
                    _gasLimit,
                    _data
                )
            );
    }

    /**
     * @notice Derives the withdrawal hash according to the encoding in the L2 Withdrawer contract
     *
     * @param _tx Withdrawal transaction to hash.
     *
     * @return Hashed withdrawal transaction.
     */
    function hashWithdrawal(Types.WithdrawalTransaction memory _tx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(_tx.nonce, _tx.sender, _tx.target, _tx.value, _tx.gasLimit, _tx.data)
            );
    }

    /**
     * @notice Hashes the various elements of an output root proof into an output root hash which
     *         can be used to check if the proof is valid.
     *
     * @param _outputRootProof Output root proof which should hash to an output root.
     *
     * @return Hashed output root proof.
     */
    function hashOutputRootProof(Types.OutputRootProof memory _outputRootProof)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _outputRootProof.version,
                    _outputRootProof.stateRoot,
                    _outputRootProof.withdrawerStorageRoot,
                    _outputRootProof.latestBlockhash
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Types } from "./Types.sol";
import { Hashing } from "./Hashing.sol";
import { RLPWriter } from "./rlp/RLPWriter.sol";

/**
 * @title Encoding
 * @notice Encoding handles Optimism's various different encoding schemes.
 */
library Encoding {
    /**
     * @notice RLP encodes the L2 transaction that would be generated when a given deposit is sent
     *         to the L2 system. Useful for searching for a deposit in the L2 system.
     *         This currently only supports user deposits and not system
     *         transactions.
     *
     * @param _tx User deposit transaction to encode.
     *
     * @return RLP encoded L2 deposit transaction.
     */
    function encodeDepositTransaction(Types.UserDepositTransaction memory _tx)
        internal
        pure
        returns (bytes memory)
    {
        bytes32 source = Hashing.hashDepositSource(_tx.l1BlockHash, _tx.logIndex);
        bytes[] memory raw = new bytes[](8);
        raw[0] = RLPWriter.writeBytes(abi.encodePacked(source));
        raw[1] = RLPWriter.writeAddress(_tx.from);
        raw[2] = _tx.isCreation ? RLPWriter.writeBytes("") : RLPWriter.writeAddress(_tx.to);
        raw[3] = RLPWriter.writeUint(_tx.mint);
        raw[4] = RLPWriter.writeUint(_tx.value);
        raw[5] = RLPWriter.writeUint(uint256(_tx.gasLimit));
        raw[6] = RLPWriter.writeBool(false);
        raw[7] = RLPWriter.writeBytes(_tx.data);
        return abi.encodePacked(uint8(0x7e), RLPWriter.writeList(raw));
    }

    /**
     * @notice Encodes the cross domain message based on the version that is encoded into the
     *         message nonce.
     *
     * @param _nonce    Message nonce with version encoded into the first two bytes.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Encoded cross domain message.
     */
    function encodeCrossDomainMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes memory) {
        (, uint16 version) = decodeVersionedNonce(_nonce);
        if (version == 0) {
            return encodeCrossDomainMessageV0(_target, _sender, _data, _nonce);
        } else if (version == 1) {
            return encodeCrossDomainMessageV1(_nonce, _sender, _target, _value, _gasLimit, _data);
        } else {
            revert("Encoding: unknown cross domain message version");
        }
    }

    /**
     * @notice Encodes a cross domain message based on the V0 (legacy) encoding.
     *
     * @param _target Address of the target of the message.
     * @param _sender Address of the sender of the message.
     * @param _data   Data to send with the message.
     * @param _nonce  Message nonce.
     *
     * @return Encoded cross domain message.
     */
    function encodeCrossDomainMessageV0(
        address _target,
        address _sender,
        bytes memory _data,
        uint256 _nonce
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "relayMessage(address,address,bytes,uint256)",
                _target,
                _sender,
                _data,
                _nonce
            );
    }

    /**
     * @notice Encodes a cross domain message based on the V1 (current) encoding.
     *
     * @param _nonce    Message nonce.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Encoded cross domain message.
     */
    function encodeCrossDomainMessageV1(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "relayMessage(uint256,address,address,uint256,uint256,bytes)",
                _nonce,
                _sender,
                _target,
                _value,
                _gasLimit,
                _data
            );
    }

    /**
     * @notice Adds a version number into the first two bytes of a message nonce.
     *
     * @param _nonce   Message nonce to encode into.
     * @param _version Version number to encode into the message nonce.
     *
     * @return Message nonce with version encoded into the first two bytes.
     */
    function encodeVersionedNonce(uint240 _nonce, uint16 _version) internal pure returns (uint256) {
        uint256 nonce;
        assembly {
            nonce := or(shl(240, _version), _nonce)
        }
        return nonce;
    }

    /**
     * @notice Pulls the version out of a version-encoded nonce.
     *
     * @param _nonce Message nonce with version encoded into the first two bytes.
     *
     * @return Nonce without encoded version.
     * @return Version of the message.
     */
    function decodeVersionedNonce(uint256 _nonce) internal pure returns (uint240, uint16) {
        uint240 nonce;
        uint16 version;
        assembly {
            nonce := and(_nonce, 0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            version := shr(240, _nonce)
        }
        return (nonce, version);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Types
 * @notice Contains various types used throughout the Optimism contract system.
 */
library Types {
    /**
     * @notice OutputProposal represents a commitment to the L2 state. The timestamp is the L1
     *         timestamp that the output root is posted. This timestamp is used to verify that the
     *         finalization period has passed since the output root was submitted.
     */
    struct OutputProposal {
        bytes32 outputRoot;
        uint256 timestamp;
    }

    /**
     * @notice Struct representing the elements that are hashed together to generate an output root
     *         which itself represents a snapshot of the L2 state.
     */
    struct OutputRootProof {
        bytes32 version;
        bytes32 stateRoot;
        bytes32 withdrawerStorageRoot;
        bytes32 latestBlockhash;
    }

    /**
     * @notice Struct representing a deposit transaction (L1 => L2 transaction) created by an end
     *         user (as opposed to a system deposit transaction generated by the system).
     */
    struct UserDepositTransaction {
        address from;
        address to;
        bool isCreation;
        uint256 value;
        uint256 mint;
        uint64 gasLimit;
        bytes data;
        bytes32 l1BlockHash;
        uint256 logIndex;
    }

    /**
     * @notice Struct representing a withdrawal transaction.
     */
    struct WithdrawalTransaction {
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 gasLimit;
        bytes data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:attribution https://github.com/bakaoh/solidity-rlp-encode
 * @title RLPWriter
 * @author RLPWriter is a library for encoding Solidity types to RLP bytes. Adapted from Bakaoh's
 *         RLPEncode library (https://github.com/bakaoh/solidity-rlp-encode) with minor
 *         modifications to improve legibility.
 */
library RLPWriter {
    /**
     * @notice RLP encodes a byte string.
     *
     * @param _in The byte string to encode.
     *
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * @notice RLP encodes a list of RLP encoded byte byte strings.
     *
     * @param _in The list of RLP encoded byte strings.
     *
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(bytes[] memory _in) internal pure returns (bytes memory) {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * @notice RLP encodes a string.
     *
     * @param _in The string to encode.
     *
     * @return The RLP encoded string in bytes.
     */
    function writeString(string memory _in) internal pure returns (bytes memory) {
        return writeBytes(bytes(_in));
    }

    /**
     * @notice RLP encodes an address.
     *
     * @param _in The address to encode.
     *
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(address _in) internal pure returns (bytes memory) {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * @notice RLP encodes a uint.
     *
     * @param _in The uint256 to encode.
     *
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(uint256 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_in));
    }

    /**
     * @notice RLP encodes a bool.
     *
     * @param _in The bool to encode.
     *
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(bool _in) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /**
     * @notice Encode the first byte and then the `len` in binary form if `length` is more than 55.
     *
     * @param _len    The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     *
     * @return RLP encoded bytes.
     */
    function _writeLength(uint256 _len, uint256 _offset) private pure returns (bytes memory) {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes1(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes1(uint8((_len / (256**(lenLen - i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * @notice Encode integer in big endian binary form with no leading zeroes.
     *
     * @param _x The integer to encode.
     *
     * @return RLP encoded bytes.
     */
    function _toBinary(uint256 _x) private pure returns (bytes memory) {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * @custom:attribution https://github.com/Arachnid/solidity-stringutils
     * @notice Copies a piece of memory to another location.
     *
     * @param _dest Destination location.
     * @param _src  Source location.
     * @param _len  Length of memory to copy.
     */
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) private pure {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask;
        unchecked {
            mask = 256**(32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * @custom:attribution https://github.com/sammayo/solidity-rlp-encoder
     * @notice Flattens a list of byte strings into one byte string.
     *
     * @param _list List of byte strings to flatten.
     *
     * @return The flattened byte string.
     */
    function _flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}