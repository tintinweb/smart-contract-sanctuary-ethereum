// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./exchange/Exchange.sol";

contract XCROWExchange is Exchange {
    string public constant name = "XCROW Exchange";

    string public constant version = "3.1";

    constructor(
        uint256 chainId,
        address[] memory registryAddrs,
        bytes memory customPersonalSignPrefix
    ) Exchange() {
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: name,
                version: version,
                chainId: chainId,
                verifyingContract: address(this)
            })
        );
        for (uint256 ind = 0; ind < registryAddrs.length; ind++) {
            registries[registryAddrs[ind]] = true;
        }
        if (customPersonalSignPrefix.length > 0) {
            personalSignPrefix = customPersonalSignPrefix;
        }
    }
}

// SPDX-License-Identifier: MIT
/*

  << Exchange >>

*/

pragma solidity ^0.8.14;

import "./ExchangeCore.sol";

contract Exchange is ExchangeCore {
    /* external ABI-encodable method wrappers. */

    constructor()ExchangeCore(){

    }
    
    function hashOrder_(
        address registry,
        address maker,
        address staticTarget,
        bytes4 staticSelector,
        bytes calldata staticExtradata,
        uint256 maximumFill,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt
    ) external pure returns (bytes32 hash) {
        return
            hashOrder(
                Order(
                    registry,
                    maker,
                    staticTarget,
                    staticSelector,
                    staticExtradata,
                    maximumFill,
                    listingTime,
                    expirationTime,
                    salt
                )
            );
    }

    function hashToSign_(bytes32 orderHash)
        external
        view
        returns (bytes32 hash)
    {
        return hashToSign(orderHash);
    }

    function validateOrderParameters_(
        address registry,
        address maker,
        address staticTarget,
        bytes4 staticSelector,
        bytes calldata staticExtradata,
        uint256 maximumFill,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt
    ) external view returns (bool) {
        Order memory order = Order(
            registry,
            maker,
            staticTarget,
            staticSelector,
            staticExtradata,
            maximumFill,
            listingTime,
            expirationTime,
            salt
        );
        return validateOrderParameters(order, hashOrder(order));
    }

    function validateOrderAuthorization_(
        bytes32 hash,
        address maker,
        bytes calldata signature
    ) external view returns (bool) {
        return validateOrderAuthorization(hash, maker, signature);
    }

    function approveOrderHash_(bytes32 hash) external {
        return approveOrderHash(hash);
    }

    function approveOrder_(
        address registry,
        address maker,
        address staticTarget,
        bytes4 staticSelector,
        bytes calldata staticExtradata,
        uint256 maximumFill,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt,
        bool orderbookInclusionDesired
    ) external {
        return
            approveOrder(
                Order(
                    registry,
                    maker,
                    staticTarget,
                    staticSelector,
                    staticExtradata,
                    maximumFill,
                    listingTime,
                    expirationTime,
                    salt
                ),
                orderbookInclusionDesired
            );
    }

    function setOrderFill_(bytes32 hash, uint256 fill) external {
        return setOrderFill(hash, fill);
    }

    function atomicMatch_(
        uint256[16] memory uints,
        bytes4[2] memory staticSelectors,
        bytes memory firstExtradata,
        bytes memory firstCalldata,
        bytes memory secondExtradata,
        bytes memory secondCalldata,
        uint8[2] memory howToCalls,
        bytes32 metadata,
        bytes memory signatures
    ) public payable {
        return
            atomicMatch(
                Order(
                    address(uint160(uints[0])),
                    address(uint160(uints[1])),
                    address(uint160(uints[2])),
                    staticSelectors[0],
                    firstExtradata,
                    uints[3],
                    uints[4],
                    uints[5],
                    uints[6]
                ),
                Call(
                    address(uint160(uints[7])),
                    ExchangeCore.HowToCall(howToCalls[0]),
                    firstCalldata
                ),
                Order(
                    address(uint160(uints[8])),
                    address(uint160(uints[9])),
                    address(uint160(uints[10])),
                    staticSelectors[1],
                    secondExtradata,
                    uints[11],
                    uints[12],
                    uints[13],
                    uints[14]
                ),
                Call(
                    address(uint160(uints[15])),
                    ExchangeCore.HowToCall(howToCalls[1]),
                    secondCalldata
                ),
                signatures,
                metadata
            );
    }
}

// SPDX-License-Identifier: MIT
/*

  << Exchange Core >>

*/

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/StaticCaller.sol";
import "../lib/ReentrancyGuarded.sol";
import "../lib/EIP712.sol";
import "../lib/EIP1271.sol";

