/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/// @dev Common feature utilities.
contract FixinCommon {

    using LibRichErrorsV06 for bytes;

    /// @dev The caller must be this contract.
    modifier onlySelf() virtual {
        if (msg.sender != address(this)) {
            LibCommonRichErrors.OnlyCallableBySelfError(msg.sender).rrevert();
        }
        _;
    }

    /// @dev The caller of this function must be the owner.
    modifier onlyOwner() virtual {
        {
            address owner = IOwnable(address(this)).owner();
            if (msg.sender != owner) {
                LibOwnableRichErrors.OnlyOwnerError(
                    msg.sender,
                    owner
                ).rrevert();
            }
        }
        _;
    }

    /// @dev Encode a feature version as a `uint256`.
    /// @param major The major version number of the feature.
    /// @param minor The minor version number of the feature.
    /// @param revision The revision number of the feature.
    /// @return encodedVersion The encoded version number.
    function _encodeVersion(uint32 major, uint32 minor, uint32 revision)
        internal
        pure
        returns (uint256 encodedVersion)
    {
        return (major << 64) | (minor << 32) | revision;
    }
}

contract TestZeroExFeature is FixinCommon {
    event PayableFnCalled(uint256 value);
    event NotPayableFnCalled();

    function payableFn()
        external
        payable
    {
        emit PayableFnCalled(msg.value);
    }

    function notPayableFn()
        external
    {
        emit NotPayableFnCalled();
    }

    // solhint-disable no-empty-blocks
    function unimplmentedFn()
        external
    {}

    function internalFn()
        external
        onlySelf
    {}
}

contract TestTransformerHost {

    using LibERC20Transformer for IERC20TokenV06;
    using LibRichErrorsV06 for bytes;

    function rawExecuteTransform(
        IERC20Transformer transformer,
        bytes32 callDataHash,
        address taker,
        bytes calldata data
    )
        external
    {
        (bool _success, bytes memory resultData) =
            address(transformer).delegatecall(abi.encodeWithSelector(
                transformer.transform.selector,
                callDataHash,
                taker,
                data
            ));
        if (!_success) {
            resultData.rrevert();
        }
        require(
            abi.decode(resultData, (bytes4)) == LibERC20Transformer.TRANSFORMER_SUCCESS,
            "TestTransformerHost/INVALID_TRANSFORMER_RESULT"
        );
    }

    // solhint-disable
    receive() external payable {}
    // solhint-enable
}

/// @dev Basic interface for a feature contract.
interface IFeature {

    // solhint-disable func-name-mixedcase

    /// @dev The name of this feature set.
    function FEATURE_NAME() external view returns (string memory name);

    /// @dev The version of this feature set.
    function FEATURE_VERSION() external view returns (uint256 version);
}

/// @dev A transformation callback used in `TransformERC20.transformERC20()`.
interface IERC20Transformer {

    /// @dev Called from `TransformERC20.transformERC20()`. This will be
    ///      delegatecalled in the context of the FlashWallet instance being used.
    /// @param callDataHash The hash of the `TransformERC20.transformERC20()` calldata.
    /// @param taker The taker address (caller of `TransformERC20.transformERC20()`).
    /// @param data Arbitrary data to pass to the transformer.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(
        bytes32 callDataHash,
        address payable taker,
        bytes calldata data
    )
        external
        returns (bytes4 success);
}

/// @dev A contract with a `die()` function.
interface IKillable {
    function die() external;
}

/// @dev Feature to composably transform between ERC20 tokens.
interface ITransformERC20 {

    /// @dev Defines a transformation to run in `transformERC20()`.
    struct Transformation {
        // The deployment nonce for the transformer.
        // The address of the transformer contract will be derived from this
        // value.
        uint32 deploymentNonce;
        // Arbitrary data to pass to the transformer.
        bytes data;
    }

    /// @dev Raised upon a successful `transformERC20`.
    /// @param taker The taker (caller) address.
    /// @param inputToken The token being provided by the taker.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the taker.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the taker.
    /// @param outputTokenAmount The amount of `outputToken` received by the taker.
    event TransformedERC20(
        address indexed taker,
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount
    );

    /// @dev Raised when `setTransformerDeployer()` is called.
    /// @param transformerDeployer The new deployer address.
    event TransformerDeployerUpdated(address transformerDeployer);

    /// @dev Replace the allowed deployer for transformers.
    ///      Only callable by the owner.
    /// @param transformerDeployer The address of the trusted deployer for transformers.
    function setTransformerDeployer(address transformerDeployer)
        external;

    /// @dev Deploy a new flash wallet instance and replace the current one with it.
    ///      Useful if we somehow break the current wallet instance.
    ///      Anyone can call this.
    /// @return wallet The new wallet instance.
    function createTransformWallet()
        external
        returns (IFlashWallet wallet);

    /// @dev Executes a series of transformations to convert an ERC20 `inputToken`
    ///      to an ERC20 `outputToken`.
    /// @param inputToken The token being provided by the sender.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the sender.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the sender.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the sender
    ///        must receive for the entire transformation to succeed.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the sender.
    function transformERC20(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] calldata transformations
    )
        external
        payable
        returns (uint256 outputTokenAmount);

    /// @dev Internal version of `transformERC20()`. Only callable from within.
    /// @param callDataHash Hash of the ingress calldata.
    /// @param taker The taker address.
    /// @param inputToken The token being provided by the taker.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the taker.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the taker.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the taker
    ///        must receive for the entire transformation to succeed.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20(
        bytes32 callDataHash,
        address payable taker,
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] calldata transformations
    )
        external
        payable
        returns (uint256 outputTokenAmount);

    /// @dev Return the current wallet instance that will serve as the execution
    ///      context for transformations.
    /// @return wallet The wallet instance.
    function getTransformWallet()
        external
        view
        returns (IFlashWallet wallet);

    /// @dev Return the allowed deployer for transformers.
    /// @return deployer The transform deployer address.
    function getTransformerDeployer()
        external
        view
        returns (address deployer);
}

/// @dev Abstract base class for transformers.
abstract contract Transformer is
    IERC20Transformer
{
    using LibRichErrorsV06 for bytes;

    /// @dev The address of the deployer.
    address public immutable deployer;
    /// @dev The original address of this contract.
    address private immutable _implementation;

    /// @dev Create this contract.
    constructor() public {
        deployer = msg.sender;
        _implementation = address(this);
    }

    /// @dev Destruct this contract. Only callable by the deployer and will not
    ///      succeed in the context of a delegatecall (from another contract).
    /// @param ethRecipient The recipient of ETH held in this contract.
    function die(address payable ethRecipient)
        external
        virtual
    {
        // Only the deployer can call this.
        if (msg.sender != deployer) {
            LibTransformERC20RichErrors
                .OnlyCallableByDeployerError(msg.sender, deployer)
                .rrevert();
        }
        // Must be executing our own context.
        if (address(this) != _implementation) {
            LibTransformERC20RichErrors
                .InvalidExecutionContextError(address(this), _implementation)
                .rrevert();
        }
        selfdestruct(ethRecipient);
    }
}

interface IERC20TokenV06 {

    // solhint-disable no-simple-event-func-name
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address to, uint256 value)
        external
        returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        returns (bool);

    /// @dev `msg.sender` approves `spender` to spend `value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address spender, uint256 value)
        external
        returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply()
        external
        view
        returns (uint256);

    /// @dev Get the balance of `owner`.
    /// @param owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address owner)
        external
        view
        returns (uint256);

    /// @dev Get the allowance for `spender` to spend from `owner`.
    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /// @dev Get the number of decimals this token has.
    function decimals()
        external
        view
        returns (uint8);
}

/// @dev Feature that allows spending token allowances.
interface ITokenSpender {

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    ///      Only callable from within.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _spendERC20Tokens(
        IERC20TokenV06 token,
        address owner,
        address to,
        uint256 amount
    )
        external;

    /// @dev Gets the maximum amount of an ERC20 token `token` that can be
    ///      pulled from `owner`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @return amount The amount of tokens that can be pulled.
    function getSpendableERC20BalanceOf(IERC20TokenV06 token, address owner)
        external
        view
        returns (uint256 amount);

    /// @dev Get the address of the allowance target.
    /// @return target The target of token allowances.
    function getAllowanceTarget() external view returns (address target);
}

/// @dev Basic registry management features.
interface ISimpleFunctionRegistry {

    /// @dev A function implementation was updated via `extend()` or `rollback()`.
    /// @param selector The function selector.
    /// @param oldImpl The implementation contract address being replaced.
    /// @param newImpl The replacement implementation contract address.
    event ProxyFunctionUpdated(bytes4 indexed selector, address oldImpl, address newImpl);

    /// @dev Roll back to a prior implementation of a function.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl) external;

    /// @dev Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl) external;

    /// @dev Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector)
        external
        view
        returns (uint256 rollbackLength);

    /// @dev Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx)
        external
        view
        returns (address impl);
}

/// @dev Feature to composably transform between ERC20 tokens.
contract TransformERC20 is
    IFeature,
    ITransformERC20,
    FixinCommon
{

    /// @dev Stack vars for `_transformERC20Private()`.
    struct TransformERC20PrivateState {
        IFlashWallet wallet;
        address transformerDeployer;
        uint256 takerOutputTokenBalanceBefore;
        uint256 takerOutputTokenBalanceAfter;
    }

    // solhint-disable
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "TransformERC20";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);
    /// @dev The implementation address of this feature.
    address private immutable _implementation;
    // solhint-enable

    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    constructor() public {
        _implementation = address(this);
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @param transformerDeployer The trusted deployer for transformers.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate(address transformerDeployer) external returns (bytes4 success) {
        ISimpleFunctionRegistry(address(this))
            .extend(this.getTransformerDeployer.selector, _implementation);
        ISimpleFunctionRegistry(address(this))
            .extend(this.createTransformWallet.selector, _implementation);
        ISimpleFunctionRegistry(address(this))
            .extend(this.getTransformWallet.selector, _implementation);
        ISimpleFunctionRegistry(address(this))
            .extend(this.setTransformerDeployer.selector, _implementation);
        ISimpleFunctionRegistry(address(this))
            .extend(this.transformERC20.selector, _implementation);
        ISimpleFunctionRegistry(address(this))
            .extend(this._transformERC20.selector, _implementation);
        createTransformWallet();
        LibTransformERC20Storage.getStorage().transformerDeployer = transformerDeployer;
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Replace the allowed deployer for transformers.
    ///      Only callable by the owner.
    /// @param transformerDeployer The address of the trusted deployer for transformers.
    function setTransformerDeployer(address transformerDeployer)
        external
        override
        onlyOwner
    {
        LibTransformERC20Storage.getStorage().transformerDeployer = transformerDeployer;
        emit TransformerDeployerUpdated(transformerDeployer);
    }

    /// @dev Return the allowed deployer for transformers.
    /// @return deployer The transform deployer address.
    function getTransformerDeployer()
        public
        override
        view
        returns (address deployer)
    {
        return LibTransformERC20Storage.getStorage().transformerDeployer;
    }

    /// @dev Deploy a new wallet instance and replace the current one with it.
    ///      Useful if we somehow break the current wallet instance.
    ///      Anyone can call this.
    /// @return wallet The new wallet instance.
    function createTransformWallet()
        public
        override
        returns (IFlashWallet wallet)
    {
        wallet = new FlashWallet();
        LibTransformERC20Storage.getStorage().wallet = wallet;
    }

    /// @dev Executes a series of transformations to convert an ERC20 `inputToken`
    ///      to an ERC20 `outputToken`.
    /// @param inputToken The token being provided by the sender.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the sender.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the sender.
    ///        If set to `uint256(-1)`, the entire spendable balance of the taker
    ///        will be solt.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the sender
    ///        must receive for the entire transformation to succeed. If set to zero,
    ///        the minimum output token transfer will not be asserted.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the sender.
    function transformERC20(
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] memory transformations
    )
        public
        override
        payable
        returns (uint256 outputTokenAmount)
    {
        return _transformERC20Private(
            keccak256(msg.data),
            msg.sender,
            inputToken,
            outputToken,
            inputTokenAmount,
            minOutputTokenAmount,
            transformations
        );
    }

    /// @dev Internal version of `transformERC20()`. Only callable from within.
    /// @param callDataHash Hash of the ingress calldata.
    /// @param taker The taker address.
    /// @param inputToken The token being provided by the taker.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the taker.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the taker.
    ///        If set to `uint256(-1)`, the entire spendable balance of the taker
    ///        will be solt.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the taker
    ///        must receive for the entire transformation to succeed. If set to zero,
    ///        the minimum output token transfer will not be asserted.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20(
        bytes32 callDataHash,
        address payable taker,
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] memory transformations
    )
        public
        override
        payable
        onlySelf
        returns (uint256 outputTokenAmount)
    {
        return _transformERC20Private(
            callDataHash,
            taker,
            inputToken,
            outputToken,
            inputTokenAmount,
            minOutputTokenAmount,
            transformations
        );
    }

    /// @dev Private version of `transformERC20()`.
    /// @param callDataHash Hash of the ingress calldata.
    /// @param taker The taker address.
    /// @param inputToken The token being provided by the taker.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the taker.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the taker.
    ///        If set to `uint256(-1)`, the entire spendable balance of the taker
    ///        will be solt.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the taker
    ///        must receive for the entire transformation to succeed. If set to zero,
    ///        the minimum output token transfer will not be asserted.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20Private(
        bytes32 callDataHash,
        address payable taker,
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] memory transformations
    )
        private
        returns (uint256 outputTokenAmount)
    {
        // If the input token amount is -1, transform the taker's entire
        // spendable balance.
        if (inputTokenAmount == uint256(-1)) {
            inputTokenAmount = ITokenSpender(address(this))
                .getSpendableERC20BalanceOf(inputToken, taker);
        }

        TransformERC20PrivateState memory state;
        state.wallet = getTransformWallet();
        state.transformerDeployer = getTransformerDeployer();

        // Remember the initial output token balance of the taker.
        state.takerOutputTokenBalanceBefore =
            LibERC20Transformer.getTokenBalanceOf(outputToken, taker);

        // Pull input tokens from the taker to the wallet and transfer attached ETH.
        _transferInputTokensAndAttachedEth(
            inputToken,
            taker,
            address(state.wallet),
            inputTokenAmount
        );

        // Perform transformations.
        for (uint256 i = 0; i < transformations.length; ++i) {
            _executeTransformation(
                state.wallet,
                transformations[i],
                state.transformerDeployer,
                taker,
                callDataHash
            );
        }

        // Compute how much output token has been transferred to the taker.
        state.takerOutputTokenBalanceAfter =
            LibERC20Transformer.getTokenBalanceOf(outputToken, taker);
        if (state.takerOutputTokenBalanceAfter > state.takerOutputTokenBalanceBefore) {
            outputTokenAmount = state.takerOutputTokenBalanceAfter.safeSub(
                state.takerOutputTokenBalanceBefore
            );
        } else if (state.takerOutputTokenBalanceAfter < state.takerOutputTokenBalanceBefore) {
            LibTransformERC20RichErrors.NegativeTransformERC20OutputError(
                address(outputToken),
                state.takerOutputTokenBalanceBefore - state.takerOutputTokenBalanceAfter
            ).rrevert();
        }
        // Ensure enough output token has been sent to the taker.
        if (outputTokenAmount < minOutputTokenAmount) {
            LibTransformERC20RichErrors.IncompleteTransformERC20Error(
                address(outputToken),
                outputTokenAmount,
                minOutputTokenAmount
            ).rrevert();
        }

        // Emit an event.
        emit TransformedERC20(
            taker,
            address(inputToken),
            address(outputToken),
            inputTokenAmount,
            outputTokenAmount
        );
    }

    /// @dev Return the current wallet instance that will serve as the execution
    ///      context for transformations.
    /// @return wallet The wallet instance.
    function getTransformWallet()
        public
        override
        view
        returns (IFlashWallet wallet)
    {
        return LibTransformERC20Storage.getStorage().wallet;
    }

    /// @dev Transfer input tokens from the taker and any attached ETH to `to`
    /// @param inputToken The token to pull from the taker.
    /// @param from The from (taker) address.
    /// @param to The recipient of tokens and ETH.
    /// @param amount Amount of `inputToken` tokens to transfer.
    function _transferInputTokensAndAttachedEth(
        IERC20TokenV06 inputToken,
        address from,
        address payable to,
        uint256 amount
    )
        private
    {
        // Transfer any attached ETH.
        if (msg.value != 0) {
            to.transfer(msg.value);
        }
        // Transfer input tokens.
        if (!LibERC20Transformer.isTokenETH(inputToken)) {
            // Token is not ETH, so pull ERC20 tokens.
            ITokenSpender(address(this))._spendERC20Tokens(
                inputToken,
                from,
                to,
                amount
            );
        } else if (msg.value < amount) {
             // Token is ETH, so the caller must attach enough ETH to the call.
            LibTransformERC20RichErrors.InsufficientEthAttachedError(
                msg.value,
                amount
            ).rrevert();
        }
    }

    /// @dev Executs a transformer in the context of `wallet`.
    /// @param wallet The wallet instance.
    /// @param transformation The transformation.
    /// @param transformerDeployer The address of the transformer deployer.
    /// @param taker The taker address.
    /// @param callDataHash Hash of the calldata.
    function _executeTransformation(
        IFlashWallet wallet,
        Transformation memory transformation,
        address transformerDeployer,
        address payable taker,
        bytes32 callDataHash
    )
        private
    {
        // Derive the transformer address from the deployment nonce.
        address payable transformer = LibERC20Transformer.getDeployedAddress(
            transformerDeployer,
            transformation.deploymentNonce
        );
        // Call `transformer.transform()` as the wallet.
        bytes memory resultData = wallet.executeDelegateCall(
            // The call target.
            transformer,
            // Call data.
            abi.encodeWithSelector(
                IERC20Transformer.transform.selector,
                callDataHash,
                taker,
                transformation.data
            )
        );
        // Ensure the transformer returned the magic bytes.
        if (resultData.length != 32 ||
            abi.decode(resultData, (bytes4)) != LibERC20Transformer.TRANSFORMER_SUCCESS
        ) {
            LibTransformERC20RichErrors.TransformerFailedError(
                transformer,
                transformation.data,
                resultData
            ).rrevert();
        }
    }
}

