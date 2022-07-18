//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./libraries/EthereumVerifier.sol";
import "./libraries/ProofParser.sol";
import "./libraries/Utils.sol";

import "./interfaces/IMaticStaking.sol";
import "./interfaces/IPolygonPool.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IBondToken.sol";
import "./interfaces/IDepositManager.sol";
import "./interfaces/IRootChainManager.sol";
import "./interfaces/IPolygonERC20Predicate.sol";

contract MaticStaking is
    IMaticStaking,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    address private _operator;

    // PolygonPool
    IPolygonPool private _pool;
    // StakeFi Cross-chain
    IBridge private _bridge;

    // Polygon chain id(137/80001)
    uint256 private _toChainId;

    // Matic token on Ethereum
    address private _matic;
    // aMATICb
    address private _bondToken;
    // aMATICc
    address private _certToken;

    // Matic POS variables
    IPolygonERC20Predicate private _maticPredicate;
    IRootChainManager private _rootChainManager;
    IDepositManager private _depositManager;

    address private _ankrToken;

    /**
     * Modifiers
     */

    modifier onlyOperator() {
        require(msg.sender == _operator, "Access: only operator");
        _;
    }

    function initialize(
        address operator,
        address maticAddress,
        address bondToken,
        address certToken,
        address rootManager,
        address maticPredicate,
        address depositManager,
        address pool,
        address bridge
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        _operator = operator;
        _matic = maticAddress;
        _bondToken = bondToken;
        _certToken = certToken;
        _maticPredicate = IPolygonERC20Predicate(maticPredicate);
        _rootChainManager = IRootChainManager(rootManager);
        _depositManager = IDepositManager(depositManager);
        _pool = IPolygonPool(pool);
        _bridge = IBridge(bridge);
        // give an approval to bridge to spend;
        IERC20Upgradeable(_bondToken).approve(bridge, type(uint256).max);
        IERC20Upgradeable(_certToken).approve(bridge, type(uint256).max);
        // give an approval to pool to spend;
        IERC20Upgradeable(_matic).approve(pool, type(uint256).max);
    }

    function startExit(bytes calldata data) external override {
        _maticPredicate.startExitWithBurntTokens(data);
        emit StartExit(data);
    }

    function stake(
        address receiver,
        uint256 amount,
        bool isRebasing
    ) external override {
        _rootChainManager.processExits(_matic);
        //   delegate via StakeFi PolygonPool
        address token;
        if (isRebasing) {
            token = _bondToken;
            _pool.stakeAndClaimBonds(amount);
        } else {
            token = _certToken;
            _pool.stakeAndClaimCerts(amount);
            amount = (amount * IBondToken(_bondToken).ratio()) / 1e18;
        }
        // transfer tokens across the bridge
        _bridge.deposit(token, _toChainId, receiver, amount);
        emit Staked(receiver, amount, isRebasing);
    }

    function unstake(
        bytes calldata encodedProof,
        bytes calldata rawReceipt,
        bytes memory proofSignature,
        bytes memory signature,
        uint256 fee,
        uint256 useBeforeBlock
    ) external onlyOperator {
        bool isRebasing;
        EthereumVerifier.State memory state;
        {
            // get info about receipt
            uint256 receiptOffset;
            assembly {
                receiptOffset := add(0x4, calldataload(36))
            }
            (state, ) = EthereumVerifier.parseTransactionReceipt(receiptOffset);
            // withdraw from bridge
            _bridge.withdraw(encodedProof, rawReceipt, proofSignature);
        }
        if (state.toToken == _bondToken) {
            isRebasing = true;
            _pool.unstakeBonds(
                state.totalAmount,
                fee,
                useBeforeBlock,
                signature
            );
        } else if (state.toToken == _certToken) {
            _pool.unstakeCerts(
                state.totalAmount,
                fee,
                useBeforeBlock,
                signature
            );
        }
        emit Unstaked(state.toAddress, state.totalAmount, isRebasing, fee);
    }

    // executes after unbond time by operator
    function unstakeAcrossToPolygon(uint256 amount) external onlyOperator {
        require(amount > 0, "amount should be greater than 0");
        _depositManager.depositERC20ForUser(_matic, _operator, amount);
        emit UnstakedAcrossToPolygon(_operator, amount);
    }

    function changeBondToken(address bondToken) external onlyOwner {
        require(bondToken != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(bondToken),
            "non-contract address"
        );
        _bondToken = bondToken;
        emit BondTokenChanged(bondToken);
    }

    function changeCertToken(address certToken) external onlyOwner {
        require(certToken != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(certToken),
            "non-contract address"
        );
        _certToken = certToken;
        emit CertTokenChanged(certToken);
    }

    function changeAnkrToken(address ankrToken) external onlyOwner {
        require(ankrToken != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(ankrToken),
            "non-contract address"
        );
        _ankrToken = ankrToken;
        emit AnkrTokenChanged(ankrToken);
    }

    function changePool(address pool) external onlyOwner {
        require(pool != address(0), "zero address");
        require(AddressUpgradeable.isContract(pool), "non-contract address");
        IERC20Upgradeable(_bondToken).approve(
            address(_pool),
            type(uint256).min
        );
        IERC20Upgradeable(_certToken).approve(
            address(_pool),
            type(uint256).min
        );
        IERC20Upgradeable(_matic).approve(address(_pool), type(uint256).min);
        IERC20Upgradeable(_ankrToken).approve(
            address(_pool),
            type(uint256).min
        );
        _pool = IPolygonPool(pool);
        IERC20Upgradeable(_matic).approve(pool, type(uint256).max);
        IERC20Upgradeable(_bondToken).approve(pool, type(uint256).max);
        IERC20Upgradeable(_certToken).approve(pool, type(uint256).max);
        IERC20Upgradeable(_ankrToken).approve(pool, type(uint256).max);
        emit PoolChanged(pool);
    }

    function changeBridge(address bridge) external onlyOwner {
        require(bridge != address(0), "zero address");
        require(AddressUpgradeable.isContract(bridge), "non-contract address");
        IERC20Upgradeable(_bondToken).approve(
            address(_bridge),
            type(uint256).min
        );
        IERC20Upgradeable(_certToken).approve(
            address(_bridge),
            type(uint256).min
        );
        _bridge = IBridge(bridge);
        IERC20Upgradeable(_bondToken).approve(bridge, type(uint256).max);
        IERC20Upgradeable(_certToken).approve(bridge, type(uint256).max);
        emit BridgeChanged(bridge);
    }

    function changeDepositManager(address depositManager) external onlyOwner {
        require(depositManager != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(depositManager),
            "non-contract address"
        );
        IERC20Upgradeable(_matic).approve(
            address(_depositManager),
            type(uint256).min
        );
        _depositManager = IDepositManager(depositManager);
        IERC20Upgradeable(_matic).approve(
            address(_depositManager),
            type(uint256).max
        );
        emit DepositManagerChanged(depositManager);
    }

    function changeMaticPredicate(address maticPredicate) external onlyOwner {
        require(maticPredicate != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(maticPredicate),
            "non-contract address"
        );
        _maticPredicate = IPolygonERC20Predicate(maticPredicate);
        emit MaticPredicateChanged(maticPredicate);
    }

    function changeRootChainManager(address rootChainManager)
        external
        onlyOwner
    {
        require(rootChainManager != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(rootChainManager),
            "non-contract address"
        );
        _rootChainManager = IRootChainManager(rootChainManager);
        emit MaticPredicateChanged(rootChainManager);
    }

    function changeToChain(uint256 toChain) external onlyOwner {
        require(toChain != 0, "zero chain id");
        _toChainId = toChain;
        emit ToChainChanged(toChain);
    }

    function changeOperator(address operator) external onlyOwner {
        require(operator != address(0), "zero address");
        _operator = operator;
        emit OperatorChanged(operator);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

// import "../SimpleToken.sol";

library Utils {
    function currentChain() internal view returns (uint256) {
        uint256 chain;
        assembly {
            chain := chainid()
        }
        return chain;
    }

    function stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function saturatingMultiply(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return type(uint256).max;
            return c;
        }
    }

    function saturatingAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return type(uint256).max;
            return c;
        }
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(floor((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideFloor(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return
            saturatingAdd(
                saturatingMultiply(a / c, b),
                ((a % c) * b) / c // can't fail because of assumption 2.
            );
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(ceil((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideCeil(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return
            saturatingAdd(
                saturatingMultiply(a / c, b),
                ((a % c) * b + (c - 1)) / c // can't fail because of assumption 2.
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./CallDataRLPReader.sol";
import "./Utils.sol";

library ProofParser {
    // Proof is message format signed by the protocol. It contains somewhat redundant information, so only part
    // of the proof could be passed into the contract and other part can be inferred from transaction receipt
    struct Proof {
        uint256 chainId;
        uint256 status;
        bytes32 transactionHash;
        uint256 blockNumber;
        bytes32 blockHash;
        uint256 transactionIndex;
        bytes32 receiptHash;
        uint256 transferAmount;
    }

    function parseProof(uint256 proofOffset)
        internal
        pure
        returns (Proof memory)
    {
        Proof memory proof;
        uint256 dataOffset = proofOffset + 0x20;
        assembly {
            calldatacopy(proof, dataOffset, 0x20) // 1 field (chainId)
            dataOffset := add(dataOffset, 0x20)
            calldatacopy(add(proof, 0x40), dataOffset, 0x80) // 4 fields * 0x20 = 0x80
            dataOffset := add(dataOffset, 0x80)
            calldatacopy(add(proof, 0xe0), dataOffset, 0x20) // transferAmount
        }
        return proof;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./CallDataRLPReader.sol";
import "./Utils.sol";
import "../interfaces/IBridge.sol";

library EthereumVerifier {
    bytes32 constant TOPIC_PEG_IN_LOCKED =
        keccak256(
            "DepositLocked(uint256,address,address,address,address,uint256,(bytes32,bytes32,uint256,address,bytes32))"
        );
    bytes32 constant TOPIC_PEG_IN_BURNED =
        keccak256(
            "DepositBurned(uint256,address,address,address,address,uint256,(bytes32,bytes32,uint256,address,bytes32),address)"
        );

    enum PegInType {
        None,
        Lock,
        Burn
    }

    struct State {
        bytes32 receiptHash;
        address contractAddress;
        uint256 chainId;
        address fromAddress;
        address payable toAddress;
        address fromToken;
        address toToken;
        uint256 totalAmount;
        // metadata fields (we can't use Metadata struct here because of Solidity struct memory layout)
        bytes32 symbol;
        bytes32 name;
        uint256 originChain;
        address originAddress;
        bytes32 bondMetadata;
        address originToken;
    }

    function getMetadata(State memory state)
        internal
        pure
        returns (IBridge.Metadata memory)
    {
        IBridge.Metadata memory metadata;
        assembly {
            metadata := add(state, 0x100)
        }
        return metadata;
    }

    function parseTransactionReceipt(uint256 receiptOffset)
        internal
        view
        returns (State memory, PegInType pegInType)
    {
        State memory state;
        /* parse peg-in data from logs */
        uint256 iter = CallDataRLPReader.beginIteration(receiptOffset + 0x20);
        {
            /* postStateOrStatus - we must ensure that tx is not reverted */
            uint256 statusOffset = iter;
            iter = CallDataRLPReader.next(iter);
            require(
                CallDataRLPReader.payloadLen(
                    statusOffset,
                    iter - statusOffset
                ) == 1,
                "tx is reverted"
            );
        }
        /* skip cumulativeGasUsed */
        iter = CallDataRLPReader.next(iter);
        /* logs - we need to find our logs */
        uint256 logs = iter;
        iter = CallDataRLPReader.next(iter);
        uint256 logsIter = CallDataRLPReader.beginIteration(logs);
        for (; logsIter < iter; ) {
            uint256 log = logsIter;
            logsIter = CallDataRLPReader.next(logsIter);
            /* make sure there is only one peg-in event in logs */
            PegInType logType = _decodeReceiptLogs(state, log);
            if (logType != PegInType.None) {
                require(pegInType == PegInType.None, "multiple logs");
                pegInType = logType;
            }
        }
        /* don't allow to process if peg-in type is unknown */
        // require(pegInType != PegInType.None, "missing logs");
        return (state, pegInType);
    }

    function _decodeReceiptLogs(State memory state, uint256 log)
        internal
        pure
        returns (PegInType pegInType)
    {
        uint256 logIter = CallDataRLPReader.beginIteration(log);
        address contractAddress;
        {
            /* parse smart contract address */
            uint256 addressOffset = logIter;
            logIter = CallDataRLPReader.next(logIter);
            contractAddress = CallDataRLPReader.toAddress(addressOffset);
        }
        /* topics */
        bytes32 mainTopic;
        address fromAddress;
        address toAddress;
        {
            uint256 topicsIter = logIter;
            logIter = CallDataRLPReader.next(logIter);
            // Must be 3 topics RLP encoded: event signature, fromAddress, toAddress
            // Each topic RLP encoded is 33 bytes (0xa0[32 bytes data])
            // Total payload: 99 bytes. Since it's list with total size bigger than 55 bytes we need 2 bytes prefix (0xf863)
            // So total size of RLP encoded topics array must be 101
            if (CallDataRLPReader.itemLength(topicsIter) != 101) {
                return PegInType.None;
            }
            topicsIter = CallDataRLPReader.beginIteration(topicsIter);
            mainTopic = bytes32(CallDataRLPReader.toUintStrict(topicsIter));
            topicsIter = CallDataRLPReader.next(topicsIter);
            fromAddress = address(
                bytes20(uint160(CallDataRLPReader.toUintStrict(topicsIter)))
            );

            topicsIter = CallDataRLPReader.next(topicsIter);
            toAddress = address(
                bytes20(uint160(CallDataRLPReader.toUintStrict(topicsIter)))
            );
            topicsIter = CallDataRLPReader.next(topicsIter);
            require(topicsIter == logIter); // safety check that iteration is finished
        }
        uint256 ptr = CallDataRLPReader.rawDataPtr(logIter);
        logIter = CallDataRLPReader.next(logIter);
        uint256 len = logIter - ptr;
        {
            // parse logs based on topic type and check that event data has correct length
            uint256 expectedLen;
            if (mainTopic == TOPIC_PEG_IN_LOCKED) {
                expectedLen = 0x120;
                pegInType = PegInType.Lock;
            } else if (mainTopic == TOPIC_PEG_IN_BURNED) {
                expectedLen = 0x140;
                pegInType = PegInType.Burn;
            } else {
                return PegInType.None;
            }
            if (len != expectedLen) {
                return PegInType.None;
            }
        }
        {
            // read chain id separately and verify that contract that emitted event is relevant
            uint256 chainId;
            assembly {
                chainId := calldataload(ptr)
            }
            //    if (chainId != Utils.currentChain()) return PegInType.None;
            // All checks are passed after this point, no errors allowed and we can modify state
            state.chainId = chainId;
            ptr += 0x20;
            len -= 0x20;
        }

        {
            uint256 structOffset;
            assembly {
                // skip 5 fields: receiptHash, contractAddress, chainId, fromAddress, toAddress
                structOffset := add(state, 0xa0)
                calldatacopy(structOffset, ptr, len)
            }
        }

        state.contractAddress = contractAddress;
        state.fromAddress = fromAddress;
        state.toAddress = payable(toAddress);
        return pegInType;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.6;

library CallDataRLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    function beginIteration(uint256 listOffset)
        internal
        pure
        returns (uint256 iter)
    {
        return listOffset + _payloadOffset(listOffset);
    }

    function next(uint256 iter) internal pure returns (uint256 nextIter) {
        return iter + itemLength(iter);
    }

    function payloadLen(uint256 ptr, uint256 len)
        internal
        pure
        returns (uint256)
    {
        return len - _payloadOffset(ptr);
    }

    function toAddress(uint256 ptr) internal pure returns (address) {
        return address(uint160(toUint(ptr, 21)));
    }

    function toUint(uint256 ptr, uint256 len) internal pure returns (uint256) {
        require(len > 0 && len <= 33);
        uint256 offset = _payloadOffset(ptr);
        uint256 numLen = len - offset;

        uint256 result;
        assembly {
            result := calldataload(add(ptr, offset))
            // cut off redundant bytes
            result := shr(mul(8, sub(32, numLen)), result)
        }
        return result;
    }

    function toUintStrict(uint256 ptr) internal pure returns (uint256) {
        // one byte prefix
        uint256 result;
        assembly {
            result := calldataload(add(ptr, 1))
        }
        return result;
    }

    function rawDataPtr(uint256 ptr) internal pure returns (uint256) {
        return ptr + _payloadOffset(ptr);
    }

    // @return entire rlp item byte length
    function itemLength(uint256 callDataPtr) internal pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, calldataload(callDataPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                callDataPtr := add(callDataPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := shr(
                    mul(8, sub(32, byteLen)),
                    calldataload(callDataPtr)
                )
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                callDataPtr := add(callDataPtr, 1)

                let dataLen := shr(
                    mul(8, sub(32, byteLen)),
                    calldataload(callDataPtr)
                )
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 callDataPtr)
        private
        pure
        returns (uint256)
    {
        uint256 byte0;
        assembly {
            byte0 := byte(0, calldataload(callDataPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (
            byte0 < STRING_LONG_START ||
            (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)
        ) return 1;
        else if (byte0 < LIST_SHORT_START)
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IRootChainManager {
    function exit(bytes calldata inputData) external;

    function processExits(address token) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IPolygonPool {
    function stakeAndClaimBondsFor(address recepient, uint256 amount) external;

    function stakeAndClaimCertsFor(address recepient, uint256 amount) external;

    function stakeAndClaimBonds(uint256 amount) external;

    function stakeAndClaimCerts(uint256 amount) external;

    function unstakeBonds(
        uint256 amount,
        uint256 fee,
        uint256 useBeforeBlock,
        bytes memory signature
    ) external;

    function unstakeCerts(
        uint256 shares,
        uint256 fee,
        uint256 useBeforeBlock,
        bytes memory signature
    ) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

// Polygon ERC20Predicate contract that handles Plasma exits (only used for Matic).
interface IPolygonERC20Predicate {
    function startExitWithBurntTokens(bytes calldata data) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IMaticStaking {
    /**
     * Events
     */

    event StartExit(bytes data);

    event Staked(
        address indexed staker,
        uint256 amount,
        bool indexed isRebasing
    );

    event Unstaked(
        address indexed claimer,
        uint256 amount,
        bool indexed isRebasing,
        uint256 fee
    );

    event UnstakedAcrossToPolygon(address indexed operator, uint256 amount);

    event BondTokenChanged(address indexed bondToken);

    event CertTokenChanged(address indexed certToken);

    event AnkrTokenChanged(address indexed ankrToken);

    event PoolChanged(address indexed pool);

    event BridgeChanged(address indexed bridge);

    event DepositManagerChanged(address indexed depositManager);

    event MaticPredicateChanged(address indexed maticPredicate);

    event RootChainManagerChanged(address indexed rootChainManager);

    event OperatorChanged(address indexed operator);

    event ToChainChanged(uint256 indexed toChain);

    /**
     * Methods
     */

    function stake(
        address receiver,
        uint256 amount,
        bool isRebasing
    ) external;

    function startExit(bytes calldata data) external;

    // function delegateLast() external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IDepositManager {
    function depositERC20ForUser(
        address token,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

interface IBridge {
    struct Metadata {
        bytes32 symbol;
        bytes32 name;
        uint256 originChain;
        address originAddress;
        bytes32 bondMetadata; // encoded metadata version, bond type
    }

    function deposit(
        address fromToken,
        uint256 toChain,
        address toAddress,
        uint256 amount
    ) external;

    function withdraw(
        bytes calldata encodedProof,
        bytes calldata rawReceipt,
        bytes calldata receiptRootSignature
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

interface IBondToken {
    function mintBonds(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function pendingBurn(address account) external view returns (uint256);

    function burnAndSetPending(address account, uint256 amount) external;

    function burnAndSetPendingFor(
        address owner,
        address account,
        uint256 amount
    ) external;

    function updatePendingBurning(address account, uint256 amount) external;

    function ratio() external view returns (uint256);

    function lockShares(uint256 shares) external;

    function lockSharesFor(address account, uint256 shares) external;

    function lockForDelayedBurn(address account, uint256 amount) external;

    function commitDelayedBurn(address account, uint256 amount) external;

    function transferAndLockShares(address account, uint256 shares) external;

    function unlockShares(uint256 shares) external;

    function unlockSharesFor(address account, uint256 bonds) external;

    function totalSharesSupply() external view returns (uint256);

    function sharesToBonds(uint256 amount) external view returns (uint256);

    function bondsToShares(uint256 amount) external view returns (uint256);

    function isRebasing() external returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}