// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libraries/BridgeTransferLib.sol";
import "../safeguard/Ownable.sol";

/**
 * @title Transfer agent. Designed to support arbitrary length receiver address for transfer. Supports the liquidity pool-based {Bridge}, the {OriginalTokenVault} for pegged
 * deposit and the {PeggedTokenBridge} for pegged burn.
 */
contract TransferAgent is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct Extension {
        uint8 Type;
        bytes Value;
    }

    mapping(BridgeTransferLib.BridgeSendType => address) public bridges;

    event Supplement(
        BridgeTransferLib.BridgeSendType bridgeSendType,
        bytes32 transferId,
        address sender,
        bytes receiver,
        Extension[] extensions
    );
    event BridgeUpdated(BridgeTransferLib.BridgeSendType bridgeSendType, address bridgeAddr);

    /**
     * @notice Send a cross-chain transfer of ERC20 token either via liquidity pool-based bridge or in form of mint/burn.
     * @param _receiver The address of the receiver.
     * @param _token The address of the token.
     * @param _amount The amount of the transfer.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least
     *        (100% - max slippage percentage) * amount or the transfer can be refunded.
     *        Only applicable to the {BridgeSendType.Liquidity}.
     * @param _bridgeSendType The type of bridge used by this transfer. One of the {BridgeSendType} enum.
     * @param _extensions A list of extension to be processed by agent, is designed to be used for extending
     *        present transfer. Contact Celer team to learn about already supported type of extension.
     */
    function transfer(
        bytes calldata _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage, // slippage * 1M, eg. 0.5% -> 5000
        BridgeTransferLib.BridgeSendType _bridgeSendType,
        Extension[] calldata _extensions
    ) external nonReentrant returns (bytes32) {
        bytes32 transferId;
        {
            address _bridgeAddr = bridges[_bridgeSendType];
            require(_bridgeAddr != address(0), "unknown bridge type");
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            transferId = BridgeTransferLib.sendTransfer(
                address(0),
                _token,
                _amount,
                _dstChainId,
                _nonce,
                _maxSlippage,
                _bridgeSendType,
                _bridgeAddr
            );
        }
        emit Supplement(_bridgeSendType, transferId, msg.sender, _receiver, _extensions);
        return transferId;
    }

    /**
     * @notice Send a cross-chain transfer of native token either via liquidity pool-based bridge or in form of mint/burn.
     * @param _receiver The address of the receiver.
     * @param _amount The amount of the transfer.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least
     *        (100% - max slippage percentage) * amount or the transfer can be refunded.
     *        Only applicable to the {BridgeSendType.Liquidity}.
     * @param _bridgeSendType The type of bridge used by this transfer. One of the {BridgeSendType} enum.
     * @param _extensions A list of extension to be processed by agent, is designed to be used for extending
     *        present transfer. Contact Celer team to learn about already supported type of extension.
     */
    function transferNative(
        bytes calldata _receiver,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage, // slippage * 1M, eg. 0.5% -> 5000
        BridgeTransferLib.BridgeSendType _bridgeSendType,
        Extension[] calldata _extensions
    ) external payable nonReentrant returns (bytes32) {
        bytes32 transferId;
        {
            address _bridgeAddr = bridges[_bridgeSendType];
            require(_bridgeAddr != address(0), "unknown bridge type");
            require(msg.value == _amount, "amount mismatch");
            transferId = BridgeTransferLib.sendNativeTransfer(
                address(0),
                _amount,
                _dstChainId,
                _nonce,
                _maxSlippage,
                _bridgeSendType,
                _bridgeAddr
            );
        }
        emit Supplement(_bridgeSendType, transferId, msg.sender, _receiver, _extensions);
        return transferId;
    }

    // ----------------------Admin operation-----------------------

    function setBridgeAddress(BridgeTransferLib.BridgeSendType _bridgeSendType, address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        bridges[_bridgeSendType] = _addr;
        emit BridgeUpdated(_bridgeSendType, _addr);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./PbBridge.sol";
import "./PbPegged.sol";
import "./PbPool.sol";
import "../interfaces/IBridge.sol";
import "../interfaces/IOriginalTokenVault.sol";
import "../interfaces/IOriginalTokenVaultV2.sol";
import "../interfaces/IPeggedTokenBridge.sol";
import "../interfaces/IPeggedTokenBridgeV2.sol";

interface INativeWrap {
    function nativeWrap() external view returns (address);
}

library BridgeTransferLib {
    using SafeERC20 for IERC20;

    enum BridgeSendType {
        Null,
        Liquidity,
        PegDeposit,
        PegBurn,
        PegV2Deposit,
        PegV2Burn,
        PegV2BurnFrom
    }

    enum BridgeReceiveType {
        Null,
        LqRelay,
        LqWithdraw,
        PegMint,
        PegWithdraw,
        PegV2Mint,
        PegV2Withdraw
    }

    struct ReceiveInfo {
        bytes32 transferId;
        address receiver;
        address token; // 0 address for native token
        uint256 amount;
        bytes32 refid; // reference id, e.g., srcTransferId for refund
    }

    // ============== Internal library functions called by apps ==============

    /**
     * @notice Send a cross-chain transfer of ERC20 token either via liquidity pool-based bridge or in the form of pegged mint / burn.
     * @param _receiver The address of the receiver.
     * @param _token The address of the token.
     * @param _amount The amount of the transfer.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least
     *        (100% - max slippage percentage) * amount or the transfer can be refunded.
     *        Only applicable to the {BridgeSendType.Liquidity}.
     * @param _bridgeSendType The type of the bridge used by this transfer. One of the {BridgeSendType} enum.
     * @param _bridgeAddr The address of the bridge used.
     */
    function sendTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage, // slippage * 1M, eg. 0.5% -> 5000
        BridgeSendType _bridgeSendType,
        address _bridgeAddr
    ) internal returns (bytes32) {
        bytes32 transferId;
        IERC20(_token).safeIncreaseAllowance(_bridgeAddr, _amount);
        if (_bridgeSendType == BridgeSendType.Liquidity) {
            IBridge(_bridgeAddr).send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
            transferId = keccak256(
                abi.encodePacked(address(this), _receiver, _token, _amount, _dstChainId, _nonce, uint64(block.chainid))
            );
        } else if (_bridgeSendType == BridgeSendType.PegDeposit) {
            IOriginalTokenVault(_bridgeAddr).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
            transferId = keccak256(
                abi.encodePacked(address(this), _token, _amount, _dstChainId, _receiver, _nonce, uint64(block.chainid))
            );
        } else if (_bridgeSendType == BridgeSendType.PegBurn) {
            IPeggedTokenBridge(_bridgeAddr).burn(_token, _amount, _receiver, _nonce);
            transferId = keccak256(
                abi.encodePacked(address(this), _token, _amount, _receiver, _nonce, uint64(block.chainid))
            );
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridgeAddr, 0);
        } else if (_bridgeSendType == BridgeSendType.PegV2Deposit) {
            transferId = IOriginalTokenVaultV2(_bridgeAddr).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
        } else if (_bridgeSendType == BridgeSendType.PegV2Burn) {
            transferId = IPeggedTokenBridgeV2(_bridgeAddr).burn(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridgeAddr, 0);
        } else if (_bridgeSendType == BridgeSendType.PegV2BurnFrom) {
            transferId = IPeggedTokenBridgeV2(_bridgeAddr).burnFrom(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridgeAddr, 0);
        } else {
            revert("bridge send type not supported");
        }
        return transferId;
    }

    /**
     * @notice Send a cross-chain transfer of native token either via liquidity pool-based bridge or in the form of pegged mint / burn.
     * @param _receiver The address of the receiver.
     * @param _amount The amount of the transfer.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least
     *        (100% - max slippage percentage) * amount or the transfer can be refunded.
     *        Only applicable to the {BridgeSendType.Liquidity}.
     * @param _bridgeSendType The type of the bridge used by this transfer. One of the {BridgeSendType} enum.
     * @param _bridgeAddr The address of the bridge used.
     */
    function sendNativeTransfer(
        address _receiver,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage, // slippage * 1M, eg. 0.5% -> 5000
        BridgeSendType _bridgeSendType,
        address _bridgeAddr
    ) internal returns (bytes32) {
        require(_bridgeSendType == BridgeSendType.Liquidity || _bridgeSendType == BridgeSendType.PegDeposit || _bridgeSendType == BridgeSendType.PegV2Deposit, "Lib: invalid bridge send type");
        address _token = INativeWrap(_bridgeAddr).nativeWrap();
        bytes32 transferId;
        if (_bridgeSendType == BridgeSendType.Liquidity) {
            IBridge(_bridgeAddr).sendNative{value: msg.value}(_receiver, _amount, _dstChainId, _nonce, _maxSlippage);
            transferId = keccak256(
                abi.encodePacked(address(this), _receiver, _token, _amount, _dstChainId, _nonce, uint64(block.chainid))
            );
        } else if (_bridgeSendType == BridgeSendType.PegDeposit) {
            IOriginalTokenVault(_bridgeAddr).depositNative{value: msg.value}(_amount, _dstChainId, _receiver, _nonce);
            transferId = keccak256(
                abi.encodePacked(address(this), _token, _amount, _dstChainId, _receiver, _nonce, uint64(block.chainid))
            );
        } else {
            // _bridgeSendType == BridgeSendType.PegV2Deposit
            transferId = IOriginalTokenVaultV2(_bridgeAddr).depositNative{value: msg.value}(_amount, _dstChainId, _receiver, _nonce);
        }
        return transferId;
    }

    /**
     * @notice Receive a cross-chain transfer.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeReceiveType The type of the received transfer. One of the {BridgeReceiveType} enum.
     * @param _bridgeAddr The address of the bridge used.
     */
    function receiveTransfer(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        BridgeReceiveType _bridgeReceiveType,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        if (_bridgeReceiveType == BridgeReceiveType.LqRelay) {
            return receiveLiquidityRelay(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else if (_bridgeReceiveType == BridgeReceiveType.LqWithdraw) {
            return receiveLiquidityWithdraw(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else if (_bridgeReceiveType == BridgeReceiveType.PegWithdraw) {
            return receivePegWithdraw(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else if (_bridgeReceiveType == BridgeReceiveType.PegMint) {
            return receivePegMint(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else if (_bridgeReceiveType == BridgeReceiveType.PegV2Withdraw) {
            return receivePegV2Withdraw(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else if (_bridgeReceiveType == BridgeReceiveType.PegV2Mint) {
            return receivePegV2Mint(_request, _sigs, _signers, _powers, _bridgeAddr);
        } else {
            revert("bridge receive type not supported");
        }
    }

    /**
     * @notice Receive a liquidity bridge relay.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of liquidity bridge.
     */
    function receiveLiquidityRelay(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbBridge.Relay memory request = PbBridge.decRelay(_request);
        recv.transferId = keccak256(
            abi.encodePacked(
                request.sender,
                request.receiver,
                request.token,
                request.amount,
                request.srcChainId,
                uint64(block.chainid),
                request.srcTransferId
            )
        );
        recv.refid = request.srcTransferId;
        recv.receiver = request.receiver;
        recv.token = request.token;
        recv.amount = request.amount;
        if (!IBridge(_bridgeAddr).transfers(recv.transferId)) {
            IBridge(_bridgeAddr).relay(_request, _sigs, _signers, _powers);
        }
        return recv;
    }

    /**
     * @notice Receive a liquidity bridge withdrawal.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of liquidity bridge.
     */
    function receiveLiquidityWithdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbPool.WithdrawMsg memory request = PbPool.decWithdrawMsg(_request);
        recv.transferId = keccak256(
            abi.encodePacked(request.chainid, request.seqnum, request.receiver, request.token, request.amount)
        );
        recv.refid = request.refid;
        recv.receiver = request.receiver;
        if (INativeWrap(_bridgeAddr).nativeWrap() == request.token) {
            recv.token = address(0);
        } else {
            recv.token = request.token;
        }
        recv.amount = request.amount;
        if (!IBridge(_bridgeAddr).withdraws(recv.transferId)) {
            IBridge(_bridgeAddr).withdraw(_request, _sigs, _signers, _powers);
        }
        return recv;
    }

    /**
     * @notice Receive an OriginalTokenVault withdrawal.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of OriginalTokenVault.
     */
    function receivePegWithdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbPegged.Withdraw memory request = PbPegged.decWithdraw(_request);
        recv.transferId = keccak256(
            abi.encodePacked(
                request.receiver,
                request.token,
                request.amount,
                request.burnAccount,
                request.refChainId,
                request.refId
            )
        );
        recv.refid = request.refId;
        recv.receiver = request.receiver;
        if (INativeWrap(_bridgeAddr).nativeWrap() == request.token) {
            recv.token = address(0);
        } else {
            recv.token = request.token;
        }
        recv.amount = request.amount;
        if (!IOriginalTokenVault(_bridgeAddr).records(recv.transferId)) {
            IOriginalTokenVault(_bridgeAddr).withdraw(_request, _sigs, _signers, _powers);
        }
        return recv;
    }

    /**
     * @notice Receive a PeggedTokenBridge mint.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of PeggedTokenBridge.
     */
    function receivePegMint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbPegged.Mint memory request = PbPegged.decMint(_request);
        recv.transferId = keccak256(
            abi.encodePacked(
                request.account,
                request.token,
                request.amount,
                request.depositor,
                request.refChainId,
                request.refId
            )
        );
        recv.refid = request.refId;
        recv.receiver = request.account;
        recv.token = request.token;
        recv.amount = request.amount;
        if (!IPeggedTokenBridge(_bridgeAddr).records(recv.transferId)) {
            IPeggedTokenBridge(_bridgeAddr).mint(_request, _sigs, _signers, _powers);
        }
        return recv;
    }

    /**
     * @notice Receive an OriginalTokenVaultV2 withdrawal.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A request must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of OriginalTokenVaultV2.
     */
    function receivePegV2Withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbPegged.Withdraw memory request = PbPegged.decWithdraw(_request);
        if (IOriginalTokenVaultV2(_bridgeAddr).records(request.refId)) {
            recv.transferId = keccak256(
                abi.encodePacked(
                    request.receiver,
                    request.token,
                    request.amount,
                    request.burnAccount,
                    request.refChainId,
                    request.refId,
                    _bridgeAddr
                )
            );
        } else {
            recv.transferId = IOriginalTokenVaultV2(_bridgeAddr).withdraw(_request, _sigs, _signers, _powers);
        }
        recv.refid = request.refId;
        recv.receiver = request.receiver;
        if (INativeWrap(_bridgeAddr).nativeWrap() == request.token) {
            recv.token = address(0);
        } else {
            recv.token = request.token;
        }
        recv.amount = request.amount;
        return recv;
    }

    /**
     * @notice Receive a PeggedTokenBridgeV2 mint.
     * @param _request The serialized request protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A request must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     * @param _bridgeAddr The address of PeggedTokenBridgeV2.
     */
    function receivePegV2Mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        address _bridgeAddr
    ) internal returns (ReceiveInfo memory) {
        ReceiveInfo memory recv;
        PbPegged.Mint memory request = PbPegged.decMint(_request);
        if (IPeggedTokenBridgeV2(_bridgeAddr).records(request.refId)) {
            recv.transferId = keccak256(
                abi.encodePacked(
                    request.account,
                    request.token,
                    request.amount,
                    request.depositor,
                    request.refChainId,
                    request.refId,
                    _bridgeAddr
                )
            );
        } else {
            recv.transferId = IPeggedTokenBridgeV2(_bridgeAddr).mint(_request, _sigs, _signers, _powers);
        }
        recv.refid = request.refId;
        recv.receiver = request.account;
        recv.token = request.token;
        recv.amount = request.amount;
        return recv;
    }

    function bridgeRefundType(BridgeSendType _bridgeSendType) internal pure returns (BridgeReceiveType) {
        if (_bridgeSendType == BridgeSendType.Liquidity) {
            return BridgeReceiveType.LqWithdraw;
        }
        if (_bridgeSendType == BridgeSendType.PegDeposit) {
            return BridgeReceiveType.PegWithdraw;
        }
        if (_bridgeSendType == BridgeSendType.PegBurn) {
            return BridgeReceiveType.PegMint;
        }
        if (_bridgeSendType == BridgeSendType.PegV2Deposit) {
            return BridgeReceiveType.PegV2Withdraw;
        }
        if (_bridgeSendType == BridgeSendType.PegV2Burn || _bridgeSendType == BridgeSendType.PegV2BurnFrom) {
            return BridgeReceiveType.PegV2Mint;
        }
        return BridgeReceiveType.Null;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: bridge.proto
pragma solidity 0.8.9;
import "./Pb.sol";

library PbBridge {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct Relay {
        address sender; // tag: 1
        address receiver; // tag: 2
        address token; // tag: 3
        uint256 amount; // tag: 4
        uint64 srcChainId; // tag: 5
        uint64 dstChainId; // tag: 6
        bytes32 srcTransferId; // tag: 7
    } // end struct Relay

    function decRelay(bytes memory raw) internal pure returns (Relay memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.sender = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 3) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 5) {
                m.srcChainId = uint64(buf.decVarint());
            } else if (tag == 6) {
                m.dstChainId = uint64(buf.decVarint());
            } else if (tag == 7) {
                m.srcTransferId = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder Relay
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

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
// source: contracts/libraries/proto/pegged.proto
pragma solidity 0.8.9;
import "./Pb.sol";

library PbPegged {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct Mint {
        address token; // tag: 1
        address account; // tag: 2
        uint256 amount; // tag: 3
        address depositor; // tag: 4
        uint64 refChainId; // tag: 5
        bytes32 refId; // tag: 6
    } // end struct Mint

    function decMint(bytes memory raw) internal pure returns (Mint memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.account = Pb._address(buf.decBytes());
            } else if (tag == 3) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 4) {
                m.depositor = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.refChainId = uint64(buf.decVarint());
            } else if (tag == 6) {
                m.refId = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder Mint

    struct Withdraw {
        address token; // tag: 1
        address receiver; // tag: 2
        uint256 amount; // tag: 3
        address burnAccount; // tag: 4
        uint64 refChainId; // tag: 5
        bytes32 refId; // tag: 6
    } // end struct Withdraw

    function decWithdraw(bytes memory raw) internal pure returns (Withdraw memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 3) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 4) {
                m.burnAccount = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.refChainId = uint64(buf.decVarint());
            } else if (tag == 6) {
                m.refId = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder Withdraw
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: contracts/libraries/proto/pool.proto
pragma solidity 0.8.9;
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable;

    function relay(
        bytes calldata _relayRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function transfers(bytes32 transferId) external view returns (bool);

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IOriginalTokenVault {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Lock native token as original token to trigger mint at a remote chain's PeggedTokenBridge
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function depositNative(
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external payable;

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IOriginalTokenVaultV2 {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external returns (bytes32);

    /**
    * @notice Lock native token as original token to trigger mint at a remote chain's PeggedTokenBridge
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function depositNative(
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external payable returns (bytes32);

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedTokenBridge {
    /**
     * @notice Burn tokens to trigger withdrawal at a remote chain's OriginalTokenVault
     * @param _token local token address
     * @param _amount locked token amount
     * @param _withdrawAccount account who withdraw original tokens on the remote chain
     * @param _nonce user input to guarantee unique depositId
     */
    function burn(
        address _token,
        uint256 _amount,
        address _withdrawAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedTokenBridgeV2 {
    /**
     * @notice Burn pegged tokens to trigger a cross-chain withdrawal of the original tokens at a remote chain's
     * OriginalTokenVault, or mint at another remote chain
     * @param _token The pegged token address.
     * @param _amount The amount to burn.
     * @param _toChainId If zero, withdraw from original vault; otherwise, the remote chain to mint tokens.
     * @param _toAccount The account to receive tokens on the remote chain
     * @param _nonce A number to guarantee unique depositId. Can be timestamp in practice.
     */
    function burn(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    // same with `burn` above, use openzeppelin ERC20Burnable interface
    function burnFrom(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

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
 *
 * This adds a normal func that setOwner if _owner is address(0). So we can't allow
 * renounceOwnership. So we can support Proxy based upgradable contract
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Only to be called by inherit contracts, in their init func called by Proxy
     * we require _owner == address(0), which is only possible when it's a delegateCall
     * because constructor sets _owner in contract state.
     */
    function initOwner() internal {
        require(_owner == address(0), "owner already set");
        _setOwner(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}