contract TestWethTransformerHost is TestTransformerHost {
    // solhint-disable
    TestWeth private immutable _weth;
    // solhint-enable

    constructor(TestWeth weth) public {
        _weth = weth;
    }

    function executeTransform(
        uint256 wethAmount,
        IERC20Transformer transformer,
        bytes calldata data
    )
        external
        payable
    {
        if (wethAmount != 0) {
            _weth.deposit{value: wethAmount}();
        }
        // Have to make this call externally because transformers aren't payable.
        this.rawExecuteTransform(transformer, bytes32(0), msg.sender, data);
    }
}

contract TestMintableERC20Token {

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 amount)
        external
        virtual
        returns (bool)
    {
        return transferFrom(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function mint(address owner, uint256 amount)
        external
        virtual
    {
        balanceOf[owner] += amount;
    }

    function burn(address owner, uint256 amount)
        external
        virtual
    {
        require(balanceOf[owner] >= amount, "TestMintableERC20Token/INSUFFICIENT_FUNDS");
        balanceOf[owner] -= amount;
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        if (from != msg.sender) {
            require(
                allowance[from][msg.sender] >= amount,
                "TestMintableERC20Token/INSUFFICIENT_ALLOWANCE"
            );
            allowance[from][msg.sender] -= amount;
        }
        require(balanceOf[from] >= amount, "TestMintableERC20Token/INSUFFICIENT_FUNDS");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function getSpendableAmount(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return balanceOf[owner] < allowance[owner][spender]
            ? balanceOf[owner]
            : allowance[owner][spender];
    }
}

contract TestWeth is TestMintableERC20Token {
    function deposit()
        external
        payable
    {
        this.mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount)
        external
    {
        require(balanceOf[msg.sender] >= amount, "TestWeth/INSUFFICIENT_FUNDS");
        balanceOf[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
}

contract TestTransformerDeployerTransformer {

    address payable public immutable deployer;

    constructor() public payable {
        deployer = msg.sender;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "TestTransformerDeployerTransformer/ONLY_DEPLOYER");
        _;
    }

    function die()
        external
        onlyDeployer
    {
        selfdestruct(deployer);
    }

    function isDeployedByDeployer(uint32 nonce)
        external
        view
        returns (bool)
    {
        return LibERC20Transformer.getDeployedAddress(deployer, nonce) == address(this);
    }
}

contract TestTransformerBase is Transformer {
    function transform(
        bytes32,
        address payable,
        bytes calldata
    )
        external
        override
        returns (bytes4 success)
    {
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}

contract TestTransformERC20 is TransformERC20 {
    // solhint-disable no-empty-blocks
    constructor()
        TransformERC20()
        public
    {}

    modifier onlySelf() override {
        _;
    }
}

contract TestTokenSpenderERC20Token is
    TestMintableERC20Token
{

    event TransferFromCalled(
        address sender,
        address from,
        address to,
        uint256 amount
    );

    // `transferFrom()` behavior depends on the value of `amount`.
    uint256 constant private EMPTY_RETURN_AMOUNT = 1337;
    uint256 constant private FALSE_RETURN_AMOUNT = 1338;
    uint256 constant private REVERT_RETURN_AMOUNT = 1339;

    function transferFrom(address from, address to, uint256 amount)
        public
        override
        returns (bool)
    {
        emit TransferFromCalled(msg.sender, from, to, amount);
        if (amount == EMPTY_RETURN_AMOUNT) {
            assembly { return(0, 0) }
        }
        if (amount == FALSE_RETURN_AMOUNT) {
            return false;
        }
        if (amount == REVERT_RETURN_AMOUNT) {
            revert("TestTokenSpenderERC20Token/Revert");
        }
        return true;
    }

    function setBalanceAndAllowanceOf(
        address owner,
        uint256 balance,
        address spender,
        uint256 allowance_
    )
        external
    {
        balanceOf[owner] = balance;
        allowance[owner][spender] = allowance_;
    }
}

/// @dev Feature that allows spending token allowances.
contract TokenSpender is
    IFeature,
    ITokenSpender,
    FixinCommon
{
    // solhint-disable
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "TokenSpender";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);
    /// @dev The implementation address of this feature.
    address private immutable _implementation;
    // solhint-enable

    using LibRichErrorsV06 for bytes;

    constructor() public {
        _implementation = address(this);
    }

    /// @dev Initialize and register this feature. Should be delegatecalled
    ///      into during a `Migrate.migrate()`.
    /// @param allowanceTarget An `allowanceTarget` instance, configured to have
    ///        the ZeroeEx contract as an authority.
    /// @return success `MIGRATE_SUCCESS` on success.
    function migrate(IAllowanceTarget allowanceTarget) external returns (bytes4 success) {
        LibTokenSpenderStorage.getStorage().allowanceTarget = allowanceTarget;
        ISimpleFunctionRegistry(address(this))
            .extend(this.getAllowanceTarget.selector, _implementation);
        ISimpleFunctionRegistry(address(this))
            .extend(this._spendERC20Tokens.selector, _implementation);
        ISimpleFunctionRegistry(address(this))
            .extend(this.getSpendableERC20BalanceOf.selector, _implementation);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Transfers ERC20 tokens from `owner` to `to`. Only callable from within.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _spendERC20Tokens(
        IERC20TokenV06 token,
        address owner,
        address to,
        uint256 amount
    )
        external
        override
        onlySelf
    {
        IAllowanceTarget spender = LibTokenSpenderStorage.getStorage().allowanceTarget;
        // Have the allowance target execute an ERC20 `transferFrom()`.
        (bool didSucceed, bytes memory resultData) = address(spender).call(
            abi.encodeWithSelector(
                IAllowanceTarget.executeCall.selector,
                address(token),
                abi.encodeWithSelector(
                    IERC20TokenV06.transferFrom.selector,
                    owner,
                    to,
                    amount
                )
            )
        );
        if (didSucceed) {
            resultData = abi.decode(resultData, (bytes));
        }
        if (!didSucceed || !LibERC20TokenV06.isSuccessfulResult(resultData)) {
            LibSpenderRichErrors.SpenderERC20TransferFromFailedError(
                address(token),
                owner,
                to,
                amount,
                resultData
            ).rrevert();
        }
    }

    /// @dev Gets the maximum amount of an ERC20 token `token` that can be
    ///      pulled from `owner` by the token spender.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @return amount The amount of tokens that can be pulled.
    function getSpendableERC20BalanceOf(IERC20TokenV06 token, address owner)
        external
        override
        view
        returns (uint256 amount)
    {
        return LibSafeMathV06.min256(
            token.allowance(owner, address(LibTokenSpenderStorage.getStorage().allowanceTarget)),
            token.balanceOf(owner)
        );
    }

    /// @dev Get the address of the allowance target.
    /// @return target The target of token allowances.
    function getAllowanceTarget()
        external
        override
        view
        returns (address target)
    {
        return address(LibTokenSpenderStorage.getStorage().allowanceTarget);
    }
}

contract TestTokenSpender is
    TokenSpender
{
    modifier onlySelf() override {
        _;
    }
}

contract TestSimpleFunctionRegistryFeatureImpl2 is
    FixinCommon
{
    function testFn()
        external
        pure
        returns (uint256 id)
    {
        return 1338;
    }
}

contract TestSimpleFunctionRegistryFeatureImpl1 is
    FixinCommon
{
    function testFn()
        external
        pure
        returns (uint256 id)
    {
        return 1337;
    }
}

contract TestMintTokenERC20Transformer is
    IERC20Transformer
{
    struct TransformData {
        IERC20TokenV06 inputToken;
        TestMintableERC20Token outputToken;
        uint256 burnAmount;
        uint256 mintAmount;
        uint256 feeAmount;
    }

    event MintTransform(
        address context,
        address caller,
        bytes32 callDataHash,
        address taker,
        bytes data,
        uint256 inputTokenBalance,
        uint256 ethBalance
    );

    function transform(
        bytes32 callDataHash,
        address payable taker,
        bytes calldata data_
    )
        external
        override
        returns (bytes4 success)
    {
        TransformData memory data = abi.decode(data_, (TransformData));
        emit MintTransform(
            address(this),
            msg.sender,
            callDataHash,
            taker,
            data_,
            data.inputToken.balanceOf(address(this)),
            address(this).balance
        );
        // "Burn" input tokens.
        data.inputToken.transfer(address(0), data.burnAmount);
        // Mint output tokens.
        if (LibERC20Transformer.isTokenETH(IERC20TokenV06(address(data.outputToken)))) {
            taker.transfer(data.mintAmount);
        } else {
            data.outputToken.mint(
                taker,
                data.mintAmount
            );
            // Burn fees from output.
            data.outputToken.burn(taker, data.feeAmount);
        }
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}

contract TestMigrator {
    event TestMigrateCalled(
        bytes callData,
        address owner
    );

    function succeedingMigrate() external returns (bytes4 success) {
        emit TestMigrateCalled(
            msg.data,
            IOwnable(address(this)).owner()
        );
        return LibMigrate.MIGRATE_SUCCESS;
    }

    function failingMigrate() external returns (bytes4 success) {
        emit TestMigrateCalled(
            msg.data,
            IOwnable(address(this)).owner()
        );
        return 0xdeadbeef;
    }

    function revertingMigrate() external pure {
        revert("OOPSIE");
    }
}

/// @dev A contract for deploying and configuring a minimal ZeroEx contract.
contract InitialMigration {

    /// @dev Features to bootstrap into the the proxy contract.
    struct BootstrapFeatures {
        SimpleFunctionRegistry registry;
        Ownable ownable;
    }

    /// @dev The allowed caller of `deploy()`. In production, this would be
    ///      the governor.
    address public immutable deployer;
    /// @dev The real address of this contract.
    address private immutable _implementation;

    /// @dev Instantiate this contract and set the allowed caller of `deploy()`
    ///      to `deployer_`.
    /// @param deployer_ The allowed caller of `deploy()`.
    constructor(address deployer_) public {
        deployer = deployer_;
        _implementation = address(this);
    }

    /// @dev Deploy the `ZeroEx` contract with the minimum feature set,
    ///      transfers ownership to `owner`, then self-destructs.
    ///      Only callable by `deployer` set in the contstructor.
    /// @param owner The owner of the contract.
    /// @param features Features to bootstrap into the proxy.
    /// @return zeroEx The deployed and configured `ZeroEx` contract.
    function deploy(address payable owner, BootstrapFeatures memory features)
        public
        virtual
        returns (ZeroEx zeroEx)
    {
        // Must be called by the allowed deployer.
        require(msg.sender == deployer, "InitialMigration/INVALID_SENDER");

        // Deploy the ZeroEx contract, setting ourselves as the bootstrapper.
        zeroEx = new ZeroEx();

        // Bootstrap the initial feature set.
        IBootstrap(address(zeroEx)).bootstrap(
            address(this),
            abi.encodeWithSelector(this.bootstrap.selector, owner, features)
        );

        // Self-destruct. This contract should not hold any funds but we send
        // them to the owner just in case.
        this.die(owner);
    }

    /// @dev Sets up the initial state of the `ZeroEx` contract.
    ///      The `ZeroEx` contract will delegatecall into this function.
    /// @param owner The new owner of the ZeroEx contract.
    /// @param features Features to bootstrap into the proxy.
    /// @return success Magic bytes if successful.
    function bootstrap(address owner, BootstrapFeatures memory features)
        public
        virtual
        returns (bytes4 success)
    {
        // Deploy and migrate the initial features.
        // Order matters here.

        // Initialize Registry.
        LibBootstrap.delegatecallBootstrapFunction(
            address(features.registry),
            abi.encodeWithSelector(
                SimpleFunctionRegistry.bootstrap.selector
            )
        );

        // Initialize Ownable.
        LibBootstrap.delegatecallBootstrapFunction(
            address(features.ownable),
            abi.encodeWithSelector(
                Ownable.bootstrap.selector
            )
        );

        // De-register `SimpleFunctionRegistry._extendSelf`.
        SimpleFunctionRegistry(address(this)).rollback(
            SimpleFunctionRegistry._extendSelf.selector,
            address(0)
        );

        // Transfer ownership to the real owner.
        Ownable(address(this)).transferOwnership(owner);

        success = LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @dev Self-destructs this contract. Only callable by this contract.
    /// @param ethRecipient Who to transfer outstanding ETH to.
    function die(address payable ethRecipient) public virtual {
        require(msg.sender == _implementation, "InitialMigration/INVALID_SENDER");
        selfdestruct(ethRecipient);
    }
}

contract TestInitialMigration is
    InitialMigration
{
    address public bootstrapFeature;
    address public dieRecipient;

    // solhint-disable-next-line no-empty-blocks
    constructor(address deployer) public InitialMigration(deployer) {}

    function callBootstrap(ZeroEx zeroEx) external {
        IBootstrap(address(zeroEx)).bootstrap(address(this), new bytes(0));
    }

    function bootstrap(address owner, BootstrapFeatures memory features)
        public
        override
        returns (bytes4 success)
    {
        success = InitialMigration.bootstrap(owner, features);
        // Snoop the bootstrap feature contract.
        bootstrapFeature = ZeroEx(address(uint160(address(this))))
            .getFunctionImplementation(IBootstrap.bootstrap.selector);
    }

    function die(address payable ethRecipient) public override {
        dieRecipient = ethRecipient;
    }
}

/// @dev A contract for deploying and configuring the full ZeroEx contract.
contract FullMigration {

    // solhint-disable no-empty-blocks,indent

    /// @dev Features to add the the proxy contract.
    struct Features {
        SimpleFunctionRegistry registry;
        Ownable ownable;
        TokenSpender tokenSpender;
        TransformERC20 transformERC20;
    }

    /// @dev Parameters needed to initialize features.
    struct MigrateOpts {
        address transformerDeployer;
    }

    /// @dev The allowed caller of `deploy()`.
    address public immutable deployer;
    /// @dev The initial migration contract.
    InitialMigration private _initialMigration;

    /// @dev Instantiate this contract and set the allowed caller of `deploy()`
    ///      to `deployer`.
    /// @param deployer_ The allowed caller of `deploy()`.
    constructor(address payable deployer_)
        public
    {
        deployer = deployer_;
        // Create an initial migration contract with this contract set to the
        // allowed deployer.
        _initialMigration = new InitialMigration(address(this));
    }

    /// @dev Deploy the `ZeroEx` contract with the full feature set,
    ///      transfer ownership to `owner`, then self-destruct.
    /// @param owner The owner of the contract.
    /// @param features Features to add to the proxy.
    /// @return zeroEx The deployed and configured `ZeroEx` contract.
    /// @param migrateOpts Parameters needed to initialize features.
    function deploy(
        address payable owner,
        Features memory features,
        MigrateOpts memory migrateOpts
    )
        public
        returns (ZeroEx zeroEx)
    {
        require(msg.sender == deployer, "FullMigration/INVALID_SENDER");

        // Perform the initial migration with the owner set to this contract.
        zeroEx = _initialMigration.deploy(
            address(uint160(address(this))),
            InitialMigration.BootstrapFeatures({
                registry: features.registry,
                ownable: features.ownable
            })
        );

        // Add features.
        _addFeatures(zeroEx, owner, features, migrateOpts);

        // Transfer ownership to the real owner.
        IOwnable(address(zeroEx)).transferOwnership(owner);

        // Self-destruct.
        this.die(owner);
    }

    /// @dev Destroy this contract. Only callable from ourselves (from `deploy()`).
    /// @param ethRecipient Receiver of any ETH in this contract.
    function die(address payable ethRecipient)
        external
        virtual
    {
        require(msg.sender == address(this), "FullMigration/INVALID_SENDER");
        // This contract should not hold any funds but we send
        // them to the ethRecipient just in case.
        selfdestruct(ethRecipient);
    }

    /// @dev Deploy and register features to the ZeroEx contract.
    /// @param zeroEx The bootstrapped ZeroEx contract.
    /// @param owner The ultimate owner of the ZeroEx contract.
    /// @param features Features to add to the proxy.
    /// @param migrateOpts Parameters needed to initialize features.
    function _addFeatures(
        ZeroEx zeroEx,
        address owner,
        Features memory features,
        MigrateOpts memory migrateOpts
    )
        private
    {
        IOwnable ownable = IOwnable(address(zeroEx));
        // TokenSpender
        {
            // Create the allowance target.
            AllowanceTarget allowanceTarget = new AllowanceTarget();
            // Let the ZeroEx contract use the allowance target.
            allowanceTarget.addAuthorizedAddress(address(zeroEx));
            // Transfer ownership of the allowance target to the (real) owner.
            allowanceTarget.transferOwnership(owner);
            // Register the feature.
            ownable.migrate(
                address(features.tokenSpender),
                abi.encodeWithSelector(
                    TokenSpender.migrate.selector,
                    allowanceTarget
                ),
                address(this)
            );
        }
        // TransformERC20
        {
            // Register the feature.
            ownable.migrate(
                address(features.transformERC20),
                abi.encodeWithSelector(
                    TransformERC20.migrate.selector,
                    migrateOpts.transformerDeployer
                ),
                address(this)
            );
        }
    }
}

contract TestFullMigration is
    FullMigration
{
    address public dieRecipient;

    // solhint-disable-next-line no-empty-blocks
    constructor(address payable deployer) public FullMigration(deployer) {}

    function die(address payable ethRecipient) external override {
        dieRecipient = ethRecipient;
    }
}

contract TestFillQuoteTransformerHost is
    TestTransformerHost
{
    function executeTransform(
        IERC20Transformer transformer,
        TestMintableERC20Token inputToken,
        uint256 inputTokenAmount,
        bytes calldata data
    )
        external
        payable
    {
        if (inputTokenAmount != 0) {
            inputToken.mint(address(this), inputTokenAmount);
        }
        // Have to make this call externally because transformers aren't payable.
        this.rawExecuteTransform(transformer, bytes32(0), msg.sender, data);
    }
}

contract TestFillQuoteTransformerExchange {

    struct FillBehavior {
        // How much of the order is filled, in taker asset amount.
        uint256 filledTakerAssetAmount;
        // Scaling for maker assets minted, in 1e18.
        uint256 makerAssetMintRatio;
    }

    uint256 private constant PROTOCOL_FEE_MULTIPLIER = 1337;

    using LibSafeMathV06 for uint256;

    function fillOrder(
        IExchange.Order calldata order,
        uint256 takerAssetFillAmount,
        bytes calldata signature
    )
        external
        payable
        returns (IExchange.FillResults memory fillResults)
    {
        require(
            signature.length != 0,
            "TestFillQuoteTransformerExchange/INVALID_SIGNATURE"
        );
        // The signature is the ABI-encoded FillBehavior data.
        FillBehavior memory behavior = abi.decode(signature, (FillBehavior));

        uint256 protocolFee = PROTOCOL_FEE_MULTIPLIER * tx.gasprice;
        require(
            msg.value == protocolFee,
            "TestFillQuoteTransformerExchange/INSUFFICIENT_PROTOCOL_FEE"
        );
        // Return excess protocol fee.
        msg.sender.transfer(msg.value - protocolFee);

        // Take taker tokens.
        TestMintableERC20Token takerToken = _getTokenFromAssetData(order.takerAssetData);
        takerAssetFillAmount = LibSafeMathV06.min256(
            order.takerAssetAmount.safeSub(behavior.filledTakerAssetAmount),
            takerAssetFillAmount
        );
        require(
            takerToken.getSpendableAmount(msg.sender, address(this)) >= takerAssetFillAmount,
            "TestFillQuoteTransformerExchange/INSUFFICIENT_TAKER_FUNDS"
        );
        takerToken.transferFrom(msg.sender, order.makerAddress, takerAssetFillAmount);

        // Mint maker tokens.
        uint256 makerAssetFilledAmount = LibMathV06.getPartialAmountFloor(
            takerAssetFillAmount,
            order.takerAssetAmount,
            order.makerAssetAmount
        );
        TestMintableERC20Token makerToken = _getTokenFromAssetData(order.makerAssetData);
        makerToken.mint(
            msg.sender,
            LibMathV06.getPartialAmountFloor(
                behavior.makerAssetMintRatio,
                1e18,
                makerAssetFilledAmount
            )
        );

        // Take taker fee.
        TestMintableERC20Token takerFeeToken = _getTokenFromAssetData(order.takerFeeAssetData);
        uint256 takerFee = LibMathV06.getPartialAmountFloor(
            takerAssetFillAmount,
            order.takerAssetAmount,
            order.takerFee
        );
        require(
            takerFeeToken.getSpendableAmount(msg.sender, address(this)) >= takerFee,
            "TestFillQuoteTransformerExchange/INSUFFICIENT_TAKER_FEE_FUNDS"
        );
        takerFeeToken.transferFrom(msg.sender, order.feeRecipientAddress, takerFee);

        fillResults.makerAssetFilledAmount = makerAssetFilledAmount;
        fillResults.takerAssetFilledAmount = takerAssetFillAmount;
        fillResults.makerFeePaid = uint256(-1);
        fillResults.takerFeePaid = takerFee;
        fillResults.protocolFeePaid = protocolFee;
    }

    function encodeBehaviorData(FillBehavior calldata behavior)
        external
        pure
        returns (bytes memory encoded)
    {
        return abi.encode(behavior);
    }

    function protocolFeeMultiplier()
        external
        pure
        returns (uint256)
    {
        return PROTOCOL_FEE_MULTIPLIER;
    }

    function getAssetProxy(bytes4)
        external
        view
        returns (address)
    {
        return address(this);
    }

    function _getTokenFromAssetData(bytes memory assetData)
        private
        pure
        returns (TestMintableERC20Token token)
    {
        return TestMintableERC20Token(LibBytesV06.readAddress(assetData, 16));
    }
}

contract TestDelegateCaller {
    function executeDelegateCall(
        address target,
        bytes calldata callData
    )
        external
    {
        (bool success, bytes memory resultData) = target.delegatecall(callData);
        if (!success) {
            assembly { revert(add(resultData, 32), mload(resultData)) }
        }
        assembly { return(add(resultData, 32), mload(resultData)) }
    }
}

contract TestCallTarget {

    event CallTargetCalled(
        address context,
        address sender,
        bytes data,
        uint256 value
    );

    bytes4 private constant MAGIC_BYTES = 0x12345678;
    bytes private constant REVERTING_DATA = hex"1337";

    fallback() external payable {
        if (keccak256(msg.data) == keccak256(REVERTING_DATA)) {
            revert("TestCallTarget/REVERT");
        }
        emit CallTargetCalled(
            address(this),
            msg.sender,
            msg.data,
            msg.value
        );
        bytes4 rval = MAGIC_BYTES;
        assembly {
            mstore(0, rval)
            return(0, 32)
        }
    }
}

interface ITestSimpleFunctionRegistryFeature {
    function testFn() external view returns (uint256 id);
}

interface IEtherTokenV06 is
    IERC20TokenV06
{
    /// @dev Wrap ether.
    function deposit() external payable;

    /// @dev Unwrap ether.
    function withdraw(uint256 amount) external;
}

/// @dev A transformer that wraps or unwraps WETH.
contract WethTransformer is
    Transformer
{
    using LibRichErrorsV06 for bytes;
    using LibSafeMathV06 for uint256;
    using LibERC20Transformer for IERC20TokenV06;

    /// @dev Transform data to ABI-encode and pass into `transform()`.
    struct TransformData {
        // The token to wrap/unwrap. Must be either ETH or WETH.
        IERC20TokenV06 token;
        // Amount of `token` to wrap or unwrap.
        // `uint(-1)` will unwrap the entire balance.
        uint256 amount;
    }

    /// @dev The WETH contract address.
    IEtherTokenV06 public immutable weth;
    /// @dev Maximum uint256 value.
    uint256 private constant MAX_UINT256 = uint256(-1);

    /// @dev Construct the transformer and store the WETH address in an immutable.
    /// @param weth_ The weth token.
    constructor(IEtherTokenV06 weth_)
        public
        Transformer()
    {
        weth = weth_;
    }

    /// @dev Wraps and unwraps WETH.
    /// @param data_ ABI-encoded `TransformData`, indicating which token to wrap/umwrap.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(
        bytes32, // callDataHash,
        address payable, // taker,
        bytes calldata data_
    )
        external
        override
        returns (bytes4 success)
    {
        TransformData memory data = abi.decode(data_, (TransformData));
        if (!data.token.isTokenETH() && data.token != weth) {
            LibTransformERC20RichErrors.InvalidTransformDataError(
                LibTransformERC20RichErrors.InvalidTransformDataErrorCode.INVALID_TOKENS,
                data_
            ).rrevert();
        }

        uint256 amount = data.amount;
        if (amount == MAX_UINT256) {
            amount = data.token.getTokenBalanceOf(address(this));
        }

        if (amount != 0) {
            if (data.token.isTokenETH()) {
                // Wrap ETH.
                weth.deposit{value: amount}();
            } else {
                // Unwrap WETH.
                weth.withdraw(amount);
            }
        }
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}

/// @dev A transformer that transfers tokens to the taker.
contract PayTakerTransformer is
    Transformer
{
    // solhint-disable no-empty-blocks
    using LibRichErrorsV06 for bytes;
    using LibSafeMathV06 for uint256;
    using LibERC20Transformer for IERC20TokenV06;

    /// @dev Transform data to ABI-encode and pass into `transform()`.
    struct TransformData {
        // The tokens to transfer to the taker.
        IERC20TokenV06[] tokens;
        // Amount of each token in `tokens` to transfer to the taker.
        // `uint(-1)` will transfer the entire balance.
        uint256[] amounts;
    }

    /// @dev Maximum uint256 value.
    uint256 private constant MAX_UINT256 = uint256(-1);

    /// @dev Create this contract.
    constructor()
        public
        Transformer()
    {}

    /// @dev Forwards tokens to the taker.
    /// @param taker The taker address (caller of `TransformERC20.transformERC20()`).
    /// @param data_ ABI-encoded `TransformData`, indicating which tokens to transfer.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(
        bytes32, // callDataHash,
        address payable taker,
        bytes calldata data_
    )
        external
        override
        returns (bytes4 success)
    {
        TransformData memory data = abi.decode(data_, (TransformData));

        // Transfer tokens directly to the taker.
        for (uint256 i = 0; i < data.tokens.length; ++i) {
            // The `amounts` array can be shorter than the `tokens` array.
            // Missing elements are treated as `uint256(-1)`.
            uint256 amount = data.amounts.length > i ? data.amounts[i] : uint256(-1);
            if (amount == MAX_UINT256) {
                amount = data.tokens[i].getTokenBalanceOf(address(this));
            }
            if (amount != 0) {
                data.tokens[i].transformerTransfer(taker, amount);
            }
        }
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}

/// @dev Interface to the V3 Exchange.
interface IExchange {

    /// @dev V3 Order structure.
    struct Order {
        // Address that created the order.
        address makerAddress;
        // Address that is allowed to fill the order.
        // If set to 0, any address is allowed to fill the order.
        address takerAddress;
        // Address that will recieve fees when order is filled.
        address feeRecipientAddress;
        // Address that is allowed to call Exchange contract methods that affect this order.
        // If set to 0, any address is allowed to call these methods.
        address senderAddress;
        // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 makerAssetAmount;
        // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 takerAssetAmount;
        // Fee paid to feeRecipient by maker when order is filled.
        uint256 makerFee;
        // Fee paid to feeRecipient by taker when order is filled.
        uint256 takerFee;
        // Timestamp in seconds at which order expires.
        uint256 expirationTimeSeconds;
        // Arbitrary number to facilitate uniqueness of the order's hash.
        uint256 salt;
        // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset.
        // The leading bytes4 references the id of the asset proxy.
        bytes makerAssetData;
        // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset.
        // The leading bytes4 references the id of the asset proxy.
        bytes takerAssetData;
        // Encoded data that can be decoded by a specified proxy contract when transferring makerFeeAsset.
        // The leading bytes4 references the id of the asset proxy.
        bytes makerFeeAssetData;
        // Encoded data that can be decoded by a specified proxy contract when transferring takerFeeAsset.
        // The leading bytes4 references the id of the asset proxy.
        bytes takerFeeAssetData;
    }

    /// @dev V3 `fillOrder()` results.`
    struct FillResults {
        // Total amount of makerAsset(s) filled.
        uint256 makerAssetFilledAmount;
        // Total amount of takerAsset(s) filled.
        uint256 takerAssetFilledAmount;
        // Total amount of fees paid by maker(s) to feeRecipient(s).
        uint256 makerFeePaid;
        // Total amount of fees paid by taker to feeRecipients(s).
        uint256 takerFeePaid;
        // Total amount of fees paid by taker to the staking contract.
        uint256 protocolFeePaid;
    }

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param takerAssetFillAmount Desired amount of takerAsset to sell.
    /// @param signature Proof that order has been created by maker.
    /// @return fillResults Amounts filled and fees paid by maker and taker.
    function fillOrder(
        Order calldata order,
        uint256 takerAssetFillAmount,
        bytes calldata signature
    )
        external
        payable
        returns (FillResults memory fillResults);

    /// @dev Returns the protocolFeeMultiplier
    /// @return multiplier The multiplier for protocol fees.
    function protocolFeeMultiplier()
        external
        view
        returns (uint256 multiplier);

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return proxyAddress The asset proxy registered to assetProxyId.
    ///         Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address proxyAddress);
}

library LibMathRichErrorsV06 {

    // bytes4(keccak256("DivisionByZeroError()"))
    bytes internal constant DIVISION_BY_ZERO_ERROR =
        hex"a791837c";

    // bytes4(keccak256("RoundingError(uint256,uint256,uint256)"))
    bytes4 internal constant ROUNDING_ERROR_SELECTOR =
        0x339f3de2;

    // solhint-disable func-name-mixedcase
    function DivisionByZeroError()
        internal
        pure
        returns (bytes memory)
    {
        return DIVISION_BY_ZERO_ERROR;
    }

    function RoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ROUNDING_ERROR_SELECTOR,
            numerator,
            denominator,
            target
        );
    }
}

library LibMathV06 {

    using LibSafeMathV06 for uint256;

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        if (isRoundingErrorFloor(
                numerator,
                denominator,
                target
        )) {
            LibRichErrorsV06.rrevert(LibMathRichErrorsV06.RoundingError(
                numerator,
                denominator,
                target
            ));
        }

        partialAmount = numerator.safeMul(target).safeDiv(denominator);
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded up.
    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        if (isRoundingErrorCeil(
                numerator,
                denominator,
                target
        )) {
            LibRichErrorsV06.rrevert(LibMathRichErrorsV06.RoundingError(
                numerator,
                denominator,
                target
            ));
        }

        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator.safeMul(target)
            .safeAdd(denominator.safeSub(1))
            .safeDiv(denominator);

        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded down.
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        partialAmount = numerator.safeMul(target).safeDiv(denominator);
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount Partial value of target rounded up.
    function getPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator.safeMul(target)
            .safeAdd(denominator.safeSub(1))
            .safeDiv(denominator);

        return partialAmount;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        if (denominator == 0) {
            LibRichErrorsV06.rrevert(LibMathRichErrorsV06.DivisionByZeroError());
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * denominator)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = remainder.safeMul(1000) >= numerator.safeMul(target);
        return isError;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        if (denominator == 0) {
            LibRichErrorsV06.rrevert(LibMathRichErrorsV06.DivisionByZeroError());
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = denominator.safeSub(remainder) % denominator;
        isError = remainder.safeMul(1000) >= numerator.safeMul(target);
        return isError;
    }
}

/// @dev A transformer that fills an ERC20 market sell/buy quote.
contract FillQuoteTransformer is
    Transformer
{
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibERC20Transformer for IERC20TokenV06;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    /// @dev Whether we are performing a market sell or buy.
    enum Side {
        Sell,
        Buy
    }

    /// @dev Transform data to ABI-encode and pass into `transform()`.
    struct TransformData {
        // Whether we aer performing a market sell or buy.
        Side side;
        // The token being sold.
        // This should be an actual token, not the ETH pseudo-token.
        IERC20TokenV06 sellToken;
        // The token being bought.
        // This should be an actual token, not the ETH pseudo-token.
        IERC20TokenV06 buyToken;
        // The orders to fill.
        IExchange.Order[] orders;
        // Signatures for each respective order in `orders`.
        bytes[] signatures;
        // Maximum fill amount for each order. This may be shorter than the
        // number of orders, where missing entries will be treated as `uint256(-1)`.
        // For sells, this will be the maximum sell amount (taker asset).
        // For buys, this will be the maximum buy amount (maker asset).
        uint256[] maxOrderFillAmounts;
        // Amount of `sellToken` to sell or `buyToken` to buy.
        // For sells, this may be `uint256(-1)` to sell the entire balance of
        // `sellToken`.
        uint256 fillAmount;
    }

    /// @dev Results of a call to `_fillOrder()`.
    struct FillOrderResults {
        // The amount of taker tokens sold, according to balance checks.
        uint256 takerTokenSoldAmount;
        // The amount of maker tokens sold, according to balance checks.
        uint256 makerTokenBoughtAmount;
        // The amount of protocol fee paid.
        uint256 protocolFeePaid;
    }

    /// @dev The Exchange ERC20Proxy ID.
    bytes4 private constant ERC20_ASSET_PROXY_ID = 0xf47261b0;
    /// @dev Maximum uint256 value.
    uint256 private constant MAX_UINT256 = uint256(-1);

    /// @dev The Exchange contract.
    IExchange public immutable exchange;
    /// @dev The ERC20Proxy address.
    address public immutable erc20Proxy;

    /// @dev Create this contract.
    /// @param exchange_ The Exchange V3 instance.
    constructor(IExchange exchange_)
        public
        Transformer()
    {
        exchange = exchange_;
        erc20Proxy = exchange_.getAssetProxy(ERC20_ASSET_PROXY_ID);
    }

    /// @dev Sell this contract's entire balance of of `sellToken` in exchange
    ///      for `buyToken` by filling `orders`. Protocol fees should be attached
    ///      to this call. `buyToken` and excess ETH will be transferred back to the caller.
    /// @param data_ ABI-encoded `TransformData`.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(
        bytes32, // callDataHash,
        address payable, // taker,
        bytes calldata data_
    )
        external
        override
        returns (bytes4 success)
    {
        TransformData memory data = abi.decode(data_, (TransformData));

        // Validate data fields.
        if (data.sellToken.isTokenETH() || data.buyToken.isTokenETH()) {
            LibTransformERC20RichErrors.InvalidTransformDataError(
                LibTransformERC20RichErrors.InvalidTransformDataErrorCode.INVALID_TOKENS,
                data_
            ).rrevert();
        }
        if (data.orders.length != data.signatures.length) {
            LibTransformERC20RichErrors.InvalidTransformDataError(
                LibTransformERC20RichErrors.InvalidTransformDataErrorCode.INVALID_ARRAY_LENGTH,
                data_
            ).rrevert();
        }

        if (data.side == Side.Sell && data.fillAmount == MAX_UINT256) {
            // If `sellAmount == -1 then we are selling
            // the entire balance of `sellToken`. This is useful in cases where
            // the exact sell amount is not exactly known in advance, like when
            // unwrapping Chai/cUSDC/cDAI.
            data.fillAmount = data.sellToken.getTokenBalanceOf(address(this));
        }

        // Approve the ERC20 proxy to spend `sellToken`.
        data.sellToken.approveIfBelow(erc20Proxy, data.fillAmount);

        // Fill the orders.
        uint256 singleProtocolFee = exchange.protocolFeeMultiplier().safeMul(tx.gasprice);
        uint256 ethRemaining = address(this).balance;
        uint256 boughtAmount = 0;
        uint256 soldAmount = 0;
        for (uint256 i = 0; i < data.orders.length; ++i) {
            // Check if we've hit our targets.
            if (data.side == Side.Sell) {
                // Market sell check.
                if (soldAmount >= data.fillAmount) {
                    break;
                }
            } else {
                // Market buy check.
                if (boughtAmount >= data.fillAmount) {
                    break;
                }
            }

            // Ensure we have enough ETH to cover the protocol fee.
            if (ethRemaining < singleProtocolFee) {
                LibTransformERC20RichErrors
                    .InsufficientProtocolFeeError(ethRemaining, singleProtocolFee)
                    .rrevert();
            }

            // Fill the order.
            FillOrderResults memory results;
            if (data.side == Side.Sell) {
                // Market sell.
                results = _sellToOrder(
                    data.buyToken,
                    data.sellToken,
                    data.orders[i],
                    data.signatures[i],
                    data.fillAmount.safeSub(soldAmount).min256(
                        data.maxOrderFillAmounts.length > i
                        ? data.maxOrderFillAmounts[i]
                        : MAX_UINT256
                    ),
                    singleProtocolFee
                );
            } else {
                // Market buy.
                results = _buyFromOrder(
                    data.buyToken,
                    data.sellToken,
                    data.orders[i],
                    data.signatures[i],
                    data.fillAmount.safeSub(boughtAmount).min256(
                        data.maxOrderFillAmounts.length > i
                        ? data.maxOrderFillAmounts[i]
                        : MAX_UINT256
                    ),
                    singleProtocolFee
                );
            }

            // Accumulate totals.
            soldAmount = soldAmount.safeAdd(results.takerTokenSoldAmount);
            boughtAmount = boughtAmount.safeAdd(results.makerTokenBoughtAmount);
            ethRemaining = ethRemaining.safeSub(results.protocolFeePaid);
        }

        // Ensure we hit our targets.
        if (data.side == Side.Sell) {
            // Market sell check.
            if (soldAmount < data.fillAmount) {
                LibTransformERC20RichErrors
                    .IncompleteFillSellQuoteError(
                        address(data.sellToken),
                        soldAmount,
                        data.fillAmount
                    ).rrevert();
            }
        } else {
            // Market buy check.
            if (boughtAmount < data.fillAmount) {
                LibTransformERC20RichErrors
                    .IncompleteFillBuyQuoteError(
                        address(data.buyToken),
                        boughtAmount,
                        data.fillAmount
                    ).rrevert();
            }
        }
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }

    /// @dev Try to sell up to `sellAmount` from an order.
    /// @param makerToken The maker/buy token.
    /// @param takerToken The taker/sell token.
    /// @param order The order to fill.
    /// @param signature The signature for `order`.
    /// @param sellAmount Amount of taker token to sell.
    /// @param protocolFee The protocol fee needed to fill `order`.
    function _sellToOrder(
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        IExchange.Order memory order,
        bytes memory signature,
        uint256 sellAmount,
        uint256 protocolFee
    )
        private
        returns (FillOrderResults memory results)
    {
        IERC20TokenV06 takerFeeToken =
            _getTokenFromERC20AssetData(order.takerFeeAssetData);

        uint256 takerTokenFillAmount = sellAmount;

        if (order.takerFee != 0) {
            if (takerFeeToken == makerToken) {
                // Taker fee is payable in the maker token, so we need to
                // approve the proxy to spend the maker token.
                // It isn't worth computing the actual taker fee
                // since `approveIfBelow()` will set the allowance to infinite. We
                // just need a reasonable upper bound to avoid unnecessarily re-approving.
                takerFeeToken.approveIfBelow(erc20Proxy, order.takerFee);
            } else if (takerFeeToken == takerToken){
                // Taker fee is payable in the taker token, so we need to
                // reduce the fill amount to cover the fee.
                // takerTokenFillAmount' =
                //   (takerTokenFillAmount * order.takerAssetAmount) /
                //   (order.takerAssetAmount + order.takerFee)
                takerTokenFillAmount = LibMathV06.getPartialAmountCeil(
                    order.takerAssetAmount,
                    order.takerAssetAmount.safeAdd(order.takerFee),
                    sellAmount
                );
            } else {
                //  Only support taker or maker asset denominated taker fees.
                LibTransformERC20RichErrors.InvalidTakerFeeTokenError(
                    address(takerFeeToken)
                ).rrevert();
            }
        }

        // Clamp fill amount to order size.
        takerTokenFillAmount = LibSafeMathV06.min256(
            takerTokenFillAmount,
            order.takerAssetAmount
        );

        // Perform the fill.
        return _fillOrder(
            order,
            signature,
            takerTokenFillAmount,
            protocolFee,
            makerToken,
            takerFeeToken == takerToken
        );
    }

    /// @dev Try to buy up to `buyAmount` from an order.
    /// @param makerToken The maker/buy token.
    /// @param takerToken The taker/sell token.
    /// @param order The order to fill.
    /// @param signature The signature for `order`.
    /// @param buyAmount Amount of maker token to buy.
    /// @param protocolFee The protocol fee needed to fill `order`.
    function _buyFromOrder(
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        IExchange.Order memory order,
        bytes memory signature,
        uint256 buyAmount,
        uint256 protocolFee
    )
        private
        returns (FillOrderResults memory results)
    {
        IERC20TokenV06 takerFeeToken =
            _getTokenFromERC20AssetData(order.takerFeeAssetData);
        // Compute the default taker token fill amount.
        uint256 takerTokenFillAmount = LibMathV06.getPartialAmountCeil(
            buyAmount,
            order.makerAssetAmount,
            order.takerAssetAmount
        );

        if (order.takerFee != 0) {
            if (takerFeeToken == makerToken) {
                // Taker fee is payable in the maker token.
                // Adjust the taker token fill amount to account for maker
                // tokens being lost to the taker fee.
                // takerTokenFillAmount' =
                //  (order.takerAssetAmount * buyAmount) /
                //  (order.makerAssetAmount - order.takerFee)
                takerTokenFillAmount = LibMathV06.getPartialAmountCeil(
                    buyAmount,
                    order.makerAssetAmount.safeSub(order.takerFee),
                    order.takerAssetAmount
                );
                // Approve the proxy to spend the maker token.
                // It isn't worth computing the actual taker fee
                // since `approveIfBelow()` will set the allowance to infinite. We
                // just need a reasonable upper bound to avoid unnecessarily re-approving.
                takerFeeToken.approveIfBelow(erc20Proxy, order.takerFee);
            } else if (takerFeeToken != takerToken) {
                //  Only support taker or maker asset denominated taker fees.
                LibTransformERC20RichErrors.InvalidTakerFeeTokenError(
                    address(takerFeeToken)
                ).rrevert();
            }
        }

        // Clamp to order size.
        takerTokenFillAmount = LibSafeMathV06.min256(
            order.takerAssetAmount,
            takerTokenFillAmount
        );

        // Perform the fill.
        return _fillOrder(
            order,
            signature,
            takerTokenFillAmount,
            protocolFee,
            makerToken,
            takerFeeToken == takerToken
        );
    }

    /// @dev Attempt to fill an order. If the fill reverts, the revert will be
    ///      swallowed and `results` will be zeroed out.
    /// @param order The order to fill.
    /// @param signature The order signature.
    /// @param takerAssetFillAmount How much taker asset to fill.
    /// @param protocolFee The protocol fee needed to fill this order.
    /// @param makerToken The maker token.
    /// @param isTakerFeeInTakerToken Whether the taker fee token is the same as the
    ///        taker token.
    function _fillOrder(
        IExchange.Order memory order,
        bytes memory signature,
        uint256 takerAssetFillAmount,
        uint256 protocolFee,
        IERC20TokenV06 makerToken,
        bool isTakerFeeInTakerToken
    )
        private
        returns (FillOrderResults memory results)
    {
        // Track changes in the maker token balance.
        uint256 initialMakerTokenBalance = makerToken.balanceOf(address(this));
        try
            exchange.fillOrder
                {value: protocolFee}
                (order, takerAssetFillAmount, signature)
            returns (IExchange.FillResults memory fillResults)
        {
            // Update maker quantity based on changes in token balances.
            results.makerTokenBoughtAmount = makerToken.balanceOf(address(this))
                .safeSub(initialMakerTokenBalance);
            // We can trust the other fill result quantities.
            results.protocolFeePaid = fillResults.protocolFeePaid;
            results.takerTokenSoldAmount = fillResults.takerAssetFilledAmount;
            // If the taker fee is payable in the taker asset, include the
            // taker fee in the total amount sold.
            if (isTakerFeeInTakerToken) {
                results.takerTokenSoldAmount =
                    results.takerTokenSoldAmount.safeAdd(fillResults.takerFeePaid);
            }
        } catch (bytes memory) {
            // Swallow failures, leaving all results as zero.
        }
    }

    /// @dev Extract the token from plain ERC20 asset data.
    ///      If the asset-data is empty, a zero token address will be returned.
    /// @param assetData The order asset data.
    function _getTokenFromERC20AssetData(bytes memory assetData)
        private
        pure
        returns (IERC20TokenV06 token)
    {
        if (assetData.length == 0) {
            return IERC20TokenV06(address(0));
        }
        if (assetData.length != 36 ||
            LibBytesV06.readBytes4(assetData, 0) != ERC20_ASSET_PROXY_ID)
        {
            LibTransformERC20RichErrors
                .InvalidERC20AssetDataError(assetData)
                .rrevert();
        }
        return IERC20TokenV06(LibBytesV06.readAddress(assetData, 16));
    }
}

/// @dev A transformer that transfers tokens to arbitrary addresses.
contract AffiliateFeeTransformer is
    Transformer
{
    // solhint-disable no-empty-blocks
    using LibRichErrorsV06 for bytes;
    using LibSafeMathV06 for uint256;
    using LibERC20Transformer for IERC20TokenV06;

    /// @dev Information for a single fee.
    struct TokenFee {
        // The token to transfer to `recipient`.
        IERC20TokenV06 token;
        // Amount of each `token` to transfer to `recipient`.
        // If `amount == uint256(-1)`, the entire balance of `token` will be
        // transferred.
        uint256 amount;
        // Recipient of `token`.
        address payable recipient;
    }

    uint256 private constant MAX_UINT256 = uint256(-1);

    /// @dev Create this contract.
    constructor()
        public
        Transformer()
    {}

    /// @dev Transfers tokens to recipients.
    /// @param data ABI-encoded `TokenFee[]`, indicating which tokens to transfer.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(
        bytes32, // callDataHash,
        address payable, // taker,
        bytes calldata data
    )
        external
        override
        returns (bytes4 success)
    {
        TokenFee[] memory fees = abi.decode(data, (TokenFee[]));

        // Transfer tokens to recipients.
        for (uint256 i = 0; i < fees.length; ++i) {
            uint256 amount = fees[i].amount;
            if (amount == MAX_UINT256) {
                amount = LibERC20Transformer.getTokenBalanceOf(fees[i].token, address(this));
            }
            if (amount != 0) {
                fees[i].token.transformerTransfer(fees[i].recipient, amount);
            }
        }

        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }
}

library LibERC20Transformer {

    using LibERC20TokenV06 for IERC20TokenV06;

    /// @dev ETH pseudo-token address.
    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev Return value indicating success in `IERC20Transformer.transform()`.
    ///      This is just `keccak256('TRANSFORMER_SUCCESS')`.
    bytes4 constant internal TRANSFORMER_SUCCESS = 0x13c9929e;

    /// @dev Transfer ERC20 tokens and ETH.
    /// @param token An ERC20 or the ETH pseudo-token address (`ETH_TOKEN_ADDRESS`).
    /// @param to The recipient.
    /// @param amount The transfer amount.
    function transformerTransfer(
        IERC20TokenV06 token,
        address payable to,
        uint256 amount
    )
        internal
    {
        if (isTokenETH(token)) {
            to.transfer(amount);
        } else {
            token.compatTransfer(to, amount);
        }
    }

    /// @dev Check if a token is the ETH pseudo-token.
    /// @param token The token to check.
    /// @return isETH `true` if the token is the ETH pseudo-token.
    function isTokenETH(IERC20TokenV06 token)
        internal
        pure
        returns (bool isETH)
    {
        return address(token) == ETH_TOKEN_ADDRESS;
    }

    /// @dev Check the balance of an ERC20 token or ETH.
    /// @param token An ERC20 or the ETH pseudo-token address (`ETH_TOKEN_ADDRESS`).
    /// @param owner Holder of the tokens.
    /// @return tokenBalance The balance of `owner`.
    function getTokenBalanceOf(IERC20TokenV06 token, address owner)
        internal
        view
        returns (uint256 tokenBalance)
    {
        if (isTokenETH(token)) {
            return owner.balance;
        }
        return token.balanceOf(owner);
    }

    /// @dev RLP-encode a 32-bit or less account nonce.
    /// @param nonce A positive integer in the range 0 <= nonce < 2^32.
    /// @return rlpNonce The RLP encoding.
    function rlpEncodeNonce(uint32 nonce)
        internal
        pure
        returns (bytes memory rlpNonce)
    {
        // See https://github.com/ethereum/wiki/wiki/RLP for RLP encoding rules.
        if (nonce == 0) {
            rlpNonce = new bytes(1);
            rlpNonce[0] = 0x80;
        } else if (nonce < 0x80) {
            rlpNonce = new bytes(1);
            rlpNonce[0] = byte(uint8(nonce));
        } else if (nonce <= 0xFF) {
            rlpNonce = new bytes(2);
            rlpNonce[0] = 0x81;
            rlpNonce[1] = byte(uint8(nonce));
        } else if (nonce <= 0xFFFF) {
            rlpNonce = new bytes(3);
            rlpNonce[0] = 0x82;
            rlpNonce[1] = byte(uint8((nonce & 0xFF00) >> 8));
            rlpNonce[2] = byte(uint8(nonce));
        } else if (nonce <= 0xFFFFFF) {
            rlpNonce = new bytes(4);
            rlpNonce[0] = 0x83;
            rlpNonce[1] = byte(uint8((nonce & 0xFF0000) >> 16));
            rlpNonce[2] = byte(uint8((nonce & 0xFF00) >> 8));
            rlpNonce[3] = byte(uint8(nonce));
        } else {
            rlpNonce = new bytes(5);
            rlpNonce[0] = 0x84;
            rlpNonce[1] = byte(uint8((nonce & 0xFF000000) >> 24));
            rlpNonce[2] = byte(uint8((nonce & 0xFF0000) >> 16));
            rlpNonce[3] = byte(uint8((nonce & 0xFF00) >> 8));
            rlpNonce[4] = byte(uint8(nonce));
        }
    }

    /// @dev Compute the expected deployment address by `deployer` at
    ///      the nonce given by `deploymentNonce`.
    /// @param deployer The address of the deployer.
    /// @param deploymentNonce The nonce that the deployer had when deploying
    ///        a contract.
    /// @return deploymentAddress The deployment address.
    function getDeployedAddress(address deployer, uint32 deploymentNonce)
        internal
        pure
        returns (address payable deploymentAddress)
    {
        // The address of if a deployed contract is the lower 20 bytes of the
        // hash of the RLP-encoded deployer's account address + account nonce.
        // See: https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed
        bytes memory rlpNonce = rlpEncodeNonce(deploymentNonce);
        return address(uint160(uint256(keccak256(abi.encodePacked(
            byte(uint8(0xC0 + 21 + rlpNonce.length)),
            byte(uint8(0x80 + 20)),
            deployer,
            rlpNonce
        )))));
    }
}

/// @dev Storage helpers for the `TokenSpender` feature.
library LibTransformERC20Storage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // The current wallet instance.
        IFlashWallet wallet;
        // The transformer deployer address.
        address transformerDeployer;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.TransformERC20
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}


/// @dev Storage helpers for the `TokenSpender` feature.
library LibTokenSpenderStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // Allowance target contract.
        IAllowanceTarget allowanceTarget;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.TokenSpender
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

library LibERC20TokenV06 {
    bytes constant private DECIMALS_CALL_DATA = hex"313ce567";

    /// @dev Calls `IERC20TokenV06(token).approve()`.
    ///      Reverts if the result fails `isSuccessfulResult()` or the call reverts.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param allowance The allowance to set.
    function compatApprove(
        IERC20TokenV06 token,
        address spender,
        uint256 allowance
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            token.approve.selector,
            spender,
            allowance
        );
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Calls `IERC20TokenV06(token).approve()` and sets the allowance to the
    ///      maximum if the current approval is not already >= an amount.
    ///      Reverts if the result fails `isSuccessfulResult()` or the call reverts.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param amount The minimum allowance needed.
    function approveIfBelow(
        IERC20TokenV06 token,
        address spender,
        uint256 amount
    )
        internal
    {
        if (token.allowance(address(this), spender) < amount) {
            compatApprove(token, spender, uint256(-1));
        }
    }

    /// @dev Calls `IERC20TokenV06(token).transfer()`.
    ///      Reverts if the result fails `isSuccessfulResult()` or the call reverts.
    /// @param token The address of the token contract.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function compatTransfer(
        IERC20TokenV06 token,
        address to,
        uint256 amount
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            to,
            amount
        );
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Calls `IERC20TokenV06(token).transferFrom()`.
    ///      Reverts if the result fails `isSuccessfulResult()` or the call reverts.
    /// @param token The address of the token contract.
    /// @param from The owner of the tokens.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function compatTransferFrom(
        IERC20TokenV06 token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            token.transferFrom.selector,
            from,
            to,
            amount
        );
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Retrieves the number of decimals for a token.
    ///      Returns `18` if the call reverts.
    /// @param token The address of the token contract.
    /// @return tokenDecimals The number of decimals places for the token.
    function compatDecimals(IERC20TokenV06 token)
        internal
        view
        returns (uint8 tokenDecimals)
    {
        tokenDecimals = 18;
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(DECIMALS_CALL_DATA);
        if (didSucceed && resultData.length == 32) {
            tokenDecimals = uint8(LibBytesV06.readUint256(resultData, 0));
        }
    }

    /// @dev Retrieves the allowance for a token, owner, and spender.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @param spender The address the spender.
    /// @return allowance_ The allowance for a token, owner, and spender.
    function compatAllowance(IERC20TokenV06 token, address owner, address spender)
        internal
        view
        returns (uint256 allowance_)
    {
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(
            abi.encodeWithSelector(
                token.allowance.selector,
                owner,
                spender
            )
        );
        if (didSucceed && resultData.length == 32) {
            allowance_ = LibBytesV06.readUint256(resultData, 0);
        }
    }

    /// @dev Retrieves the balance for a token owner.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @return balance The token balance of an owner.
    function compatBalanceOf(IERC20TokenV06 token, address owner)
        internal
        view
        returns (uint256 balance)
    {
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(
            abi.encodeWithSelector(
                token.balanceOf.selector,
                owner
            )
        );
        if (didSucceed && resultData.length == 32) {
            balance = LibBytesV06.readUint256(resultData, 0);
        }
    }

    /// @dev Check if the data returned by a non-static call to an ERC20 token
    ///      is a successful result. Supported functions are `transfer()`,
    ///      `transferFrom()`, and `approve()`.
    /// @param resultData The raw data returned by a non-static call to the ERC20 token.
    /// @return isSuccessful Whether the result data indicates success.
    function isSuccessfulResult(bytes memory resultData)
        internal
        pure
        returns (bool isSuccessful)
    {
        if (resultData.length == 0) {
            return true;
        }
        if (resultData.length == 32) {
            uint256 result = LibBytesV06.readUint256(resultData, 0);
            if (result == 1) {
                return true;
            }
        }
    }

    /// @dev Executes a call on address `target` with calldata `callData`
    ///      and asserts that either nothing was returned or a single boolean
    ///      was returned equal to `true`.
    /// @param target The call target.
    /// @param callData The abi-encoded call data.
    function _callWithOptionalBooleanResult(
        address target,
        bytes memory callData
    )
        private
    {
        (bool didSucceed, bytes memory resultData) = target.call(callData);
        if (didSucceed && isSuccessfulResult(resultData)) {
            return;
        }
        LibRichErrorsV06.rrevert(resultData);
    }
}

