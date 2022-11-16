// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

pragma solidity 0.8.13;

interface IBridge {
    function send(address _receiver, address _token, uint256 _amount, uint64 _dstChainId, uint64 _nonce, uint32 _maxSilippage) external;
    function sendNative(address _receiver, uint256 _amount, uint64 _dstChainId, uint64 _nonce, uint32 _maxSlippage) external payable ;
    function withdraw(bytes calldata _wdmsg, bytes[] memory _sigs, address[] memory _signers, uint256[] memory _powers) external;
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

// runtime proto sol library
library Pb {
    enum WireType {
        Varint,
        Fixed64,
        LengthDelim,
        StartGroup,
        EndGroup,
        Fixed32
    }

    struct Buffer {
        uint256 idx; // the start index of next read. when idx=b.length, we're done
        bytes b; // hold serialized proto msg, readonly
    }

    // create a new in-memory Buffer object from raw msg bytes
    function fromBytes(bytes memory raw) internal pure returns (Buffer memory buf) {
        buf.b = raw;
        buf.idx = 0;
    }

    // whether there are unread bytes
    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }

    // decode current field number and wiretype
    function decKey(Buffer memory buf) internal pure returns (uint256 tag, WireType wiretype) {
        uint256 v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }

    // count tag occurrences, return an array due to no memory map support
    // have to create array for (maxtag+1) size. cnts[tag] = occurrences
    // should keep buf.idx unchanged because this is only a count function
    function cntTags(Buffer memory buf, uint256 maxtag) internal pure returns (uint256[] memory cnts) {
        uint256 originalIdx = buf.idx;
        cnts = new uint256[](maxtag + 1); // protobuf's tags are from 1 rather than 0
        uint256 tag;
        WireType wire;
        while (hasMore(buf)) {
            (tag, wire) = decKey(buf);
            cnts[tag] += 1;
            skipValue(buf, wire);
        }
        buf.idx = originalIdx;
    }

