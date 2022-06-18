// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;
import "../../../interfaces/IEvaFlowProxy.sol";
import "./NftLimitOrderFlow.sol";

contract NftLimitOrderFlowProxy is IEvaFlowProxy, NftLimitOrderFlow {
    constructor(
        address _config,
        address _evaSafesFactory,
        string memory name,
        string memory version
    ) NftLimitOrderFlow(_config, _evaSafesFactory, name, version) {} //solhint-disable

    function create(
        IEvaFlowController ser,
        INftLimitOrder nftLimitOrder,
        KeepNetWork network,
        uint256 gasFee,
        string memory name,
        Order memory order
    ) external payable {
        require(bytes(name).length > 0, "invalid name");
        uint256 _value = msg.value - gasFee;
        require(order.amount * order.price <= _value, "order value + gasFee must be greater than msg.value");

        uint256 flowSize = ser.getFlowMetaSize();
        bytes32 orderId = nftLimitOrder.createOrder{value: _value}(order, flowSize);
        uint256 afterFlowId = ser.registerFlow{value: gasFee}(
            name,
            network,
            address(nftLimitOrder),
            abi.encode(orderId)
        );
        require(flowSize == afterFlowId, "flowId must be equal");
    }

    function closeFlow(IEvaFlowController ser, uint256 flowId) external override {
        ser.closeFlow(flowId);
        (INftLimitOrder exchange, bytes32 orderId) = _getInfo(ser, flowId);
        exchange.cancelOrder(orderId);
    }

    function _getInfo(IEvaFlowController ser, uint256 flowId)
        internal
        view
        returns (INftLimitOrder nftLimitOrder, bytes32 orderId)
    {
        (address flow, bytes memory checkdata) = ser.getFlowCheckInfo(flowId);
        require(flow != address(0), "empty");

        nftLimitOrder = INftLimitOrder(flow);
        orderId = abi.decode(checkdata, (bytes32));
    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

import "./IEvaFlowController.sol";

interface IEvaFlowProxy {
    function closeFlow(IEvaFlowController ctr, uint256 flowId) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;
import "../../../interfaces/IEvaFlow.sol";
import "../../../venders/EIP712.sol";
import "../../../lib/MathConv.sol";
import "../../../interfaces/INftLimitOrder.sol";
import {IEvabaseConfig} from "../../../interfaces/IEvabaseConfig.sol";
import {IEvaSafes} from "../../../interfaces/IEvaSafes.sol";
import {IEvaFlowController} from "../../../interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "../../../interfaces/IEvaSafesFactory.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftLimitOrderFlow is IEvaFlow, INftLimitOrder, EIP712, Ownable {
    using Address for address;

    bytes32 private constant _ORDER_TYPEHASH =
        keccak256(
            "Order(address owner,address assetToken,uint256 amount,uint256 price,uint256 deadline,uint256 tokenId,uint256 salt)"
        );
    IEvaSafesFactory public evaSafesFactory;
    IEvabaseConfig public config;
    address private _owner;

    mapping(bytes32 => OrderExist) public orderExists;

    constructor(
        address _config,
        address _evaSafesFactory,
        string memory name,
        string memory version
    ) {
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        config = IEvabaseConfig(_config);
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        init(name, version);
    }

    function check(bytes memory) external pure override returns (bool, bytes memory) {
        revert("No support check");
    }

    function setFactory(address factory) external onlyOwner {
        evaSafesFactory = IEvaSafesFactory(factory);
    }

    function execute(bytes memory executeData) external override returns (bool canDestoryFlow) {
        (Order memory order, bytes memory signature, bytes[] memory data) = abi.decode(
            executeData,
            (Order, bytes, bytes[])
        );
        canDestoryFlow = _atomicMatch(order, signature, data);
    }

    function createOrder(Order memory order, uint256 flowId) external payable override returns (bytes32 orderId) {
        require(msg.sender == evaSafesFactory.get(order.owner), "only safes can creat order");

        require(order.amount > 0, "invalid order.amount");
        require(order.price > 0, "invalid order.price");

        require(order.assetToken != address(0), "invalid order.assetToken");
        require(order.deadline > block.timestamp, "invalid order.deadline"); //solhint-disable

        uint256 totalOrder = order.amount * order.price;
        uint256 total = msg.value;
        require(total >= totalOrder, "invalid msg value");

        orderId = hashOrder(order);
        require(orderExists[orderId].owner == address(0), "order exist");

        orderExists[orderId] = OrderExist({
            amount: 0,
            owner: order.owner,
            balance: MathConv.toU96(total),
            deadline: MathConv.toU64(order.deadline)
        });

        emit OrderCreated(msg.sender, flowId, order);
    }

    function cancelOrder(bytes32 orderId) public override {
        OrderExist storage orderExist = orderExists[orderId];
        require(orderExist.owner != address(0), "order not exist");

        if (msg.sender != evaSafesFactory.get(orderExist.owner)) {
            require(orderExpired(orderId), "order is active");
        }
        uint256 remain = orderExist.balance;
        address user = orderExist.owner;
        delete orderExists[orderId];
        if (remain > 0) {
            (bool succeed, ) = user.call{value: remain}(""); //solhint-disable
            require(succeed, "Failed to transfer Ether");
        }
        emit OrderCancelled(msg.sender, orderId);
    }

    function needClose(bytes memory orderIdData) external view override returns (bool yes) {
        bytes32 orderId = abi.decode(orderIdData, (bytes32));
        yes = orderExpired(orderId);
    }

    function close(bytes memory orderIdData) external override {
        bytes32 orderId = abi.decode(orderIdData, (bytes32));
        cancelOrder(orderId);
    }

    function _atomicMatch(
        Order memory _order,
        bytes memory _signature,
        bytes[] memory _data
    ) internal returns (bool orderDone) {
        require(verifyOrder(_order, _signature), "signature is not valid");
        bytes32 orderId = hashOrder(_order);
        OrderExist storage orderExist = orderExists[orderId];
        require(orderExist.owner != address(0), "order not exist");
        require(_order.owner != address(0), "order owner addrss is 0x");
        uint256 _amount = _order.amount;
        require(_amount > 0, "execute amount gt 0");

        require(_order.deadline >= block.timestamp, "order time is end"); //solhint-disable
        require(msg.sender == evaSafesFactory.get(orderExist.owner), "should exected by safes");

        uint256 total = 0;

        require(_data.length <= _order.amount - orderExist.amount, "Exceeded purchase");

        for (uint256 i = 0; i < _data.length; i++) {
            (address target, bytes memory input, uint256 value) = abi.decode(_data[i], (address, bytes, uint256));
            require(target != address(this), "FORBIDDEN");
            require(target != msg.sender, "FORBIDDEN");
            target.functionCallWithValue(input, value, "CallFailed");

            total += value;
        }

        //Increase in the number of completed purchases
        orderExist.amount = MathConv.toU8(_data.length) + orderExist.amount;
        //Decrease in funds deposited for purchases
        uint96 totalUsed = MathConv.toU96(total);
        require(orderExist.balance >= totalUsed, "invalid balance");
        orderExist.balance = orderExist.balance - totalUsed;

        orderDone = orderExist.amount == _order.amount;
        if (orderDone) {
            uint256 bal = orderExist.balance;
            if (bal > 0) {
                (bool succeed, ) = orderExist.owner.call{value: bal}(""); //solhint-disable
                require(succeed, "Failed to transfer Ether");
            }
            delete orderExists[orderId];
        }
        emit OrderExecuted(msg.sender, orderId, _data.length, total);
    }

    function hashOrder(Order memory order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode( // order
                    _ORDER_TYPEHASH,
                    order.owner,
                    order.assetToken,
                    order.amount,
                    order.price,
                    order.deadline,
                    order.tokenId,
                    order.salt
                )
            );
    }

    function verifyOrder(Order memory order, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = hashOrder(order);

        bytes32 ethSignedMessageHash = _hashTypedDataV4(messageHash);

        return SignatureChecker.isValidSignatureNow(order.owner, ethSignedMessageHash, signature);
    }

    function orderExpired(bytes32 orderId) public view returns (bool) {
        // solhint-disable
        uint256 deadline = orderExists[orderId].deadline;
        return deadline > 0 && deadline < block.timestamp;
    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {FlowStatus, KeepNetWork} from "../lib/EvabaseHelper.sol";

//struct
struct EvaFlowMeta {
    FlowStatus flowStatus;
    KeepNetWork keepNetWork;
    address admin;
    address lastKeeper;
    address lastVersionflow;
    uint256 lastExecNumber;
    uint256 maxVaildBlockNumber;
    string flowName;
    bytes checkData;
}

struct EvaUserMeta {
    uint120 ethBal;
    uint120 gasTokenBal; //keep
    uint8 vaildFlowsNum;
}

struct MinConfig {
    address feeRecived;
    address feeToken;
    uint64 minGasFundForUser;
    uint64 minGasFundOneFlow;
    uint16 ppb;
    uint16 blockCountPerTurn;
}

interface IEvaFlowController {
    event FlowOperatorChanged(address op, bool removed);
    event FlowCreated(address indexed user, uint256 indexed flowId, address flowAdd, bytes checkData, uint256 fee);
    event FlowUpdated(address indexed user, uint256 flowId, address flowAdd);
    event FlowClosed(address indexed user, uint256 flowId);
    event FlowExecuteSuccess(
        address indexed user,
        uint256 indexed flowId,
        uint120 payAmountByETH,
        uint120 payAmountByFeeToken,
        uint256 gasUsed
    );
    event FlowExecuteFailed(
        address indexed user,
        uint256 indexed flowId,
        uint120 payAmountByETH,
        uint120 payAmountByFeeToken,
        uint256 gasUsed,
        string reason
    );

    event SetMinConfig(
        address indexed user,
        address feeRecived,
        address feeToken,
        uint64 minGasFundForUser,
        uint64 minGasFundOneFlow,
        uint16 ppb,
        uint16 blockCountPerTurn
    );

    function registerFlow(
        string memory name,
        KeepNetWork keepNetWork,
        address flow,
        bytes memory checkdata
    ) external payable returns (uint256 flowId);

    function closeFlow(uint256 flowId) external;

    function closeFlowWithGas(uint256 flowId, uint256 before) external;

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory inputData
    ) external;

    function depositFund(address flowAdmin) external payable;

    function withdrawFund(address recipient, uint256 amount) external;

    function withdrawPayment(uint256 amount) external;

    function getIndexVaildFlow(uint256 index, KeepNetWork keepNetWork) external view returns (uint256 value);

    function getAllVaildFlowSize(KeepNetWork keepNetWork) external view returns (uint256 size);

    function getFlowMetas(uint256 index) external view returns (EvaFlowMeta memory);

    function getFlowMetaSize() external view returns (uint256);

    function batchExecFlow(address keeper, bytes memory data) external;

    function getFlowCheckInfo(uint256 flowId) external view returns (address flow, bytes memory checkData);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

enum CompareOperator {
    Eq,
    Ne,
    Ge,
    Gt,
    Le,
    Lt
}

enum FlowStatus {
    Active, //可执行
    Closed,
    Expired,
    Completed,
    Unknown
}

enum KeepNetWork {
    ChainLink,
    Evabase,
    Gelato,
    Others
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaFlow {
    function check(bytes memory checkData) external view returns (bool needExecute, bytes memory executeData);

    function execute(bytes memory executeData) external returns (bool canDestoryFlow);

    function needClose(bytes memory checkData) external returns (bool yes);

    function close(bytes memory checkData) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    uint256 private _CACHED_CHAIN_ID;

    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    /* solhint-disable private-vars-leading-underscore */
    function init(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name, version, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
/* solhint-disable */

pragma solidity ^0.8.0;

library MathConv {
    function toU120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "to120-overflow");
        return uint120(value);
    }

    function toU96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "to96-overflow");
        return uint96(value);
    }

    function toU64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "to64-overflow");
        return uint64(value);
    }

    function toU8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "to8-overflow");
        return uint8(value);
    }
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface INftLimitOrder {
    struct Order {
        address owner; //拥有人
        address assetToken; //资产合约地址
        uint256 amount; //NFT数量
        uint256 price; //NFT价格
        uint256 deadline; //订单过期时间 s
        uint256 tokenId;
        uint256 salt; //随机数
    }
    struct OrderExist {
        address owner; //   slot 0   order owner
        uint96 balance; //  slot 0  order eth balance
        uint8 amount; //    slot 1    dealed nft amount
        uint64 deadline; // slot 1 order expired time
    }
    event OrderExecuted(address indexed user, bytes32 orderId, uint256 amount, uint256 value);

    event OrderCancelled(address indexed user, bytes32 orderId);

    event OrderCreated(address indexed user, uint256 indexed flowId, Order order);

    function createOrder(Order memory order, uint256 flowId) external payable returns (bytes32 orderId);

    function cancelOrder(bytes32 orderId) external;
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

struct KeepInfo {
    bool isActive;
    KeepNetWork keepNetWork;
}

interface IEvabaseConfig {
    event AddKeeper(address indexed user, address keeper, KeepNetWork keepNetWork);
    event RemoveKeeper(address indexed user, address keeper);
    event AddBatchKeeper(address indexed user, address[] keeper, KeepNetWork[] keepNetWork);
    event RemoveBatchKeeper(address indexed user, address[] keeper);

    event SetControl(address indexed user, address control);
    event SetBatchFlowNum(address indexed user, uint32 num);

    function getBytes32Item(bytes32 key) external view returns (bytes32);

    function getAddressItem(bytes32 key) external view returns (address);

    function control() external view returns (address);

    function isKeeper(address query) external view returns (bool);

    function batchFlowNum() external view returns (uint32);

    function keepBotSizes(KeepNetWork keepNetWork) external view returns (uint32);

    function getKeepBot(address add) external view returns (KeepInfo memory);

    function isActiveControler(address add) external view returns (bool);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

enum HowToCall {
    Call,
    DelegateCall
}

interface IEvaSafes {
    function owner() external view returns (address);

    function initialize(address admin, address agent) external;

    function proxy(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) external payable returns (bytes memory);

    function isEvaSafes() external pure returns (bool);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaSafesFactory {
    event ConfigChanged(address indexed newConfig);

    event WalletCreated(address indexed user, address wallet);

    function get(address user) external view returns (address wallet);

    function create(address user) external returns (address wallet);

    function calcSafes(address user) external view returns (address wallet);

    function changeConfig(address _config) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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