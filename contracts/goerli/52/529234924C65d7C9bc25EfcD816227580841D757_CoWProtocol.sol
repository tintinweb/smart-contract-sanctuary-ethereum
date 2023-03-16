// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity =0.8.19;

contract CoWProtocol {
    address immutable self;
    IGPv2Settlement immutable settlement;
    bytes32 immutable domainSeparator;
    IGPv2VaultRelayer immutable vaultRelayer;
    IWETH immutable weth;

    event OrderPlaced(
        address indexed owner,
        string note,
        bytes uid,
        GPv2Order.Data order
    );

    error NotDelegateCall();

    constructor(IGPv2Settlement settlement_, IWETH weth_) {
        self = address(this);
        settlement = settlement_;
        domainSeparator = settlement_.domainSeparator();
        vaultRelayer = settlement_.vaultRelayer();
        weth = weth_;
    }

    function placeOrder(
        IERC20 sellToken,
        IERC20 buyToken,
        address receiver,
        uint256 sellAmount,
        uint256 buyAmount,
        uint32 validity,
        bytes32 appData,
        uint256 feeAmount,
        string memory kind,
        bool partiallyFillable,
        string calldata note
    ) payable external returns (bytes memory uid) {
        // Make sure we are in a delegate call, this contract is not intended to
        // be used in any other way.
        if (address(this) == self) {
            revert NotDelegateCall();
        }

        // In order to support WETH without requiring an additional transaction,
        // accept a `value` with the order and wrap the received Ether.
        if (msg.value > 0) {
            weth.deposit{value: msg.value}();
        }

        // Compute the actual CoW Protocol order, based on the current block
        // timestamp and making sure to hash the string parameters.
        GPv2Order.Data memory order = GPv2Order.Data({
            sellToken: sellToken,
            buyToken: buyToken,
            receiver: receiver,
            sellAmount: sellAmount,
            buyAmount: buyAmount,
            validTo: validity & 1 == 0
                ? uint32(block.timestamp) + validity
                : validity ^ 1,
            appData: appData,
            feeAmount: feeAmount,
            kind: keccak256(bytes(kind)),
            partiallyFillable: partiallyFillable,
            sellTokenBalance: GPv2Order.BALANCE_ERC20,
            buyTokenBalance: GPv2Order.BALANCE_ERC20
        });

        // Make sure we have sufficient allowance. Note that we **only** set the
        // approval that is required and not unlimited, as many Safe users
        // prefer this behaviour anyway.
        uint256 requiredAllowance = order.sellAmount + order.feeAmount;
        if (requiredAllowance < order.sellToken.allowance(address(this), address(vaultRelayer))) {
            // Make sure to reset approval first as some tokens require this.
            order.sellToken.approve(address(vaultRelayer), 0);
            order.sellToken.approve(address(vaultRelayer), requiredAllowance);
        }

        // Compute the order UID.
        bytes32 digest = GPv2Order.hash(order, domainSeparator);
        uid = new bytes(GPv2Order.UID_LENGTH);
        GPv2Order.packOrderUidParams(uid, digest, address(this), order.validTo);

        // Place the order and emit a placement event.
        settlement.setPreSignature(uid, true);
        emit OrderPlaced(address(this), note, uid, order);
    }
}

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IGPv2VaultRelayer {}

interface IGPv2Settlement {
    function domainSeparator() external view returns (bytes32);
    function vaultRelayer() external view returns (IGPv2VaultRelayer);
    function setPreSignature(bytes calldata orderUid, bool signed) external;
}

interface IWETH {
    function deposit() external payable;
}