library LibSafeMathRichErrorsV06 {

    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR =
        0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR =
        0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_BINOP_ERROR_SELECTOR,
            errorCode,
            a,
            b
        );
    }

    function Uint256DowncastError(
        DowncastErrorCodes errorCode,
        uint256 a
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_DOWNCAST_ERROR_SELECTOR,
            errorCode,
            a
        );
    }
}

library LibSafeMathV06 {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b == 0) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b > a) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                a,
                b
            ));
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(LibSafeMathRichErrorsV06.Uint256BinOpError(
                LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

/// @dev Storage helpers for the `SimpleFunctionRegistry` feature.
library LibSimpleFunctionRegistryStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // Mapping of function selector -> implementation history.
        mapping(bytes4 => address[]) implHistory;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.SimpleFunctionRegistry
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

/// @dev Basic registry management features.
contract SimpleFunctionRegistry is
    IFeature,
    ISimpleFunctionRegistry,
    FixinCommon
{
    // solhint-disable
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "SimpleFunctionRegistry";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);
    /// @dev The deployed address of this contract.
    address private immutable _implementation;
    // solhint-enable

    using LibRichErrorsV06 for bytes;

    constructor() public {
        _implementation = address(this);
    }

    /// @dev Initializes this feature, registering its own functions.
    /// @return success Magic bytes if successful.
    function bootstrap()
        external
        returns (bytes4 success)
    {
        // Register the registration functions (inception vibes).
        _extend(this.extend.selector, _implementation);
        _extend(this._extendSelf.selector, _implementation);
        // Register the rollback function.
        _extend(this.rollback.selector, _implementation);
        // Register getters.
        _extend(this.getRollbackLength.selector, _implementation);
        _extend(this.getRollbackEntryAtIndex.selector, _implementation);
        return LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @dev Roll back to a prior implementation of a function.
    ///      Only directly callable by an authority.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl)
        external
        override
        onlyOwner
    {
        (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        ) = _getStorages();

        address currentImpl = proxyStor.impls[selector];
        if (currentImpl == targetImpl) {
            // Do nothing if already at targetImpl.
            return;
        }
        // Walk history backwards until we find the target implementation.
        address[] storage history = stor.implHistory[selector];
        uint256 i = history.length;
        for (; i > 0; --i) {
            address impl = history[i - 1];
            history.pop();
            if (impl == targetImpl) {
                break;
            }
        }
        if (i == 0) {
            LibSimpleFunctionRegistryRichErrors.NotInRollbackHistoryError(
                selector,
                targetImpl
            ).rrevert();
        }
        proxyStor.impls[selector] = targetImpl;
        emit ProxyFunctionUpdated(selector, currentImpl, targetImpl);
    }

    /// @dev Register or replace a function.
    ///      Only directly callable by an authority.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl)
        external
        override
        onlyOwner
    {
        _extend(selector, impl);
    }

    /// @dev Register or replace a function.
    ///      Only callable from within.
    ///      This function is only used during the bootstrap process and
    ///      should be deregistered by the deployer after bootstrapping is
    ///      complete.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function _extendSelf(bytes4 selector, address impl)
        external
        onlySelf
    {
        _extend(selector, impl);
    }

    /// @dev Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector)
        external
        override
        view
        returns (uint256 rollbackLength)
    {
        return LibSimpleFunctionRegistryStorage.getStorage().implHistory[selector].length;
    }

    /// @dev Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx)
        external
        override
        view
        returns (address impl)
    {
        return LibSimpleFunctionRegistryStorage.getStorage().implHistory[selector][idx];
    }

    /// @dev Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function _extend(bytes4 selector, address impl)
        private
    {
        (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        ) = _getStorages();

        address oldImpl = proxyStor.impls[selector];
        address[] storage history = stor.implHistory[selector];
        history.push(oldImpl);
        proxyStor.impls[selector] = impl;
        emit ProxyFunctionUpdated(selector, oldImpl, impl);
    }

    /// @dev Get the storage buckets for this feature and the proxy.
    /// @return stor Storage bucket for this feature.
    /// @return proxyStor age bucket for the proxy.
    function _getStorages()
        private
        pure
        returns (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        )
    {
        return (
            LibSimpleFunctionRegistryStorage.getStorage(),
            LibProxyStorage.getStorage()
        );
    }
}

library LibMigrate {

    /// @dev Magic bytes returned by a migrator to indicate success.
    ///      This is `keccack('MIGRATE_SUCCESS')`.
    bytes4 internal constant MIGRATE_SUCCESS = 0x2c64c5ef;

    using LibRichErrorsV06 for bytes;

    /// @dev Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallMigrateFunction(
        address target,
        bytes memory data
    )
        internal
    {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success ||
            resultData.length != 32 ||
            abi.decode(resultData, (bytes4)) != MIGRATE_SUCCESS)
        {
            LibOwnableRichErrors.MigrateCallFailedError(target, resultData).rrevert();
        }
    }
}