contract ExchangeCore is ReentrancyGuarded, StaticCaller, EIP712 {
    bytes4 internal constant EIP_1271_MAGICVALUE = 0x20c13b0b;
    bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";

    enum HowToCall {
        Call,
        DelegateCall
    }
    /* Struct definitions. */

    /* An order, convenience struct. */
    struct Order {
        /* Order registry address. */
        address registry;
        /* Order maker address. */
        address maker;
        /* Order static target. */
        address staticTarget;
        /* Order static selector. */
        bytes4 staticSelector;
        /* Order static extradata. */
        bytes staticExtradata;
        /* Order maximum fill factor. */
        uint256 maximumFill;
        /* Order listing timestamp. */
        uint256 listingTime;
        /* Order expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt to prevent duplicate hashes. */
        uint256 salt;
    }

    /* A call, convenience struct. */
    struct Call {
        /* Target */
        address target;
        /* How to call */
        HowToCall howToCall;
        /* Calldata */
        bytes data;
    }

    /* Constants */
    // AuthenticatedProxy proxy;
    /* Order typehash for EIP 712 compatibility. */
    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "Order(address registry,address maker,address staticTarget,bytes4 staticSelector,bytes staticExtradata,uint256 maximumFill,uint256 listingTime,uint256 expirationTime,uint256 salt)"
        );

    /* Variables */

    /* Trusted proxy registry contracts. */
    mapping(address => bool) public registries;

    /* Order fill status, by maker address then by hash. */
    mapping(address => mapping(bytes32 => uint256)) public fills;

    /* Orders verified by on-chain approval.
       Alternative to ECDSA signatures so that smart contracts can place orders directly.
       By maker address, then by hash. */
    mapping(address => mapping(bytes32 => bool)) public approved;

    /* Events */

    event OrderApproved(
        bytes32 indexed hash,
        address registry,
        address indexed maker,
        address staticTarget,
        bytes4 staticSelector,
        bytes staticExtradata,
        uint256 maximumFill,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt,
        bool orderbookInclusionDesired
    );
    event OrderFillChanged(
        bytes32 indexed hash,
        address indexed maker,
        uint256 newFill
    );
    event OrdersMatched(
        bytes32 firstHash,
        bytes32 secondHash,
        address indexed firstMaker,
        address indexed secondMaker,
        uint256 newFirstFill,
        uint256 newSecondFill,
        bytes32 indexed metadata
    );

    constructor(/*address _authenticatedProxy*/) {
       // proxy = AuthenticatedProxy(payable(address(_authenticatedProxy)));
    }

    /* Functions */

    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Per EIP 712. */
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.registry,
                    order.maker,
                    order.staticTarget,
                    order.staticSelector,
                    keccak256(order.staticExtradata),
                    order.maximumFill,
                    order.listingTime,
                    order.expirationTime,
                    order.salt
                )
            );
    }

    function hashToSign(bytes32 orderHash)
        internal
        view
        returns (bytes32 hash)
    {
        /* Calculate the string a user must sign. */
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash)
            );
    }

    function exists(address what) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(what)
        }
        return size > 0;
    }

    function validateOrderParameters(Order memory order, bytes32 hash)
        internal
        view
        returns (bool)
    {
        /* Order must be listed and not be expired. */
        if (
            order.listingTime > block.timestamp ||
            (order.expirationTime != 0 &&
                order.expirationTime <= block.timestamp)
        ) {
            return false;
        }

        /* Order must not have already been completely filled. */
        if (fills[order.maker][hash] >= order.maximumFill) {
            return false;
        }

        /* Order static target must exist. */
        if (!exists(order.staticTarget)) {
            return false;
        }

        return true;
    }

    function validateOrderAuthorization(
        bytes32 hash,
        address maker,
        bytes memory signature
    ) internal view returns (bool) {
        /* Memoized authentication. If order has already been partially filled, order must be authenticated. */
        if (fills[maker][hash] > 0) {
            return true;
        }

        /* Order authentication. Order must be either: */

        /* (a): sent by maker */
        if (maker == msg.sender) {
            return true;
        }

        /* (b): previously approved */
        if (approved[maker][hash]) {
            return true;
        }

        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(hash);

        /* Determine whether signer is a contract or account. */
        bool isContract = exists(maker);

        /* (c): Contract-only authentication: EIP/ERC 1271. */
        if (isContract) {
            if (
                ERC1271(maker).isValidSignature(
                    abi.encodePacked(calculatedHashToSign),
                    signature
                ) == EIP_1271_MAGICVALUE
            ) {
                return true;
            }
            return false;
        }

        /* (d): Account-only authentication: ECDSA-signed by maker. */
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(
            signature,
            (uint8, bytes32, bytes32)
        );

        address isMaker = ecrecover(
            keccak256(
                abi.encodePacked(personalSignPrefix, "32", calculatedHashToSign)
            ),
            v,
            r,
            s
        );

        if (isMaker == maker) {
            // EthSign byte
            /* (d.1): Old way: order hash signed by maker using the prefixed personal_sign */
            return true;
        }
        // /* (d.2): New way: order hash signed by maker using sign_typed_data */
        // else if (ecrecover(calculatedHashToSign, v, r, s) == maker) {
        //     return true;
        // }
        return false;
    }

    function encodeStaticCall(
        Order memory order,
        Call memory call,
        Order memory counterorder,
        Call memory countercall,
        address matcher,
        uint256 value,
        uint256 fill
    ) internal pure returns (bytes memory) {
        /* This array wrapping is necessary to preserve static call target function stack space. */
        address[7] memory addresses = [
            order.registry,
            order.maker,
            call.target,
            counterorder.registry,
            counterorder.maker,
            countercall.target,
            matcher
        ];
        HowToCall[2] memory howToCalls = [
            call.howToCall,
            countercall.howToCall
        ];
        uint256[6] memory uints = [
            value,
            order.maximumFill,
            order.listingTime,
            order.expirationTime,
            counterorder.listingTime,
            fill
        ];
        return
            abi.encodeWithSelector(
                order.staticSelector,
                order.staticExtradata,
                addresses,
                howToCalls,
                uints,
                call.data,
                countercall.data
            );
    }

    function executeStaticCall(
        Order memory order,
        Call memory call,
        Order memory counterorder,
        Call memory countercall,
        address matcher,
        uint256 value,
        uint256 fill
    ) internal view returns (uint256) {
        return
            staticCallUint(
                order.staticTarget,
                encodeStaticCall(
                    order,
                    call,
                    counterorder,
                    countercall,
                    matcher,
                    value,
                    fill
                )
            );
    }

    function executeCall(Call memory call) internal returns (bool) {
        // /* Assert valid registry. */
        // require(registries[address(registry)]);

        /* Assert target exists. */
        require(exists(call.target), "Call target does not exist");

        // /* Retrieve delegate proxy contract. */
        // OwnableDelegateProxy delegateProxy = registry.proxies((maker));

        // /* Assert existence. */
        // require(
        //     address(delegateProxy) != address(0),
        //     "Delegate proxy does not exist for maker"
        // );

        /* Assert implementation. */
        // require(
        //     delegateProxy.implementation() ==
        //         registry.delegateProxyImplementation(),
        //     "Incorrect delegate proxy implementation for maker"
        // );

        /* Typecast. */

        // AuthenticatedProxy proxy = AuthenticatedProxy(
        //     payable(address(delegateProxy))
        // );

        /* Execute order. */
        return _proxy(call.target, call.howToCall, call.data);
    }

    function approveOrderHash(bytes32 hash) internal {
        /* CHECKS */

        /* Assert order has not already been approved. */
        require(!approved[msg.sender][hash], "Order has already been approved");

        /* EFFECTS */

        /* Mark order as approved. */
        approved[msg.sender][hash] = true;
    }

    function approveOrder(Order memory order, bool orderbookInclusionDesired)
        internal
    {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(
            order.maker == msg.sender,
            "Sender is not the maker of the order and thus not authorized to approve it"
        );

        /* Calculate order hash. */
        bytes32 hash = hashOrder(order);

        /* Approve order hash. */
        approveOrderHash(hash);

        /* Log approval event. */
        emit OrderApproved(
            hash,
            order.registry,
            order.maker,
            order.staticTarget,
            order.staticSelector,
            order.staticExtradata,
            order.maximumFill,
            order.listingTime,
            order.expirationTime,
            order.salt,
            orderbookInclusionDesired
        );
    }

    function setOrderFill(bytes32 hash, uint256 fill) internal {
        /* CHECKS */

        /* Assert fill is not already set. */
        require(
            fills[msg.sender][hash] != fill,
            "Fill is already set to the desired value"
        );

        /* EFFECTS */

        /* Mark order as accordingly filled. */
        fills[msg.sender][hash] = fill;

        /* Log order fill change event. */
        emit OrderFillChanged(hash, msg.sender, fill);
    }

    function atomicMatch(
        Order memory firstOrder,
        Call memory firstCall,
        Order memory secondOrder,
        Call memory secondCall,
        bytes memory signatures,
        bytes32 metadata
    ) internal reentrancyGuard {
        /* CHECKS */

        /* Calculate first order hash. */
        bytes32 firstHash = hashOrder(firstOrder);

        /* Check first order validity. */
        require(
            validateOrderParameters(firstOrder, firstHash),
            "First order has invalid parameters"
        );

        /* Calculate second order hash. */
        bytes32 secondHash = hashOrder(secondOrder);

        /* Check second order validity. */
        require(
            validateOrderParameters(secondOrder, secondHash),
            "Second order has invalid parameters"
        );

        /* Prevent self-matching (possibly unnecessary, but safer). */
        require(firstHash != secondHash, "Self-matching orders is prohibited");

        {
            /* Calculate signatures (must be awkwardly decoded here due to stack size constraints). */
            (bytes memory firstSignature, bytes memory secondSignature) = abi
                .decode(signatures, (bytes, bytes));

            /* Check first order authorization. */
            require(
                validateOrderAuthorization(
                    firstHash,
                    firstOrder.maker,
                    firstSignature
                ),
                "First order failed authorization"
            );

            /* Check second order authorization. */
            require(
                validateOrderAuthorization(
                    secondHash,
                    secondOrder.maker,
                    secondSignature
                ),
                "Second order failed authorization"
            );
        }

        /* INTERACTIONS */

        /* Transfer any msg.value.
           This is the first "asymmetric" part of order matching: if an order requires Ether, it must be the first order. */
        if (msg.value > 0) {
            payable(address(uint160(firstOrder.maker))).transfer(msg.value);
        }
        /* Execute first call, assert success.
           This is the second "asymmetric" part of order matching: execution of the second order can depend on state changes in the first order, but not vice-versa. */
        require(executeCall(firstCall), "First call failed");

        /* Execute second call, assert success. */
        require(executeCall(secondCall), "Second call failed");

        /* Static calls must happen after the effectful calls so that they can check the resulting state. */

        /* Fetch previous first order fill. */
        uint256 previousFirstFill = fills[firstOrder.maker][firstHash];

        /* Fetch previous second order fill. */
        uint256 previousSecondFill = fills[secondOrder.maker][secondHash];

        /* Execute first order static call, assert success, capture returned new fill. */
        uint256 firstFill = executeStaticCall(
            firstOrder,
            firstCall,
            secondOrder,
            secondCall,
            msg.sender,
            msg.value,
            previousFirstFill
        );

        /* Execute second order static call, assert success, capture returned new fill. */
        uint256 secondFill = executeStaticCall(
            secondOrder,
            secondCall,
            firstOrder,
            firstCall,
            msg.sender,
            uint256(0),
            previousSecondFill
        );

        /* EFFECTS */

        /* Update first order fill, if necessary. */
        if (firstOrder.maker != msg.sender) {
            if (firstFill != previousFirstFill) {
                fills[firstOrder.maker][firstHash] = firstFill;
            }
        }

        /* Update second order fill, if necessary. */
        if (secondOrder.maker != msg.sender) {
            if (secondFill != previousSecondFill) {
                fills[secondOrder.maker][secondHash] = secondFill;
            }
        }

        /* LOGS */

        /* Log match event. */
        emit OrdersMatched(
            firstHash,
            secondHash,
            firstOrder.maker,
            secondOrder.maker,
            firstFill,
            secondFill,
            metadata
        );
    }

    function _proxy(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) internal returns (bool result) {
        bytes memory ret;
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
        return result;
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
/*

  << Static Caller >>

*/

pragma solidity ^0.8.14;

contract StaticCaller {
    function staticCall(address target, bytes memory data)
        internal
        view
        returns (bool result)
    {
        assembly {
            result := staticcall(
                gas(),
                target,
                add(data, 0x20),
                mload(data),
                mload(0x40),
                0
            )
        }
        return result;
    }

    function staticCallUint(address target, bytes memory data)
        internal
        view
        returns (uint256 ret)
    {
        bool result;
        assembly {
            let size := 0x20
            let free := mload(0x40)
            result := staticcall(
                gas(),
                target,
                add(data, 0x20),
                mload(data),
                free,
                size
            )
            ret := mload(free)
        }
        require(result, "Static call failed");
        return ret;
    }
}

// SPDX-License-Identifier: MIT
/*

  Simple contract extension to provide a contract-global reentrancy guard on functions.

*/

pragma solidity ^0.8.14;

contract ReentrancyGuarded {
    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        require(!reentrancyLock, "Reentrancy detected");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}

// SPDX-License-Identifier: MIT
/*

  << EIP 712 >>

*/

pragma solidity ^0.8.14;

contract EIP712 {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 DOMAIN_SEPARATOR;

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }
}

// SPDX-License-Identifier: MIT
/*

  << EIP 1271 >>

*/

pragma solidity ^0.8.14;

abstract contract ERC1271 {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant MAGICVALUE = 0x20c13b0b;

    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature)
        public
        view
        virtual
        returns (bytes4 magicValue);
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