    // read varint from current buf idx, move buf.idx to next read, return the int value
    function decVarint(Buffer memory buf) internal pure returns (uint256 v) {
        bytes10 tmp; // proto int is at most 10 bytes (7 bits can be used per byte)
        bytes memory bb = buf.b; // get buf.b mem addr to use in assembly
        v = buf.idx; // use v to save one additional uint variable
        assembly {
            tmp := mload(add(add(bb, 32), v)) // load 10 bytes from buf.b[buf.idx] to tmp
        }
        uint256 b; // store current byte content
        v = 0; // reset to 0 for return value
        for (uint256 i = 0; i < 10; i++) {
            assembly {
                b := byte(i, tmp) // don't use tmp[i] because it does bound check and costs extra
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert(); // i=10, invalid varint stream
    }

    // read length delimited field and return bytes
    function decBytes(Buffer memory buf) internal pure returns (bytes memory b) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        b = new bytes(len);
        bytes memory bufB = buf.b; // get buf.b mem addr to use in assembly
        uint256 bStart;
        uint256 bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint256 i = 0; i < len; i += 32) {
            assembly {
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }

    // return packed ints
    function decPacked(Buffer memory buf) internal pure returns (uint256[] memory t) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        // array in memory must be init w/ known length
        // so we have to create a tmp array w/ max possible len first
        uint256[] memory tmp = new uint256[](len);
        uint256 i = 0; // count how many ints are there
        while (buf.idx < end) {
            tmp[i] = decVarint(buf);
            i++;
        }
        t = new uint256[](i); // init t with correct length
        for (uint256 j = 0; j < i; j++) {
            t[j] = tmp[j];
        }
        return t;
    }

    // move idx pass current value field, to beginning of next tag or msg end
    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) {
            decVarint(buf);
        } else if (wire == WireType.LengthDelim) {
            uint256 len = decVarint(buf);
            buf.idx += len; // skip len bytes value data
            require(buf.idx <= buf.b.length); // avoid overflow
        } else {
            revert();
        } // unsupported wiretype
    }

    // type conversion help utils
    function _bool(uint256 x) internal pure returns (bool v) {
        return x != 0;
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32); // b's length must be smaller than or equal to 32
        assembly {
            v := mload(add(b, 32))
        } // load all 32bytes to v
        v = v >> (8 * (32 - b.length)); // only first b.length is valid
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(bytes memory b) internal pure returns (address payable v) {
        require(b.length == 20);
        //load 32bytes then shift right 12 bytes
        assembly {
            v := div(mload(add(b, 32)), 0x1000000000000000000000000)
        }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly {
            v := mload(add(b, 32))
        }
    }

    // uint[] to uint8[]
    function uint8s(uint256[] memory arr) internal pure returns (uint8[] memory t) {
        t = new uint8[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint8(arr[i]);
        }
    }

    function uint32s(uint256[] memory arr) internal pure returns (uint32[] memory t) {
        t = new uint32[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint32(arr[i]);
        }
    }

    function uint64s(uint256[] memory arr) internal pure returns (uint64[] memory t) {
        t = new uint64[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint64(arr[i]);
        }
    }

    function bools(uint256[] memory arr) internal pure returns (bool[] memory t) {
        t = new bool[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = arr[i] != 0;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: contracts/libraries/proto/pool.proto
pragma solidity 0.8.13;
import "./Pb.sol";

library PbPool {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct WithdrawMsg {
        uint64 chainid; // tag: 1
        uint64 seqnum; // tag: 2
        address receiver; // tag: 3
        address token; // tag: 4
        uint256 amount; // tag: 5
        bytes32 refid; // tag: 6
    } // end struct WithdrawMsg

    function decWithdrawMsg(bytes memory raw) internal pure returns (WithdrawMsg memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.chainid = uint64(buf.decVarint());
            } else if (tag == 2) {
                m.seqnum = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 6) {
                m.refid = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder WithdrawMsg
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IERC20.sol";
import "./libraries/PbPool.sol";



contract Vault is Ownable {


    struct SwapInfo {
                address dstToken;
                uint64 chainId;
                uint256 amount;
    }

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    struct BridgeDescription {
        address receiver;
        uint64 dstChainId; 
        uint64 nonce; 
        uint32 maxSlippage;
    }

    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);    

    address private immutable ROUTER;
    address private immutable BRIDGE;
    
    mapping(address => mapping(uint64 => SwapInfo)) public userSwapInfo;

    // returns (uint64 chainid, address token, uint256 amount)
    event with(uint64 id, address token, uint256 amount, uint64 wdmsgId, address wdmsgToken, uint256 wdmsgAmount);

    constructor(address router, address bridge) {
        ROUTER = router;
        BRIDGE = bridge;
    }

    function bridge( address _token, uint256 _amount, BridgeDescription calldata bDesc) external payable {
        bool isNotNative = !_isNative(IERC20(_token));

        if (isNotNative) {
            IERC20(_token).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
            IERC20(_token).approve(BRIDGE, _amount);

            IBridge(BRIDGE).send(bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        } else {
            IBridge(BRIDGE).sendNative{value:msg.value}(bDesc.receiver, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        }

        SwapInfo memory sif = userSwapInfo[msg.sender][bDesc.nonce];
        sif.dstToken = _token;
        sif.chainId = bDesc.dstChainId;
        sif.amount = _amount;
        userSwapInfo[msg.sender][bDesc.nonce] = sif;

    }

    function swap(uint minOut, bytes calldata _data) external payable {
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bool isNotNative = !_isNative(IERC20(desc.srcToken));

        if (isNotNative) {
        IERC20(desc.srcToken).transferFrom(msg.sender, address(this), desc.amount);
        IERC20(desc.srcToken).approve(ROUTER, desc.amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value : msg.value}(_data);
        if (succ) {
            (uint returnAmount, uint gasLeft) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);
        } else {
            revert();
        }
    }

    function uno(uint minOut, bytes calldata _data) external payable {
        (IERC20 srcToken, uint256 amount, uint256 b, bytes32[] memory c) = abi.decode(_data[4:], (IERC20, uint256, uint256, bytes32[]));

        bool isNotNative = !_isNative(srcToken);

        if (isNotNative) {
            srcToken.transferFrom(msg.sender, address(this), amount);
            srcToken.approve(ROUTER, amount);
        }
        

        (bool succ, bytes memory _data) = address(ROUTER).call{value : msg.value}(_data);
        if (succ) {
            (uint returnAmount) = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
        } else {
            revert();
        }
    }

    function v3swap(uint minOut, IERC20 srcToken, bytes calldata _data) external payable {
        ( uint256 amount, uint256 b, uint256[] memory c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));

        bool isNotNative = !_isNative(srcToken);
        if (isNotNative) {
            srcToken.transferFrom(msg.sender, address(this), amount);
            srcToken.approve(ROUTER, amount);   
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
        if (succ) {
            (uint returnAmount) = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
        } else {
            revert();
        }
    }

    function swapBridge(uint minOut, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bool isNotNative = !_isNative(IERC20(desc.srcToken));

        if (isNotNative) {
        IERC20(desc.srcToken).transferFrom(msg.sender, address(this), desc.amount);
        IERC20(desc.srcToken).approve(ROUTER, desc.amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            (uint returnAmount, ) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);
            isNotNative = !_isNative(IERC20(desc.dstToken));
            if (isNotNative) {
            IERC20(desc.dstToken).approve(BRIDGE, returnAmount);
            IBridge(BRIDGE).send(bDesc.receiver, address(desc.dstToken) , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            } else {
            IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            }

            SwapInfo memory sif = userSwapInfo[msg.sender][bDesc.nonce];
            require(sif.dstToken != address(0));
            sif.dstToken = address(desc.dstToken);
            sif.chainId = bDesc.dstChainId;
            sif.amount = returnAmount;
            userSwapInfo[msg.sender][bDesc.nonce] = sif;
            
            
        } 
        else {
            revert();
        }
    }

    function unoBridge(uint minOut,IERC20 toToken, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        (IERC20 srcToken, uint256 amount, uint256 b, bytes32[] memory c) = abi.decode(_data[4:], (IERC20, uint256, uint256, bytes32[]));

        bool isNotNative = !_isNative(srcToken);

        if (isNotNative) {
        srcToken.transferFrom(msg.sender, address(this), amount);
        srcToken.approve(ROUTER, amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            uint returnAmount = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            isNotNative = !_isNative(toToken);
            if (isNotNative) {
            toToken.approve(BRIDGE, returnAmount);
            IBridge(BRIDGE).send(bDesc.receiver, address(toToken) , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            } else {
            IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            }

            SwapInfo memory sif = userSwapInfo[msg.sender][bDesc.nonce];
            sif.dstToken = address(toToken);
            sif.chainId = bDesc.dstChainId;
            sif.amount = returnAmount;
            userSwapInfo[msg.sender][bDesc.nonce] = sif;
            
            
        } 
        else {
            revert();
        }
    }

    function v3Bridge(uint minOut,IERC20 fromToken, IERC20 toToken, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        ( uint256 amount, uint256 b, uint256[] memory c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));

        bool isNotNative = !_isNative(fromToken);

        if (isNotNative) {
        fromToken.transferFrom(msg.sender, address(this), amount);
        fromToken.approve(ROUTER, amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            uint returnAmount = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            isNotNative = !_isNative(toToken);
            if (isNotNative) {
            toToken.approve(BRIDGE, returnAmount);
            IBridge(BRIDGE).send(bDesc.receiver, address(toToken) , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            } else {
            IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            }

            SwapInfo memory sif = userSwapInfo[msg.sender][bDesc.nonce];
            sif.dstToken = address(toToken);
            sif.chainId = bDesc.dstChainId;
            sif.amount = returnAmount;
            userSwapInfo[msg.sender][bDesc.nonce] = sif;
            
            
        } 
        else {
            revert();
        }
    }

    function _isNative(IERC20 token_) internal pure returns (bool) {
        return (token_ == ETH_ADDRESS);
    }

    function _safeNativeTransfer(address to_, uint256 amount_) private {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe transfer fail");
    }     

    function withdraw(address _srcAddress, uint64 _nonce, bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external onlyOwner {
        SwapInfo memory sif = userSwapInfo[_srcAddress][_nonce];
        IBridge(BRIDGE).withdraw(_wdmsg,_sigs,_signers,_powers);
        IERC20(sif.dstToken).transfer(_srcAddress,sif.amount);
    }

    }