// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./base/ModuleManager.sol";
import "./base/OwnerManager.sol";
import "./base/FallbackManager.sol";
import "./base/GuardManager.sol";
import "./common/EtherPaymentFallback.sol";
import "./common/Singleton.sol";
import "./common/SignatureDecoder.sol";
import "./common/SecuredTokenTransfer.sol";
import "./common/StorageAccessible.sol";
import "./interfaces/ISignatureValidator.sol";
import "./external/GnosisSafeMath.sol";

/// @title Gnosis Safe - A multisignature wallet with support for confirmations using signed messages based on ERC191.
contract GnosisSafe is
    EtherPaymentFallback,
    Singleton,
    ModuleManager,
    OwnerManager,
    SignatureDecoder,
    SecuredTokenTransfer,
    ISignatureValidatorConstants,
    FallbackManager,
    StorageAccessible,
    GuardManager
{
    using GnosisSafeMath for uint256;

    string public constant VERSION = "1.3.0";

    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    event SafeSetup(address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event SignMsg(bytes32 indexed msgHash);
    event ExecutionFailure(bytes32 txHash, uint256 payment);
    event ExecutionSuccess(bytes32 txHash, uint256 payment);

    uint256 public nonce;
    bytes32 private _deprecatedDomainSeparator;
    // 映射以跟踪所有必需所有者已批准的所有消息哈希
    mapping(bytes32 => uint256) public signedMessages;
    // 映射以跟踪已被任何所有者批准的所有哈希（消息或交易）
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;
    
    // 此构造函数确保此合约只能用作代理合约的主副本
    constructor() {
        // 通过设置阈值，就不能再调用 setup， 
        // 所以我们创建了一个拥有 0 个所有者和阈值 1 的保险箱。 
        // 这是一个无法使用的保险箱，非常适合单例
        threshold = 1;
    }
    
    /// @dev 设置函数设置合约的初始存储。 
    /// @param _owners 安全所有者列表。 
    /// @param _threshold 安全交易所需的确认次数。 
    /// @param to 于可选委托调用的合约地址。 
    /// @param data 可选委托调用的数据负载。 
    /// @param fallbackHandler 该合约的回退调用处理程序 
    /// @param paymentToken 应该用于支付的令牌（0 是 ETH） 
    /// @param payment 应该支付的值 
    /// @param paymentReceiver 地址应该收到付款（如果 tx.origin 则为 0）
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        // setupOwners 检查是否已经设置了阈值，因此防止此方法被调用两次
        setupOwners(_owners, _threshold);
        if (fallbackHandler != address(0)) internalSetFallbackHandler(fallbackHandler);
        // 因为 setupOwners 只能在合约没有被初始化的情况下被调用，所以我们不需要检查 setupModules
        setupModules(to, data);

        if (payment > 0) {
            // 为了避免遇到 EIP-170 的问题，我们重用了 handlePayment 函数（为了避免调整已验证的代码，我们不会调整方法本身） 
            // baseGas = 0, gasPrice = 1 and gas = payment => amount = (付款 + 0) * 1 = 付款
            handlePayment(payment, 0, 1, paymentToken, paymentReceiver);
        }
        emit SafeSetup(msg.sender, _owners, _threshold, to, fallbackHandler);
    }

    /// @dev 允许执行由所需数量的所有者确认的安全交易，然后支付提交交易的帐户。 
    /// 注意：即使用户交易失败，费用也会一直转移。 
    /// @param to 安全事务的目标地址。 
    /// @param value 安全交易的以太币值。 
    /// @param data 安全事务的数据负载。 
    /// @param operation 安全事务的操作类型。 
    /// @param safeTxGas 应该用于安全交易的气体。 
    /// @param baseGas 独立于交易执行的 Gas 成本（例如基本交易费、签名检查、退款支付） 
    /// @param gasPrice 应该用于支付计算的 Gas 价格。 
    /// @param gasToken 用于支付的代币地址（如果是 ETH，则为 0）。 
    /// @param refundReceiver gas 支付接收方地址（如果 tx.origin 则为 0）。 
    /// @param signatures 打包的签名数据 ({bytes32 r}{bytes32 s}{uint8 v})
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 txHash;
        // 这里使用作用域来限制变量的生命周期并防止 `stack too deep` 错误
        {
            bytes memory txHashData =
                encodeTransactionData(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    nonce
                );
            // Increase nonce and execute transaction.
            nonce++;
            txHash = keccak256(txHashData);
            checkSignatures(txHash, txHashData, signatures);
        }
        address guard = getGuard();
        {
            if (guard != address(0)) {
                Guard(guard).checkTransaction(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    signatures,
                    msg.sender
                );
            }
        }
        // 我们需要一些 gas 来在执行后发出事件（至少 2500）和一些在执行之前执行代码（500） 
        // 我们还在检查中包含 1/64，它不会与调用一起发送抵消 EIP-150 导致的潜在短路
        require(gasleft() >= ((safeTxGas * 64) / 63).max(safeTxGas + 2500) + 500, "GS010");
        // 这里使用作用域来限制变量的生命周期并防止 `stack too deep` 错误
        {
            uint256 gasUsed = gasleft();
           // 如果 gasPrice 为 0，我们假设几乎所有可用的 gas 都可以使用（它总是比 safeTxGas 多） 
           // 我们只减去 2500（与之前的 3000 相比）以确保传递的数量仍然高于 safeTxGas
           success = execute(to, value, data, operation, gasPrice == 0 ? (gasleft() - 2500) : safeTxGas);
            gasUsed = gasUsed.sub(gasleft());
            // 如果没有设置 safeTxGas 和 gasPrice（例如，两者都是 0），则需要内部 tx 成功 
            // 这使得可以毫无问题地使用 `estimateGas`，因为它会搜索 tx 所在的最小 gas不恢复
            require(success || safeTxGas != 0 || gasPrice != 0, "GS013");
            // 我们将计算的 tx 成本转移到 tx.origin 以避免将其发送到已调用的中间合约
            uint256 payment = 0;
            if (gasPrice > 0) {
                payment = handlePayment(gasUsed, baseGas, gasPrice, gasToken, refundReceiver);
            }
            if (success) emit ExecutionSuccess(txHash, payment);
            else emit ExecutionFailure(txHash, payment);
        }
        {
            if (guard != address(0)) {
                Guard(guard).checkAfterExecution(txHash, success);
            }
        }
    }

    function handlePayment(
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    ) private returns (uint256 payment) {
        // solhint-disable-next-line avoid-tx-origin
        address payable receiver = refundReceiver == address(0) ? payable(tx.origin) : refundReceiver;
        if (gasToken == address(0)) {
            // 对于 ETH，我们只会将 gas 价格调整为不高于实际使用的 gas 价格
            payment = gasUsed.add(baseGas).mul(gasPrice < tx.gasprice ? gasPrice : tx.gasprice);
            require(receiver.send(payment), "GS011");
        } else {
            payment = gasUsed.add(baseGas).mul(gasPrice);
            require(transferToken(gasToken, receiver, payment), "GS012");
        }
    }

    /**
    * @dev 检查提供的签名是否对提供的数据有效，哈希。否则将恢复。 
    * @param dataHash 数据的哈希（可以是消息哈希或交易哈希） 
    * @param data 应该被签名的数据（这被传递给外部验证者合约） 
    * @param signatures 应该被验证的签名数据。可以是 ECDSA 签名、合约签名 (EIP-1271) 或已批准的哈希。
    */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view {
        // 负载阈值以避免多个存储负载
        uint256 _threshold = threshold;
        // 检查是否设置了阈值
        require(_threshold > 0, "GS001");
        checkNSignatures(dataHash, data, signatures, _threshold);
    }

    /**
    * @dev 检查提供的签名是否对提供的数据有效，哈希。否则将恢复。 
    * @param dataHash 数据的哈希（可以是消息哈希或交易哈希） 
    * @param data 应该被签名的数据（这被传递给外部验证者合约） 
    * @param signatures 应该被验证的签名数据。可以是 ECDSA 签名、合约签名 (EIP-1271) 或已批准的哈希。 
    * @param requiredSignatures 所需有效签名的数量。
    */
    function checkNSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        // 检查提供的签名数据是否太短
        require(signatures.length >= requiredSignatures.mul(65), "GS020");
        // 不能有地址为 0 的所有者。
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                // 如果 v 为 0， 那么它是一个合约签名 
                // 当处理合约签名时， 合约的地址被编码为 r
                currentOwner = address(uint160(uint256(r)));

               // 检查签名数据指针 (s) 是否未指向签名字节的静态部分内。 
               // 此检查并不完全准确，因为发送的签名可能超过阈值。
               // 这里我们只检查指针没有指向正在处理的部分内部。
               require(uint256(s) >= requiredSignatures.mul(65), "GS021");

                // 检查签名数据指针 (s) 是否在界限内（指向数据长度 -> 32 字节）
                require(uint256(s).add(32) <= signatures.length, "GS022");

                // 检查合约签名是否在界限内：数据的开始是 s + 32，结束是开始 + 签名长度
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s).add(32).add(contractSignatureLen) <= signatures.length, "GS023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // 合约签名的签名数据附加到级联签名中，偏移量存储在 s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
            } else if (v == 1) {
                // 如果 v 为 1，那么它是一个已批准的哈希 
                // 当处理已批准的哈希时，批准者的地址被编码为 r
                currentOwner = address(uint160(uint256(r)));
                // 哈希由消息的发送者自动批准， 或者当它们通过单独的交易被预先批准时
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
            } else if (v > 30) {
                // 如果 v > 30， 则默认 va (27,28) 已针对 eth_sign 流进行了调整 
                // 为了支持 eth_sign 和类似内容， 我们调整 v 并在应用 ecrecover 之前使用以太坊消息前缀对 messageHash 进行散列
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // 默认是带有提供数据哈希的 ecrecover 流 
                // 使用带有 messageHash 的 ecrecover 进行 EOA 签名
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            require(currentOwner > lastOwner && owners[currentOwner] != address(0) && currentOwner != SENTINEL_OWNERS, "GS026");
            lastOwner = currentOwner;
        }
    }

   /// @dev 允许估计一个安全事务。 
   /// 此方法仅用于估计目的，因此调用将始终还原并将结果编码到还原数据中。 
   /// 由于 `estimateGas` 函数包含退款，调用此方法可通过 `execTransaction` 获取从保险箱中扣除的估计费用 
   /// @param to Safe 交易的目标地址。 
   /// @param value 安全交易的以太币值。 
   /// @param data 安全事务的数据负载。 
   /// @param operation 安全事务的操作类型。 
   /// @return 估计没有退款和间接费用（基本交易和有效载荷数据气体成本）。 
   /// @notice 已弃用，取而代之的是 common/StorageAccessible.sol，并将在下一个版本中删除。
   function requiredTxGas(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (uint256) {
        uint256 startGas = gasleft();
        // 我们在这里不提供错误消息，因为我们使用它来返回估计值
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        // 将响应转换为字符串并通过错误消息返回
        revert(string(abi.encodePacked(requiredGas)));
    }

    /**
    * @dev 将哈希标记为已批准。这可用于验证签名使用的散列。 
    * @param hashToApprove 应标记为已批准的哈希值，以用于由本合约验证的签名。
    */
    function approveHash(bytes32 hashToApprove) external {
        require(owners[msg.sender] != address(0), "GS030");
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }
    
    /// @dev 返回此合约使用的链 ID。
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
    }

    /// @dev 返回经过哈希处理以由所有者签名的字节。 
    /// @param 到目标地址。 
    /// @param value 以太币值。 
    /// @param data 数据负载。 
    /// @param operation 操作类型。 
    /// @param safeTxGas 应该用于安全交易的气体。 
    /// @param baseGas Gas 成本与交易执行无关（例如，基本交易费用、签名检查、退款支付） 
    /// @param gasPrice 该交易应使用的最大gas价格。 
    /// @param gasToken 用于支付的代币地址（如果是 ETH，则为 0）。 
    /// @param refundReceiver gas 支付接收方地址（如果 tx.origin 则为 0）。 
    /// @param _nonce 事务随机数。 
    /// @return 事务哈希字节。
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    SAFE_TX_TYPEHASH,
                    to,
                    value,
                    keccak256(data),
                    operation,
                    safeTxGas,
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    _nonce
                )
            );
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeTxHash);
    }
    
    /// @dev 返回要由所有者签名的哈希。 
    /// @param to 目标地址。 
    /// @param value 以太币值。 
    /// @param data 数据负载。 
    /// @param operation 操作类型。 
    /// @param safeTxGas Fas 应该用于安全交易。 
    /// @param baseGas 用于触发安全交易的数据的 Gas 成本。 
    /// @param gasPrice 该交易应该使用的最大gas价格。 
    /// @param gasToken 用于支付的代币地址（如果是 ETH，则为 0）。 
    /// @param refundReceiver gas 支付接收方地址（如果 tx.origin 则为 0）。 
    /// @param _nonce 事务随机数。 
    /// @return 交易哈希。
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";