/// @dev Storage helpers for the `Ownable` feature.
library LibOwnableStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // The owner of this contract.
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.Ownable
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

interface IOwnableV06 {

    /// @dev Emitted by Ownable when ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Transfers ownership of the contract to a new address.
    /// @param newOwner The address that will become the owner.
    function transferOwnership(address newOwner) external;

    /// @dev The owner of this contract.
    /// @return ownerAddress The owner address.
    function owner() external view returns (address ownerAddress);
}

// solhint-disable no-empty-blocks
/// @dev Owner management and migration features.
interface IOwnable is
    IOwnableV06
{
    /// @dev Emitted when `migrate()` is called.
    /// @param caller The caller of `migrate()`.
    /// @param migrator The migration contract.
    /// @param newOwner The address of the new owner.
    event Migrated(address caller, address migrator, address newOwner);

    /// @dev Execute a migration function in the context of the ZeroEx contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccack('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      The owner will be temporarily set to `address(this)` inside the call.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param newOwner The address of the new owner.
    /// @param data The call data.
    function migrate(address target, bytes calldata data, address newOwner) external;
}

/// @dev Owner management features.
contract Ownable is
    IFeature,
    IOwnable,
    FixinCommon
{

    // solhint-disable
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "Ownable";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);
    /// @dev The deployed address of this contract.
    address immutable private _implementation;
    // solhint-enable

    using LibRichErrorsV06 for bytes;

    constructor() public {
        _implementation = address(this);
    }

    /// @dev Initializes this feature. The intial owner will be set to this (ZeroEx)
    ///      to allow the bootstrappers to call `extend()`. Ownership should be
    ///      transferred to the real owner by the bootstrapper after
    ///      bootstrapping is complete.
    /// @return success Magic bytes if successful.
    function bootstrap() external returns (bytes4 success) {
        // Set the owner to ourselves to allow bootstrappers to call `extend()`.
        LibOwnableStorage.getStorage().owner = address(this);

        // Register feature functions.
        SimpleFunctionRegistry(address(this))._extendSelf(this.transferOwnership.selector, _implementation);
        SimpleFunctionRegistry(address(this))._extendSelf(this.owner.selector, _implementation);
        SimpleFunctionRegistry(address(this))._extendSelf(this.migrate.selector, _implementation);
        return LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @dev Change the owner of this contract.
    ///      Only directly callable by the owner.
    /// @param newOwner New owner address.
    function transferOwnership(address newOwner)
        external
        override
        onlyOwner
    {
        LibOwnableStorage.Storage storage proxyStor = LibOwnableStorage.getStorage();

        if (newOwner == address(0)) {
            LibOwnableRichErrors.TransferOwnerToZeroError().rrevert();
        } else {
            proxyStor.owner = newOwner;
            emit OwnershipTransferred(msg.sender, newOwner);
        }
    }

    /// @dev Execute a migration function in the context of the ZeroEx contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccack('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      Temporarily sets the owner to ourselves so we can perform admin functions.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param data The call data.
    /// @param newOwner The address of the new owner.
    function migrate(address target, bytes calldata data, address newOwner)
        external
        override
    {
        if (newOwner == address(0)) {
            LibOwnableRichErrors.TransferOwnerToZeroError().rrevert();
        }

        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        // The owner will be temporarily set to `address(this)` inside the call.
        stor.owner = address(this);

        // Perform the migration.
        LibMigrate.delegatecallMigrateFunction(target, data);

        // Update the owner.
        stor.owner = newOwner;

        emit Migrated(msg.sender, target, newOwner);
    }

    /// @dev Get the owner of this contract.
    /// @return owner_ The owner of this contract.
    function owner() external override view returns (address owner_) {
        return LibOwnableStorage.getStorage().owner;
    }
}

