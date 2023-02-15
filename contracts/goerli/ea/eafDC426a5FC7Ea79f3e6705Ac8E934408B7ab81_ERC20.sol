// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./IERC20.sol";

import "evm-gateway-contract/contracts/ICrossTalkApplication.sol";
import "evm-gateway-contract/contracts/Utils.sol";
import "evm-gateway-contract/contracts/IGateway.sol";

contract ERC20 is IERC20, ICrossTalkApplication {
    // events for crosstalk
    event sent(
        address sender,
        address recipient,
        string _srcChainId,
        uint256 amount
    );
    event received(
        address sender,
        address recipient,
        string dstId,
        uint256 amount
    );

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Solidity by Example";
    string public symbol = "SOLBYEX";
    uint8 public decimals = 18;

    address owner;
    address public gatewayContract;
    uint64 public destGasLimit;
    mapping(uint64 => mapping(string => bytes)) public ourContractOnChains;

    constructor(
        address payable gatewayAddress,
        uint64 _destGasLimit,
        uint256 _initialSupply
    ) {
        gatewayContract = gatewayAddress;
        destGasLimit = _destGasLimit;
        owner = msg.sender;
        _mint(msg.sender, _initialSupply * 10 ** decimals);
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    // cross chain functions
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not owner");
        _;
    }

    /*
        mapping remote contract on src contract
    */
    function setContractOnChain(
        uint64 chainType,
        string memory chainId,
        address contractAddress
    ) external onlyOwner {
        ourContractOnChains[chainType][chainId] = toBytes(contractAddress);
    }

    function _mint(address recipient, uint256 amount) internal {
        balanceOf[recipient] += amount;
        totalSupply += amount;
    }

    function _burn(address sender, uint256 amount) internal {
        require(balanceOf[sender] >= amount, "Insufficient balance");
        balanceOf[sender] -= amount;
        totalSupply -= amount;
    }

    function transferCrossChain(
        uint64 _dstChainType,
        string memory _dstChainId, // it can be uint, why it is string?
        uint64 expiryTimestamp,
        uint64 destGasPrice,
        address recipient,
        uint256 amount
    ) public {
        bytes memory payload = abi.encode(amount, recipient, msg.sender);

        // burn token on src chain from msg.msg.sender
        _burn(msg.sender, amount);

        if (expiryTimestamp == 0) {
            expiryTimestamp = type(uint64).max;
        }

        bytes[] memory addresses = new bytes[](1);
        addresses[0] = ourContractOnChains[_dstChainType][_dstChainId];
        bytes[] memory payloads = new bytes[](1);
        payloads[0] = payload;

        IGateway(gatewayContract).requestToDest(
            Utils.RequestArgs(expiryTimestamp, false, Utils.FeePayer.USER),
            Utils.AckType(Utils.AckType.NO_ACK),
            Utils.AckGasParams(destGasLimit, destGasPrice),
            Utils.DestinationChainParams(
                destGasLimit,
                destGasPrice,
                _dstChainType,
                _dstChainId
            ),
            Utils.ContractCalls(payloads, addresses)
        );

        emit sent(msg.sender, recipient, _dstChainId, amount);
    }

    // mint amount to receipent
    function handleRequestFromSource(
        bytes memory srcContractAddress,
        bytes memory payload,
        string memory srcChainId,
        uint64 srcChainType
    ) external returns (bytes memory) {
        require(msg.sender == gatewayContract, "Caller is not gateway");
        require(
            keccak256(srcContractAddress) ==
                keccak256(ourContractOnChains[srcChainType][srcChainId]),
            "Invalid src chain"
        );
        (uint256 amount, address recipient, address sender) = abi.decode(
            payload,
            (uint256, address, address)
        );

        _mint(recipient, amount);

        emit received(sender, recipient, srcChainId, amount);
        return abi.encode(srcChainId, srcChainType);
    }

    function toBytes(address a) public pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    // without any ack
    function handleCrossTalkAck(
        uint64, // eventIdentifier
        bool[] memory, // execFlags
        bytes[] memory // execData
    ) external {}
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev CrossTalk flow Interface.
 */
interface ICrossTalkApplication {
    function handleRequestFromSource(
        bytes memory srcContractAddress,
        bytes memory payload,
        string memory srcChainId,
        uint64 srcChainType
    ) external returns (bytes memory);

    function handleCrossTalkAck(uint64 eventIdentifier, bool[] memory execFlags, bytes[] memory execData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Utils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    function requestToRouter(
        bytes memory payload,
        string memory routerBridgeContract,
        uint256 gasLimit,
        Utils.FeePayer feePayerEnum
    ) external returns (uint64);

    function executeHandlerCalls(
        string memory sender,
        bytes[] memory handlers,
        bytes[] memory payloads,
        bool isAtomic
    ) external returns (bool[] memory);

    function requestToDest(
        Utils.RequestArgs memory requestArgs,
        Utils.AckType ackType,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external payable returns (uint64);

    function readQueryToDest(
        Utils.RequestArgs memory requestArgs,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external payable returns (uint64);

    function requestToRouterDefaultFee() external view returns (uint256 fees);

    function requestToDestDefaultFee() external view returns (uint256 fees);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Utils {
    // This is used purely to avoid stack too deep errors
    // represents everything about a given validator set
    struct ValsetArgs {
        // the validators in this set, represented by an Ethereum address
        address[] validators;
        // the powers of the given validators in the same order as above
        uint64[] powers;
        // the nonce of this validator set
        uint64 valsetNonce;
    }

    // This is being used purely to avoid stack too deep errors
    struct RouterRequestPayload {
        // the sender address
        string routerBridgeAddress;
        string relayerRouterAddress;
        bool isAtomic;
        uint64 expTimestamp;
        // The user contract address
        bytes[] handlers;
        bytes[] payloads;
        uint64 outboundTxNonce;
    }

    struct AckGasParams {
        uint64 gasLimit;
        uint64 gasPrice;
    }

    struct SourceChainParams {
        uint64 crossTalkNonce;
        uint64 expTimestamp;
        bool isAtomicCalls;
        uint64 chainType;
        string chainId;
    }
    struct SourceParams {
        bytes caller;
        uint64 chainType;
        string chainId;
    }

    struct DestinationChainParams {
        uint64 gasLimit;
        uint64 gasPrice;
        uint64 destChainType;
        string destChainId;
    }

    struct RequestArgs {
        uint64 expTimestamp;
        bool isAtomicCalls;
        Utils.FeePayer feePayerEnum;
    }

    struct ContractCalls {
        bytes[] payloads;
        bytes[] destContractAddresses;
    }

    struct CrossTalkPayload {
        string relayerRouterAddress;
        bool isAtomic;
        uint64 eventIdentifier;
        uint64 expTimestamp;
        uint64 crossTalkNonce;
        SourceParams sourceParams;
        ContractCalls contractCalls;
        bool isReadCall;
    }

    struct CrossTalkAckPayload {
        string relayerRouterAddress;
        uint64 crossTalkNonce;
        uint64 eventIdentifier;
        uint64 destChainType;
        string destChainId;
        bytes srcContractAddress;
        bool[] execFlags;
        bytes[] execData;
    }

    // This represents a validator signature
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }

    enum FeePayer {
        APP,
        USER,
        NONE
    }

    error IncorrectCheckpoint();
    error InvalidValsetNonce(uint64 newNonce, uint64 currentNonce);
    error MalformedNewValidatorSet();
    error MalformedCurrentValidatorSet();
    error InsufficientPower(uint64 cumulativePower, uint64 powerThreshold);
    error InvalidSignature();
    // constants
    string constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint64 constant constantPowerThreshold = 2791728742;
}