library GPv2Order {
    /// @dev The complete data for a Gnosis Protocol order. This struct contains
    /// all order parameters that are signed for submitting to GP.
    struct Data {
        IERC20 sellToken;
        IERC20 buyToken;
        address receiver;
        uint256 sellAmount;
        uint256 buyAmount;
        uint32 validTo;
        bytes32 appData;
        uint256 feeAmount;
        bytes32 kind;
        bool partiallyFillable;
        bytes32 sellTokenBalance;
        bytes32 buyTokenBalance;
    }

    /// @dev The order EIP-712 type hash for the [`GPv2Order.Data`] struct.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256(
    ///     "Order(" +
    ///         "address sellToken," +
    ///         "address buyToken," +
    ///         "address receiver," +
    ///         "uint256 sellAmount," +
    ///         "uint256 buyAmount," +
    ///         "uint32 validTo," +
    ///         "bytes32 appData," +
    ///         "uint256 feeAmount," +
    ///         "string kind," +
    ///         "bool partiallyFillable," +
    ///         "string sellTokenBalance," +
    ///         "string buyTokenBalance" +
    ///     ")"
    /// )
    /// ```
    bytes32 internal constant TYPE_HASH =
        hex"d5a25ba2e97094ad7d83dc28a6572da797d6b3e7fc6663bd93efb789fc17e489";

    /// @dev The marker value for a sell order for computing the order struct
    /// hash. This allows the EIP-712 compatible wallets to display a
    /// descriptive string for the order kind (instead of 0 or 1).
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("sell")
    /// ```
    bytes32 internal constant KIND_SELL =
        hex"f3b277728b3fee749481eb3e0b3b48980dbbab78658fc419025cb16eee346775";

    /// @dev The OrderKind marker value for a buy order for computing the order
    /// struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("buy")
    /// ```
    bytes32 internal constant KIND_BUY =
        hex"6ed88e868af0a1983e3886d5f3e95a2fafbd6c3450bc229e27342283dc429ccc";

    /// @dev The TokenBalance marker value for using direct ERC20 balances for
    /// computing the order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("erc20")
    /// ```
    bytes32 internal constant BALANCE_ERC20 =
        hex"5a28e9363bb942b639270062aa6bb295f434bcdfc42c97267bf003f272060dc9";

    /// @dev The TokenBalance marker value for using Balancer Vault external
    /// balances (in order to re-use Vault ERC20 approvals) for computing the
    /// order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("external")
    /// ```
    bytes32 internal constant BALANCE_EXTERNAL =
        hex"abee3b73373acd583a130924aad6dc38cfdc44ba0555ba94ce2ff63980ea0632";

    /// @dev The TokenBalance marker value for using Balancer Vault internal
    /// balances for computing the order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("internal")
    /// ```
    bytes32 internal constant BALANCE_INTERNAL =
        hex"4ac99ace14ee0a5ef932dc609df0943ab7ac16b7583634612f8dc35a4289a6ce";

    /// @dev Marker address used to indicate that the receiver of the trade
    /// proceeds should the owner of the order.
    ///
    /// This is chosen to be `address(0)` for gas efficiency as it is expected
    /// to be the most common case.
    address internal constant RECEIVER_SAME_AS_OWNER = address(0);

    /// @dev The byte length of an order unique identifier.
    uint256 internal constant UID_LENGTH = 56;

    /// @dev Returns the actual receiver for an order. This function checks
    /// whether or not the [`receiver`] field uses the marker value to indicate
    /// it is the same as the order owner.
    ///
    /// @return receiver The actual receiver of trade proceeds.
    function actualReceiver(Data memory order, address owner)
        internal
        pure
        returns (address receiver)
    {
        if (order.receiver == RECEIVER_SAME_AS_OWNER) {
            receiver = owner;
        } else {
            receiver = order.receiver;
        }
    }

    /// @dev Return the EIP-712 signing hash for the specified order.
    ///
    /// @param order The order to compute the EIP-712 signing hash for.
    /// @param domainSeparator The EIP-712 domain separator to use.
    /// @return orderDigest The 32 byte EIP-712 struct hash.
    function hash(Data memory order, bytes32 domainSeparator)
        internal
        pure
        returns (bytes32 orderDigest)
    {
        bytes32 structHash;

        // NOTE: Compute the EIP-712 order struct hash in place. As suggested
        // in the EIP proposal, noting that the order struct has 12 fields, and
        // prefixing the type hash `(1 + 12) * 32 = 416` bytes to hash.
        // <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-encodedata>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let dataStart := sub(order, 32)
            let temp := mload(dataStart)
            mstore(dataStart, TYPE_HASH)
            structHash := keccak256(dataStart, 416)
            mstore(dataStart, temp)
        }

        // NOTE: Now that we have the struct hash, compute the EIP-712 signing
        // hash using scratch memory past the free memory pointer. The signing
        // hash is computed from `"\x19\x01" || domainSeparator || structHash`.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory>
        // <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#specification>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            orderDigest := keccak256(freeMemoryPointer, 66)
        }
    }

    /// @dev Packs order UID parameters into the specified memory location. The
    /// result is equivalent to `abi.encodePacked(...)` with the difference that
    /// it allows re-using the memory for packing the order UID.
    ///
    /// This function reverts if the order UID buffer is not the correct size.
    ///
    /// @param orderUid The buffer pack the order UID parameters into.
    /// @param orderDigest The EIP-712 struct digest derived from the order
    /// parameters.
    /// @param owner The address of the user who owns this order.
    /// @param validTo The epoch time at which the order will stop being valid.
    function packOrderUidParams(
        bytes memory orderUid,
        bytes32 orderDigest,
        address owner,
        uint32 validTo
    ) internal pure {
        require(orderUid.length == UID_LENGTH, "GPv2: uid buffer overflow");

        // NOTE: Write the order UID to the allocated memory buffer. The order
        // parameters are written to memory in **reverse order** as memory
        // operations write 32-bytes at a time and we want to use a packed
        // encoding. This means, for example, that after writing the value of
        // `owner` to bytes `20:52`, writing the `orderDigest` to bytes `0:32`
        // will **overwrite** bytes `20:32`. This is desirable as addresses are
        // only 20 bytes and `20:32` should be `0`s:
        //
        //        |           1111111111222222222233333333334444444444555555
        //   byte | 01234567890123456789012345678901234567890123456789012345
        // -------+---------------------------------------------------------
        //  field | [.........orderDigest..........][......owner.......][vT]
        // -------+---------------------------------------------------------
        // mstore |                         [000000000000000000000000000.vT]
        //        |                     [00000000000.......owner.......]
        //        | [.........orderDigest..........]
        //
        // Additionally, since Solidity `bytes memory` are length prefixed,
        // 32 needs to be added to all the offsets.
        //
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(orderUid, 56), validTo)
            mstore(add(orderUid, 52), owner)
            mstore(add(orderUid, 32), orderDigest)
        }
    }

    /// @dev Extracts specific order information from the standardized unique
    /// order id of the protocol.
    ///
    /// @param orderUid The unique identifier used to represent an order in
    /// the protocol. This uid is the packed concatenation of the order digest,
    /// the validTo order parameter and the address of the user who created the
    /// order. It is used by the user to interface with the contract directly,
    /// and not by calls that are triggered by the solvers.
    /// @return orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @return owner The address of the user who owns this order.
    /// @return validTo The epoch time at which the order will stop being valid.
    function extractOrderUidParams(bytes calldata orderUid)
        internal
        pure
        returns (
            bytes32 orderDigest,
            address owner,
            uint32 validTo
        )
    {
        require(orderUid.length == UID_LENGTH, "GPv2: invalid uid");

        // Use assembly to efficiently decode packed calldata.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            orderDigest := calldataload(orderUid.offset)
            owner := shr(96, calldataload(add(orderUid.offset, 32)))
            validTo := shr(224, calldataload(add(orderUid.offset, 52)))
        }
    }
}