contract OwnableV06 is
    IOwnableV06
{
    /// @dev The owner of this contract.
    /// @return 0 The owner address.
    address public override owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _assertSenderIsOwner();
        _;
    }

    /// @dev Change the owner of this contract.
    /// @param newOwner New owner address.
    function transferOwnership(address newOwner)
        public
        override
        onlyOwner
    {
        if (newOwner == address(0)) {
            LibRichErrorsV06.rrevert(LibOwnableRichErrorsV06.TransferOwnerToZeroError());
        } else {
            owner = newOwner;
            emit OwnershipTransferred(msg.sender, newOwner);
        }
    }

    function _assertSenderIsOwner()
        internal
        view
    {
        if (msg.sender != owner) {
            LibRichErrorsV06.rrevert(LibOwnableRichErrorsV06.OnlyOwnerError(
                msg.sender,
                owner
            ));
        }
    }
}

interface IAuthorizableV06 is
    IOwnableV06
{
    // Event logged when a new address is authorized.
    event AuthorizedAddressAdded(
        address indexed target,
        address indexed caller
    );

    // Event logged when a currently authorized address is unauthorized.
    event AuthorizedAddressRemoved(
        address indexed target,
        address indexed caller
    );

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external;

    /// @dev Gets all authorized addresses.
    /// @return authorizedAddresses Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory authorizedAddresses);

    /// @dev Whether an adderss is authorized to call privileged functions.
    /// @param addr Address to query.
    /// @return isAuthorized Whether the address is authorized.
    function authorized(address addr) external view returns (bool isAuthorized);

    /// @dev All addresseses authorized to call privileged functions.
    /// @param idx Index of authorized address.
    /// @return addr Authorized address.
    function authorities(uint256 idx) external view returns (address addr);

}