/// @title Executor - 可以执行交易的合约
contract Executor {
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/SelfAuthorized.sol";

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
contract FallbackManager is SelfAuthorized {
    event ChangedFallbackHandler(address handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    function internalSetFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded.
    ///      This can only be done via a Safe transaction.
    /// @param handler contract to handle fallback calls.
    function setFallbackHandler(address handler) public authorized {
        internalSetFallbackHandler(handler);
        emit ChangedFallbackHandler(handler);
    }

    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "../interfaces/IERC165.sol";

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

/// @title Fallback Manager - 管理对此合约的后备调用的合约
contract GuardManager is SelfAuthorized {
    event ChangedGuard(address guard);
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external authorized {
        if (guard != address(0)) {
            require(Guard(guard).supportsInterface(type(Guard).interfaceId), "GS300");
        }
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";

/// @title Module Manager - 管理可以通过此合约执行交易的模块的合约 
contract ModuleManager is SelfAuthorized, Executor {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping(address => address) internal modules;

    function setupModules(address to, bytes memory data) internal {
        require(modules[SENTINEL_MODULES] == address(0), "GS100");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0))
            // 设置必须成功完成或交易失败
            require(execute(to, 0, data, Enum.Operation.DelegateCall, gasleft()), "GS000");
    }

    /// @dev 允许将模块添加到白名单。 
    ///  这只能通过安全事务来完成。 
    /// @notice 为保险箱启用模块 `module`。 
    /// @param module 要列入白名单的模块。
    function enableModule(address module) public authorized {
        // 模块地址不能为空或哨兵。
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        // 模块不能添加两次。
        require(modules[module] == address(0), "GS102");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }
    
    /// @dev 允许从白名单中删除模块。 这只能通过安全事务来完成。 
    /// @notice 为保险箱禁用模块 `module`。 
    /// @param prevModule 指向链表中要移除的模块的模块 
    /// @param module 要移除的模块。
    function disableModule(address prevModule, address module) public authorized {
        // 验证模块地址并检查它是否对应于模块索引
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        require(modules[prevModule] == module, "GS103");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }
    
    /// @dev 允许模块在没有任何进一步确认的情况下执行安全事务。 
    /// @param to 模块事务的目标地址。 
    /// @param value 模块交易的以太币值。 
    /// @param data 模块事务的数据负载。 
    /// @param operation 模块事务的操作类型。
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool success) {
        // 只允许列入白名单的模块
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "GS104");
        // 无需进一步确认即可执行交易。
        success = execute(to, value, data, operation, gasleft());
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /// @dev 允许模块在没有任何进一步确认的情况下执行安全事务并返回数据 
    /// @param to 模块事务的目标地址。 
    /// @param value 模块交易的以太币值。 
    /// @param data 模块事务的数据负载。 
    /// @param operation 模块事务的操作类型。
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // 加载空闲内存位置
            let ptr := mload(0x40)
            // 我们通过将空闲内存位置设置为 
            // 当前空闲内存位置 + 数据大小 + 32 字节作为数据大小值来为返回数据分配内存
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // 将返回数据指向正确的内存位置
            returnData := ptr
        }
    }
    
    /// @dev 如果启用了模块，则返回 
    /// @return 如果启用了模块，则返回 True
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }

    /// @dev 返回模块数组。 
    /// @param start 页面的开始。 
    /// @param pageSize 应该返回的最大模块数。 
    /// @return array 模块数组。 
    /// @return next 下一页的开始。
    function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array, address next) {
        // 具有最大页面大小的初始化数组
        array = new address[](pageSize);

        // 填充返回数组
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while (currentModule != address(0x0) && currentModule != SENTINEL_MODULES && moduleCount < pageSize) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // 设置返回数组的正确大小 
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/SelfAuthorized.sol";

/// @title OwnerManager - 管理一组所有者和执行操作的阈值。
/// @author Stefan George - <[email protected]>
contract OwnerManager is SelfAuthorized {
    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    function setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "GS200");
        // Validate that threshold is smaller than number of added owners.
        require(_threshold <= _owners.length, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this) && currentOwner != owner, "GS203");
            // No duplicate owners allowed.
            require(owners[owner] == address(0), "GS204");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }
    
    /// @dev 允许将新所有者添加到保险箱并同时更新阈值。 这只能通过安全事务来完成。
    /// @notice 将所有者 `owner` 添加到 Safe 并将阈值更新为 `_threshold`。
    /// @param owner 新的所有者地址。
    /// @param _threshold 新阈值
    function addOwnerWithThreshold(address owner, uint256 _threshold) public authorized {
        // 所有者地址不能为空，哨兵或保险箱本身。
        require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this), "GS203");
        // 不允许重复所有者。
        require(owners[owner] == address(0), "GS204");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        // 如果阈值改变，则改变阈值。
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    
    /// @dev 允许从保险箱中删除所有者并同时更新阈值。 这只能通过安全事务来完成。 
    /// @notice 从 Safe 中删除所有者 `owner` 并将阈值更新为 `_threshold`。 
    /// @param prevOwner Owner 指向链表中要移除的所有者 
    /// @param owner 要移除的所有者地址。 
    /// @param _threshold 新阈值。
    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) public authorized {
        // 如果仍然可以达到阈值，则只允许删除所有者。
        require(ownerCount - 1 >= _threshold, "GS201");
        // 验证所有者地址并检查它是否与所有者索引相对应。
        require(owner != address(0) && owner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == owner, "GS205");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        // 如果阈值已更改，则更改阈值。
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev 允许用另一个地址交换/替换保险箱中的所有者。 这只能通过安全事务来完成。 
    /// @notice 将保险箱中的所有者 `oldOwner` 替换为 `newOwner`。 
    /// @param prevOwner Owner 指向链表中要替换的所有者 
    /// @param oldOwner 要替换的所有者地址。 
    /// @param newOwner 新所有者地址。
    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    ) public authorized {
        // 所有者地址不能为空，哨兵或保险箱本身。
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS && newOwner != address(this), "GS203");
        // 不允许重复所有者。
        require(owners[newOwner] == address(0), "GS204");
        // 验证 oldOwner 地址并检查它是否对应于所有者索引。
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == oldOwner, "GS205");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev 允许更新安全所有者所需的确认次数。 这只能通过安全事务来完成。 
    /// @notice 将 Safe 的阈值更改为 `_threshold`。 
    /// @param _threshold 新阈值。
    function changeThreshold(uint256 _threshold) public authorized {
        // 验证阈值小于所有者数。
        require(_threshold <= ownerCount, "GS201");
        // 必须至少有一个保险箱所有者。
        require(_threshold >= 1, "GS202");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /// @dev 返回所有者数组。 
    /// @return 安全所有者数组。
    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title EtherPaymentFallback - 能接受 以太币支付 的 fallback 合约
contract EtherPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /// @dev Fallback function 接受以太币交易
    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SecuredTokenTransfer - Secure token transfer
contract SecuredTokenTransfer {
    /// @dev 传输一个代币，如果成功则返回 
    /// @param token 应该被传输的代币
    /// @param receiver 代币应该被传输到的接收者 
    /// @param amount 代币的数量应该转移的
    function transferToken(
        address token,
        address receiver,
        uint256 amount
    ) internal returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
                case 0 {
                    transferred := success
                }
                case 0x20 {
                    transferred := iszero(or(iszero(success), iszero(mload(0))))
                }
                default {
                    transferred := 0
                }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SelfAuthorized - 授权当前合约执行操作
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // 这是一个函数调用， 因为它最小化了字节码大小
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
contract SignatureDecoder {
    /// @dev 将字节签名划分为 `uint8 v, bytes32 r, bytes32 s`。 
    /// @notice 确保 边界检查，以避免 越界访问 
    /// @param pos 要读取哪个签名。应先执行此参数的边界检查，以避免越界访问 
    /// @param signatures concatenated rsv signatures

    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Singleton - 单例合约的基础（应该始终是第一个超级合约）
/// 这个合约与我们的代理合约紧密耦合（参见 `proxies/GnosisSafeProxy.sol`）
contract Singleton {
    // 单例总 首先声明变量， 以确保它与 代理合约 中的位置相同。 
    // 还应始终确保单独存储地址（使用完整字）
    address private singleton;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title StorageAccessible - 通用基础合约，允许调用者访问所有内部存储
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
contract StorageAccessible {
    /**
     * @dev 读取当前合约中存储的 `length` 字节 
     * @param offset - 当前合约存储中要开始读取的字数 
     * @param length - 要读取的数据字数（32 字节）
     * @return 读取的字节数。
     */
    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev 在 self 的上下文中对 targetContract 执行委托调用。 
     * 在内部恢复执行以避免副作用（使其成为静态）。 
     * 
     * 此方法使用等于 `abi.encode(bool(success), bytes(response))` 的数据恢复。 
     * 具体来说，调用此方法后的 `returndata` 将是： `success:bool || 响应长度：uint256 || 响应：字节`。 
     * 
     * @param targetContract 包含要执行的代码的合约地址。 
     * @param calldataPayload 应该发送到目标合约的调用数据（编码的方法名称和参数）。
     */
    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let success := delegatecall(gas(), targetContract, add(calldataPayload, 0x20), mload(calldataPayload), 0, 0)

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title GnosisSafeMath
 * @dev 具有安全检查的数学运算，在错误时恢复 
 * 从 SafeMath 重命名为 GnosisSafeMath 以避免冲突 
 * TODO：一旦打开 zeppelin 更新到 solc 0.5.0 就删除
 */
library GnosisSafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas 优化：这比要求 'a' 不为零要便宜，但是如果还测试了 'b'，则好处会丢失。
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev 减去两个数字，在溢出时恢复（即如果 subtrahend 大于 minuend）。
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev 添加两个数字，溢出时恢复。
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev 返回两个数字中最大的一个。 
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./DefaultCallbackHandler.sol";
import "../interfaces/ISignatureValidator.sol";
import "../GnosisSafe.sol";

/// @title Compatibility Fallback Handler - fallback handler to provider compatibility between pre 1.3.0 and 1.3.0+ Safe contracts
contract CompatibilityFallbackHandler is DefaultCallbackHandler, ISignatureValidator {
    //keccak256(
    //    "SafeMessage(bytes message)"
    //);
    bytes32 private constant SAFE_MSG_TYPEHASH = 0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca;

    bytes4 internal constant SIMULATE_SELECTOR = bytes4(keccak256("simulate(address,bytes)"));

    address internal constant SENTINEL_MODULES = address(0x1);
    bytes4 internal constant UPDATED_MAGIC_VALUE = 0x1626ba7e;

    /**
     * ISignatureValidator 的实现（参见`interfaces/ISignatureValidator.sol`） 
     * @dev 应该返回所提供的签名对于所提供的数据是否有效。 
     * @param _data 代表地址（msg.sender）签名的任意长度数据 
     * @param _signature 与_data 关联的签名字节数组 
     * @return 对应_data的有效或无效签名的布尔值
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view override returns (bytes4) {
        // Caller should be a Safe
        GnosisSafe safe = GnosisSafe(payable(msg.sender));
        bytes32 messageHash = getMessageHashForSafe(safe, _data);
        if (_signature.length == 0) {
            require(safe.signedMessages(messageHash) != 0, "Hash not approved");
        } else {
            safe.checkSignatures(messageHash, _data, _signature);
        }
        return EIP1271_MAGIC_VALUE;
    }

    /// @dev 返回可以由所有者签名的消息的哈希值。 
    /// @param message 应该被散列的消息 
    /// @return 消息散列。
    function getMessageHash(bytes memory message) public view returns (bytes32) {
        return getMessageHashForSafe(GnosisSafe(payable(msg.sender)), message);
    }
    
    /// @dev 返回可以由所有者签名的消息的哈希值。 
    /// @param safe 消息的目标安全 
    /// @param message 应该被散列的消息 
    /// @return 消息散列。
    function getMessageHashForSafe(GnosisSafe safe, bytes memory message) public view returns (bytes32) {
        bytes32 safeMessageHash = keccak256(abi.encode(SAFE_MSG_TYPEHASH, keccak256(message)));
        return keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), safe.domainSeparator(), safeMessageHash));
    }

    /**
     * Implementation of updated EIP-1271
     * @dev Should return whether the signature provided is valid for the provided data.
     *       The save does not implement the interface since `checkSignatures` is not a view method.
     *       The method will not perform any state changes (see parameters of `checkSignatures`)
     * @param _dataHash Hash of the data signed on the behalf of address(msg.sender)
     * @param _signature Signature byte array associated with _dataHash
     * @return a bool upon valid or invalid signature with corresponding _dataHash
     * @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
     */
    function isValidSignature(bytes32 _dataHash, bytes calldata _signature) external view returns (bytes4) {
        ISignatureValidator validator = ISignatureValidator(msg.sender);
        bytes4 value = validator.isValidSignature(abi.encode(_dataHash), _signature);
        return (value == EIP1271_MAGIC_VALUE) ? UPDATED_MAGIC_VALUE : bytes4(0);
    }

    /// @dev 返回前 10 个模块的数组
    /// @return Array of modules.
    function getModules() external view returns (address[] memory) {
        // Caller 应该是保险箱
        GnosisSafe safe = GnosisSafe(payable(msg.sender));
        (address[] memory array, ) = safe.getModulesPaginated(SENTINEL_MODULES, 10);
        return array;
    }

    /**
    * @dev 在 self 的上下文中对 targetContract 执行委托调用。 * 在内部恢复执行以避免副作用（使其成为静态）。捕获还原并将编码结果作为字节返回。 
    * @param targetContract 包含要执行的代码的合约地址。 
    * @param calldataPayload 应该发送到目标合约的调用数据（编码的方法名称和参数）。
    */
    function simulate(address targetContract, bytes calldata calldataPayload) external returns (bytes memory response) {
        // 禁止编译器关于不使用参数的警告，同时允许参数保留名称 以用于文档目的。 这不会​​生成代码。
        targetContract;
        calldataPayload;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let internalCalldata := mload(0x40)
            // Store `simulateAndRevert.selector`.
            // String representation is used to force right padding
            mstore(internalCalldata, "\xb4\xfa\xba\x09")
            // Abuse the fact that both this and the internal methods have the
            // same signature, and differ only in symbol name (and therefore,
            // selector) and copy calldata directly. This saves us approximately
            // 250 bytes of code and 300 gas at runtime over the
            // `abi.encodeWithSelector` builtin.
            calldatacopy(add(internalCalldata, 0x04), 0x04, sub(calldatasize(), 0x04))

            // `pop` is required here by the compiler, as top level expressions
            // can't have return values in inline assembly. `call` typically
            // returns a 0 or 1 value indicated whether or not it reverted, but
            // since we know it will always revert, we can safely ignore it.
            pop(
                call(
                    gas(),
                    // address() has been changed to caller() to use the implementation of the Safe
                    caller(),
                    0,
                    internalCalldata,
                    calldatasize(),
                    // The `simulateAndRevert` call always reverts, and
                    // instead encodes whether or not it was successful in the return
                    // data. The first 32-byte word of the return data contains the
                    // `success` value, so write it to memory address 0x00 (which is
                    // reserved Solidity scratch space and OK to use).
                    0x00,
                    0x20
                )
            )

            // Allocate and copy the response bytes, making sure to increment
            // the free memory pointer accordingly (in case this method is
            // called as an internal function). The remaining `returndata[0x20:]`
            // contains the ABI encoded response bytes, so we can just write it
            // as is to memory.
            let responseSize := sub(returndatasize(), 0x20)
            response := mload(0x40)
            mstore(0x40, add(response, responseSize))
            returndatacopy(response, 0x20, responseSize)

            if iszero(mload(0x00)) {
                revert(add(response, 0x20), mload(response))
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/ERC1155TokenReceiver.sol";
import "../interfaces/ERC721TokenReceiver.sol";
import "../interfaces/ERC777TokensRecipient.sol";
import "../interfaces/IERC165.sol";

/// @title Default Callback Handler - returns true for known token callbacks
contract DefaultCallbackHandler is ERC1155TokenReceiver, ERC777TokensRecipient, ERC721TokenReceiver, IERC165 {
    string public constant NAME = "Default Callback Handler";
    string public constant VERSION = "1.0.0";

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure override {
        // We implement this for completeness, doesn't really have any value
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(ERC1155TokenReceiver).interfaceId ||
            interfaceId == type(ERC721TokenReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
    /** 
    @notice 处理单个 ERC1155 令牌类型的接收。 
    @dev 符合 ERC1155 的智能合约必须在余额更新后的“safeTransferFrom”结束时在代币接收者合约上调用此函数。
    如果该函数接受传输，则必须返回 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`（即 0xf23a6e61）。
    如果拒绝传输，该函数必须恢复。返回除规定的 keccak256 生成值之外的任何其他值必须导致调用者恢复事务。 
    @param _operator 发起传输的地址（即 msg.sender） 
    @param _from 之前拥有代币的地址 
    @param _id 正在传输的代币的 ID 
    @param _value 正在传输的代币数量 
    @param _data 附加数据没有指定格式 
    @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` 
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /** 
    @notice 处理多个 ERC1155 令牌类型的接收。 
    @dev 符合 ERC1155 的智能合约必须在余额更新后的“safeBatchTransferFrom”结束时在代币接收者合约上调用此函数。
    如果此函数接受传输，则必须返回 `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`（即 0xbc197c81）。
    如果拒绝传输，该函数必须恢复。返回除规定的 keccak256 生成值之外的任何其他值必须导致调用者恢复事务。 
    @param _operator 发起批量传输的地址（即 msg.sender） 
    @param _from 先前拥有令牌的地址 
    @param _ids 包含正在传输的每个令牌的 id 的数组（顺序和长度必须匹配 _values 数组） 
    @param _values包含正在传输的每个令牌数量的数组（顺序和长度必须与 _ids 数组匹配）
    @param _data 没有指定格式的附加数据 
    @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes )"))` 
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice 处理 NFT 的收据
    /// @dev ERC721 智能合约在“转移”之后在接收者上调用此函数。此 函数可能会抛出以恢复和拒绝传输。魔术值以外的返回必须导致事务被还原。
    /// 注意：合约地址始终是消息发送者。
    /// @param _operator 调用 `safeTransferFrom` 函数的地址
    /// @param _from 先前拥有令牌的地址
    /// @param _tokenId 正在传输的 NFT 标识符
    /// @param _data 没有附加数据指定格式
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` 除非抛出。
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
    * @dev 如果此合约实现了由 `interfaceId` 定义的接口，则返回 true。
    * 
    * 此函数调用必须使用少于 30 000 个气体。 
    */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev 应该返回提供的签名是否对提供的数据有效 
     * @param _data 代表地址（this）签名的任意长度数据 
     * @param _signature 与_data关联的签名字节数组 
     * 
     * 必须返回 bytes4 魔术值 0x20c13b0b当函数通过时。 
     * 不得修改状态（对于 solc < 0.5 使用 STATICCALL，对于 solc > 0.5 使用视图修饰符） 
     * 必须允许外部调用

     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}