// solhint-disable no-empty-blocks
contract AuthorizableV06 is
    OwnableV06,
    IAuthorizableV06
{
    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized {
        _assertSenderIsAuthorized();
        _;
    }

    // @dev Whether an address is authorized to call privileged functions.
    // @param 0 Address to query.
    // @return 0 Whether the address is authorized.
    mapping (address => bool) public override authorized;
    // @dev Whether an address is authorized to call privileged functions.
    // @param 0 Index of authorized address.
    // @return 0 Authorized address.
    address[] public override authorities;

    /// @dev Initializes the `owner` address.
    constructor()
        public
        OwnableV06()
    {}

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external
        override
        onlyOwner
    {
        _addAuthorizedAddress(target);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external
        override
        onlyOwner
    {
        if (!authorized[target]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.TargetNotAuthorizedError(target));
        }
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                _removeAuthorizedAddressAtIndex(target, i);
                break;
            }
        }
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external
        override
        onlyOwner
    {
        _removeAuthorizedAddressAtIndex(target, index);
    }

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        override
        view
        returns (address[] memory)
    {
        return authorities;
    }

    /// @dev Reverts if msg.sender is not authorized.
    function _assertSenderIsAuthorized()
        internal
        view
    {
        if (!authorized[msg.sender]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.SenderNotAuthorizedError(msg.sender));
        }
    }

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function _addAuthorizedAddress(address target)
        internal
    {
        // Ensure that the target is not the zero address.
        if (target == address(0)) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.ZeroCantBeAuthorizedError());
        }

        // Ensure that the target is not already authorized.
        if (authorized[target]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.TargetAlreadyAuthorizedError(target));
        }

        authorized[target] = true;
        authorities.push(target);
        emit AuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function _removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        internal
    {
        if (!authorized[target]) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.TargetNotAuthorizedError(target));
        }
        if (index >= authorities.length) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.IndexOutOfBoundsError(
                index,
                authorities.length
            ));
        }
        if (authorities[index] != target) {
            LibRichErrorsV06.rrevert(LibAuthorizableRichErrorsV06.AuthorizedAddressMismatchError(
                authorities[index],
                target
            ));
        }

        delete authorized[target];
        authorities[index] = authorities[authorities.length - 1];
        authorities.pop();
        emit AuthorizedAddressRemoved(target, msg.sender);
    }
}

/// @dev Deployer contract for ERC20 transformers.
///      Only authorities may call `deploy()` and `kill()`.
contract TransformerDeployer is
    AuthorizableV06
{
    /// @dev Emitted when a contract is deployed via `deploy()`.
    /// @param deployedAddress The address of the deployed contract.
    /// @param nonce The deployment nonce.
    /// @param sender The caller of `deploy()`.
    event Deployed(address deployedAddress, uint256 nonce, address sender);
    /// @dev Emitted when a contract is killed via `kill()`.
    /// @param target The address of the contract being killed..
    /// @param sender The caller of `kill()`.
    event Killed(address target, address sender);

    // @dev The current nonce of this contract.
    uint256 public nonce = 1;
    // @dev Mapping of deployed contract address to deployment nonce.
    mapping (address => uint256) public toDeploymentNonce;

    /// @dev Create this contract and register authorities.
    constructor(address[] memory authorities) public {
        for (uint256 i = 0; i < authorities.length; ++i) {
            _addAuthorizedAddress(authorities[i]);
        }
    }

    /// @dev Deploy a new contract. Only callable by an authority.
    ///      Any attached ETH will also be forwarded.
    function deploy(bytes memory bytecode)
        public
        payable
        onlyAuthorized
        returns (address deployedAddress)
    {
        uint256 deploymentNonce = nonce;
        nonce += 1;
        assembly {
            deployedAddress := create(callvalue(), add(bytecode, 32), mload(bytecode))
        }
        toDeploymentNonce[deployedAddress] = deploymentNonce;
        emit Deployed(deployedAddress, deploymentNonce, msg.sender);
    }

    /// @dev Call `die()` on a contract. Only callable by an authority.
    function kill(IKillable target)
        public
        onlyAuthorized
    {
        target.die();
        emit Killed(address(target), msg.sender);
    }
}

/// @dev A contract that can execute arbitrary calls from its owner.
interface IFlashWallet {

    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @param value Ether to attach to the call.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData,
        uint256 value
    )
        external
        payable
        returns (bytes memory resultData);

    /// @dev Execute an arbitrary delegatecall, in the context of this puppet.
    ///      Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeDelegateCall(
        address payable target,
        bytes calldata callData
    )
        external
        payable
        returns (bytes memory resultData);

    /// @dev Allows the puppet to receive ETH.
    receive() external payable;

    /// @dev Fetch the immutable owner/deployer of this contract.
    /// @return owner_ The immutable owner/deployer/
    function owner() external view returns (address owner_);
}

/// @dev A contract that can execute arbitrary calls from its owner.
contract FlashWallet is
    IFlashWallet
{
    // solhint-disable no-unused-vars,indent,no-empty-blocks
    using LibRichErrorsV06 for bytes;

    // solhint-disable
    /// @dev Store the owner/deployer as an immutable to make this contract stateless.
    address public override immutable owner;
    // solhint-enable

    constructor() public {
        // The deployer is the owner.
        owner = msg.sender;
    }

    /// @dev Allows only the (immutable) owner to call a function.
    modifier onlyOwner() virtual {
        if (msg.sender != owner) {
            LibOwnableRichErrorsV06.OnlyOwnerError(
                msg.sender,
                owner
            ).rrevert();
        }
        _;
    }

    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @param value Ether to attach to the call.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData,
        uint256 value
    )
        external
        payable
        override
        onlyOwner
        returns (bytes memory resultData)
    {
        bool success;
        (success, resultData) = target.call{value: value}(callData);
        if (!success) {
            LibWalletRichErrors
                .WalletExecuteCallFailedError(
                    address(this),
                    target,
                    callData,
                    value,
                    resultData
                )
                .rrevert();
        }
    }

    /// @dev Execute an arbitrary delegatecall, in the context of this puppet.
    ///      Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeDelegateCall(
        address payable target,
        bytes calldata callData
    )
        external
        payable
        override
        onlyOwner
        returns (bytes memory resultData)
    {
        bool success;
        (success, resultData) = target.delegatecall(callData);
        if (!success) {
            LibWalletRichErrors
                .WalletExecuteDelegateCallFailedError(
                    address(this),
                    target,
                    callData,
                    resultData
                )
                .rrevert();
        }
    }

    // solhint-disable
    /// @dev Allows this contract to receive ether.
    receive() external override payable {}
    // solhint-enable

    /// @dev Signal support for receiving ERC1155 tokens.
    /// @param interfaceID The interface ID, as per ERC-165 rules.
    /// @return hasSupport `true` if this contract supports an ERC-165 interface.
    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool hasSupport)
    {
        return  interfaceID == this.supportsInterface.selector ||
                interfaceID == this.onERC1155Received.selector ^ this.onERC1155BatchReceived.selector ||
                interfaceID == this.tokenFallback.selector;
    }

    ///  @dev Allow this contract to receive ERC1155 tokens.
    ///  @return success  `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    function onERC1155Received(
        address, // operator,
        address, // from,
        uint256, // id,
        uint256, // value,
        bytes calldata //data
    )
        external
        pure
        returns (bytes4 success)
    {
        return this.onERC1155Received.selector;
    }

    ///  @dev Allow this contract to receive ERC1155 tokens.
    ///  @return success  `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    function onERC1155BatchReceived(
        address, // operator,
        address, // from,
        uint256[] calldata, // ids,
        uint256[] calldata, // values,
        bytes calldata // data
    )
        external
        pure
        returns (bytes4 success)
    {
        return this.onERC1155BatchReceived.selector;
    }

    /// @dev Allows this contract to receive ERC223 tokens.
    function tokenFallback(
        address, // from,
        uint256, // value,
        bytes calldata // value
    )
        external
        pure
    {}
}

/// @dev The allowance target for the TokenSpender feature.
interface IAllowanceTarget is
    IAuthorizableV06
{
    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData
    )
        external
        returns (bytes memory resultData);
}

library LibOwnableRichErrorsV06 {

    // bytes4(keccak256("OnlyOwnerError(address,address)"))
    bytes4 internal constant ONLY_OWNER_ERROR_SELECTOR =
        0x1de45ad1;

    // bytes4(keccak256("TransferOwnerToZeroError()"))
    bytes internal constant TRANSFER_OWNER_TO_ZERO_ERROR_BYTES =
        hex"e69edc3e";

    // solhint-disable func-name-mixedcase
    function OnlyOwnerError(
        address sender,
        address owner
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_OWNER_ERROR_SELECTOR,
            sender,
            owner
        );
    }

    function TransferOwnerToZeroError()
        internal
        pure
        returns (bytes memory)
    {
        return TRANSFER_OWNER_TO_ZERO_ERROR_BYTES;
    }
}

library LibAuthorizableRichErrorsV06 {

    // bytes4(keccak256("AuthorizedAddressMismatchError(address,address)"))
    bytes4 internal constant AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR =
        0x140a84db;

    // bytes4(keccak256("IndexOutOfBoundsError(uint256,uint256)"))
    bytes4 internal constant INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR =
        0xe9f83771;

    // bytes4(keccak256("SenderNotAuthorizedError(address)"))
    bytes4 internal constant SENDER_NOT_AUTHORIZED_ERROR_SELECTOR =
        0xb65a25b9;

    // bytes4(keccak256("TargetAlreadyAuthorizedError(address)"))
    bytes4 internal constant TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR =
        0xde16f1a0;

    // bytes4(keccak256("TargetNotAuthorizedError(address)"))
    bytes4 internal constant TARGET_NOT_AUTHORIZED_ERROR_SELECTOR =
        0xeb5108a2;

    // bytes4(keccak256("ZeroCantBeAuthorizedError()"))
    bytes internal constant ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES =
        hex"57654fe4";

    // solhint-disable func-name-mixedcase
    function AuthorizedAddressMismatchError(
        address authorized,
        address target
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR,
            authorized,
            target
        );
    }

    function IndexOutOfBoundsError(
        uint256 index,
        uint256 length
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR,
            index,
            length
        );
    }

    function SenderNotAuthorizedError(address sender)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            SENDER_NOT_AUTHORIZED_ERROR_SELECTOR,
            sender
        );
    }

    function TargetAlreadyAuthorizedError(address target)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR,
            target
        );
    }

    function TargetNotAuthorizedError(address target)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TARGET_NOT_AUTHORIZED_ERROR_SELECTOR,
            target
        );
    }

    function ZeroCantBeAuthorizedError()
        internal
        pure
        returns (bytes memory)
    {
        return ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES;
    }
}

/// @dev The allowance target for the TokenSpender feature.
contract AllowanceTarget is
    IAllowanceTarget,
    AuthorizableV06
{
    // solhint-disable no-unused-vars,indent,no-empty-blocks
    using LibRichErrorsV06 for bytes;

    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData
    )
        external
        override
        onlyAuthorized
        returns (bytes memory resultData)
    {
        bool success;
        (success, resultData) = target.call(callData);
        if (!success) {
            resultData.rrevert();
        }
    }
}

library LibWalletRichErrors {

    // solhint-disable func-name-mixedcase

    function WalletExecuteCallFailedError(
        address wallet,
        address callTarget,
        bytes memory callData,
        uint256 callValue,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("WalletExecuteCallFailedError(address,address,bytes,uint256,bytes)")),
            wallet,
            callTarget,
            callData,
            callValue,
            errorData
        );
    }

    function WalletExecuteDelegateCallFailedError(
        address wallet,
        address callTarget,
        bytes memory callData,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("WalletExecuteDelegateCallFailedError(address,address,bytes,bytes)")),
            wallet,
            callTarget,
            callData,
            errorData
        );
    }
}

library LibTransformERC20RichErrors {

    // solhint-disable func-name-mixedcase,separate-by-one-line-in-contract

    function InsufficientEthAttachedError(
        uint256 ethAttached,
        uint256 ethNeeded
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InsufficientEthAttachedError(uint256,uint256)")),
            ethAttached,
            ethNeeded
        );
    }

    function IncompleteTransformERC20Error(
        address outputToken,
        uint256 outputTokenAmount,
        uint256 minOutputTokenAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IncompleteTransformERC20Error(address,uint256,uint256)")),
            outputToken,
            outputTokenAmount,
            minOutputTokenAmount
        );
    }

    function NegativeTransformERC20OutputError(
        address outputToken,
        uint256 outputTokenLostAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NegativeTransformERC20OutputError(address,uint256)")),
            outputToken,
            outputTokenLostAmount
        );
    }

    function TransformerFailedError(
        address transformer,
        bytes memory transformerData,
        bytes memory resultData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("TransformerFailedError(address,bytes,bytes)")),
            transformer,
            transformerData,
            resultData
        );
    }

    // Common Transformer errors ///////////////////////////////////////////////

    function OnlyCallableByDeployerError(
        address caller,
        address deployer
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyCallableByDeployerError(address,address)")),
            caller,
            deployer
        );
    }

    function InvalidExecutionContextError(
        address actualContext,
        address expectedContext
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidExecutionContextError(address,address)")),
            actualContext,
            expectedContext
        );
    }

    enum InvalidTransformDataErrorCode {
        INVALID_TOKENS,
        INVALID_ARRAY_LENGTH
    }

    function InvalidTransformDataError(
        InvalidTransformDataErrorCode errorCode,
        bytes memory transformData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidTransformDataError(uint8,bytes)")),
            errorCode,
            transformData
        );
    }

    // FillQuoteTransformer errors /////////////////////////////////////////////

    function IncompleteFillSellQuoteError(
        address sellToken,
        uint256 soldAmount,
        uint256 sellAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IncompleteFillSellQuoteError(address,uint256,uint256)")),
            sellToken,
            soldAmount,
            sellAmount
        );
    }

    function IncompleteFillBuyQuoteError(
        address buyToken,
        uint256 boughtAmount,
        uint256 buyAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IncompleteFillBuyQuoteError(address,uint256,uint256)")),
            buyToken,
            boughtAmount,
            buyAmount
        );
    }

    function InsufficientTakerTokenError(
        uint256 tokenBalance,
        uint256 tokensNeeded
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InsufficientTakerTokenError(uint256,uint256)")),
            tokenBalance,
            tokensNeeded
        );
    }

    function InsufficientProtocolFeeError(
        uint256 ethBalance,
        uint256 ethNeeded
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InsufficientProtocolFeeError(uint256,uint256)")),
            ethBalance,
            ethNeeded
        );
    }

    function InvalidERC20AssetDataError(
        bytes memory assetData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidERC20AssetDataError(bytes)")),
            assetData
        );
    }

    function InvalidTakerFeeTokenError(
        address token
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidTakerFeeTokenError(address)")),
            token
        );
    }
}

library LibSpenderRichErrors {

    // solhint-disable func-name-mixedcase

    function SpenderERC20TransferFromFailedError(
        address token,
        address owner,
        address to,
        uint256 amount,
        bytes memory errorData
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("SpenderERC20TransferFromFailedError(address,address,address,uint256,bytes)")),
            token,
            owner,
            to,
            amount,
            errorData
        );
    }
}

library LibSimpleFunctionRegistryRichErrors {

    // solhint-disable func-name-mixedcase

    function NotInRollbackHistoryError(bytes4 selector, address targetImpl)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NotInRollbackHistoryError(bytes4,address)")),
            selector,
            targetImpl
        );
    }
}

library LibOwnableRichErrors {

    // solhint-disable func-name-mixedcase

    function OnlyOwnerError(
        address sender,
        address owner
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyOwnerError(address,address)")),
            sender,
            owner
        );
    }

    function TransferOwnerToZeroError()
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("TransferOwnerToZeroError()"))
        );
    }

    function MigrateCallFailedError(address target, bytes memory resultData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MigrateCallFailedError(address,bytes)")),
            target,
            resultData
        );
    }
}

library LibCommonRichErrors {

    // solhint-disable func-name-mixedcase

    function OnlyCallableBySelfError(address sender)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyCallableBySelfError(address)")),
            sender
        );
    }

    function IllegalReentrancyError()
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IllegalReentrancyError()"))
        );
    }
}

/// @dev Detachable `bootstrap()` feature.
interface IBootstrap {

    /// @dev Bootstrap the initial feature set of this contract by delegatecalling
    ///      into `target`. Before exiting the `bootstrap()` function will
    ///      deregister itself from the proxy to prevent being called again.
    /// @param target The bootstrapper contract address.
    /// @param callData The call data to execute on `target`.
    function bootstrap(address target, bytes calldata callData) external;
}

/// @dev Common storage helpers
library LibStorage {

    /// @dev What to bit-shift a storage ID by to get its slot.
    ///      This gives us a maximum of 2**128 inline fields in each bucket.
    uint256 private constant STORAGE_SLOT_EXP = 128;

    /// @dev Storage IDs for feature storage buckets.
    ///      WARNING: APPEND-ONLY.
    enum StorageId {
        Proxy,
        SimpleFunctionRegistry,
        Ownable,
        TokenSpender,
        TransformERC20
    }

    /// @dev Get the storage slot given a storage ID. We assign unique, well-spaced
    ///     slots to storage bucket variables to ensure they do not overlap.
    ///     See: https://solidity.readthedocs.io/en/v0.6.6/assembly.html#access-to-external-variables-functions-and-libraries
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function getStorageSlot(StorageId storageId)
        internal
        pure
        returns (uint256 slot)
    {
        // This should never overflow with a reasonable `STORAGE_SLOT_EXP`
        // because Solidity will do a range check on `storageId` during the cast.
        return (uint256(storageId) + 1) << STORAGE_SLOT_EXP;
    }
}

/// @dev Storage helpers for the proxy contract.
library LibProxyStorage {

    /// @dev Storage bucket for proxy contract.
    struct Storage {
        // Mapping of function selector -> function implementation
        mapping(bytes4 => address) impls;
        // The owner of the proxy contract.
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.Proxy
        );
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := storageSlot }
    }
}

/// @dev Detachable `bootstrap()` feature.
contract Bootstrap is IBootstrap {
    // solhint-disable state-visibility,indent
    /// @dev The ZeroEx contract.
    ///      This has to be immutable to persist across delegatecalls.
    address immutable private _deployer;
    /// @dev The implementation address of this contract.
    ///      This has to be immutable to persist across delegatecalls.
    address immutable private _implementation;
    /// @dev The deployer.
    ///      This has to be immutable to persist across delegatecalls.
    address immutable private _bootstrapCaller;
    // solhint-enable state-visibility,indent

    using LibRichErrorsV06 for bytes;

    /// @dev Construct this contract and set the bootstrap migration contract.
    ///      After constructing this contract, `bootstrap()` should be called
    ///      to seed the initial feature set.
    /// @param bootstrapCaller The allowed caller of `bootstrap()`.
    constructor(address bootstrapCaller) public {
        _deployer = msg.sender;
        _implementation = address(this);
        _bootstrapCaller = bootstrapCaller;
    }

    /// @dev Bootstrap the initial feature set of this contract by delegatecalling
    ///      into `target`. Before exiting the `bootstrap()` function will
    ///      deregister itself from the proxy to prevent being called again.
    /// @param target The bootstrapper contract address.
    /// @param callData The call data to execute on `target`.
    function bootstrap(address target, bytes calldata callData) external override {
        // Only the bootstrap caller can call this function.
        if (msg.sender != _bootstrapCaller) {
            LibProxyRichErrors.InvalidBootstrapCallerError(
                msg.sender,
                _bootstrapCaller
            ).rrevert();
        }
        // Deregister.
        LibProxyStorage.getStorage().impls[this.bootstrap.selector] = address(0);
        // Self-destruct.
        Bootstrap(_implementation).die();
        // Call the bootstrapper.
        LibBootstrap.delegatecallBootstrapFunction(target, callData);
    }

    /// @dev Self-destructs this contract.
    ///      Can only be called by the deployer.
    function die() external {
        if (msg.sender != _deployer) {
            LibProxyRichErrors.InvalidDieCallerError(msg.sender, _deployer).rrevert();
        }
        selfdestruct(msg.sender);
    }
}

library LibProxyRichErrors {

    // solhint-disable func-name-mixedcase

    function NotImplementedError(bytes4 selector)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NotImplementedError(bytes4)")),
            selector
        );
    }

    function InvalidBootstrapCallerError(address actual, address expected)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidBootstrapCallerError(address,address)")),
            actual,
            expected
        );
    }

    function InvalidDieCallerError(address actual, address expected)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidDieCallerError(address,address)")),
            actual,
            expected
        );
    }

    function BootstrapCallFailedError(address target, bytes memory resultData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("BootstrapCallFailedError(address,bytes)")),
            target,
            resultData
        );
    }
}

library LibBootstrap {

    /// @dev Magic bytes returned by the bootstrapper to indicate success.
    ///      This is `keccack('BOOTSTRAP_SUCCESS')`.
    bytes4 internal constant BOOTSTRAP_SUCCESS = 0xd150751b;

    using LibRichErrorsV06 for bytes;

    /// @dev Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallBootstrapFunction(
        address target,
        bytes memory data
    )
        internal
    {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success ||
            resultData.length != 32 ||
            abi.decode(resultData, (bytes4)) != BOOTSTRAP_SUCCESS)
        {
            LibProxyRichErrors.BootstrapCallFailedError(target, resultData).rrevert();
        }
    }
}

library LibRichErrorsV06 {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

library LibBytesRichErrorsV06 {

    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }

    // bytes4(keccak256("InvalidByteOperationError(uint8,uint256,uint256)"))
    bytes4 internal constant INVALID_BYTE_OPERATION_ERROR_SELECTOR =
        0x28006595;

    // solhint-disable func-name-mixedcase
    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_BYTE_OPERATION_ERROR_SELECTOR,
            errorCode,
            offset,
            required
        );
    }
}

library LibBytesV06 {

    using LibBytesV06 for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    )
        internal
        pure
    {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} lt(source, sEnd) {} {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} slt(dest, dEnd) {} {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length
        );
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    ///      When `from == 0`, the original array will match the slice.
    ///      In other cases its state will be corrupted.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The byte that was popped off.
    function popLastByte(bytes memory b)
        internal
        pure
        returns (bytes1 result)
    {
        if (b.length == 0) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanZeroRequired,
                b.length,
                0
            ));
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return equal True if arrays are the same. False otherwise.
    function equals(
        bytes memory lhs,
        bytes memory rhs
    )
        internal
        pure
        returns (bool equal)
    {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        if (b.length < index + 20) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

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

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    )
        internal
        pure
    {
        if (b.length < index + 20) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return result bytes32 value from byte array.
    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        if (b.length < index + 32) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    )
        internal
        pure
    {
        if (b.length < index + 32) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    )
        internal
        pure
    {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        if (b.length < index + 4) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsFourRequired,
                b.length,
                index + 4
            ));
        }

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

    /// @dev Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    function writeLength(bytes memory b, uint256 length)
        internal
        pure
    {
        assembly {
            mstore(b, length)
        }
    }
}

/// @dev An extensible proxy contract that serves as a universal entry point for
///      interacting with the 0x protocol.
contract ZeroEx {
    // solhint-disable separate-by-one-line-in-contract,indent,var-name-mixedcase
    using LibBytesV06 for bytes;

    /// @dev Construct this contract and register the `Bootstrap` feature.
    ///      After constructing this contract, `bootstrap()` should be called
    ///      to seed the initial feature set.
    constructor() public {
        // Temporarily create and register the bootstrap feature.
        // It will deregister itself after `bootstrap()` has been called.
        Bootstrap bootstrap = new Bootstrap(msg.sender);
        LibProxyStorage.getStorage().impls[bootstrap.bootstrap.selector] =
            address(bootstrap);
    }

    // solhint-disable state-visibility

    /// @dev Forwards calls to the appropriate implementation contract.
    fallback() external payable {
        bytes4 selector = msg.data.readBytes4(0);
        address impl = getFunctionImplementation(selector);
        if (impl == address(0)) {
            _revertWithData(LibProxyRichErrors.NotImplementedError(selector));
        }

        (bool success, bytes memory resultData) = impl.delegatecall(msg.data);
        if (!success) {
            _revertWithData(resultData);
        }
        _returnWithData(resultData);
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    // solhint-enable state-visibility

    /// @dev Get the implementation contract of a registered function.
    /// @param selector The function selector.
    /// @return impl The implementation contract address.
    function getFunctionImplementation(bytes4 selector)
        public
        view
        returns (address impl)
    {
        return LibProxyStorage.getStorage().impls[selector];
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    function _revertWithData(bytes memory data) private pure {
        assembly { revert(add(data, 32), mload(data)) }
    }

    /// @dev Return with arbitrary bytes.
    /// @param data Return data.
    function _returnWithData(bytes memory data) private pure {
        assembly { return(add(data, 32), mload(data)) }
    }
}