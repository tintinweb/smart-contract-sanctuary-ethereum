// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import {DataTransferType} from "../../data-transfer/LibCommon.sol";
import {LibGuard} from "../../libraries/LibGuard.sol";
import {AppStorage} from "../../libraries/LibMagpieAggregator.sol";
import {LibPauser} from "../../pauser/LibPauser.sol";
import {LibRouter} from "../../router/LibRouter.sol";
import {IAggregator} from "../interfaces/IAggregator.sol";
import {LibAggregator, SwapArgs, SwapInArgs, SwapOutArgs} from "../LibAggregator.sol";

contract AggregatorFacet is IAggregator {
    AppStorage internal s;

    function updateWeth(address weth) external override {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.updateWeth(weth);
    }

    function updateNetworkId(uint16 networkId) external override {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.updateNetworkId(networkId);
    }

    function addMagpieAggregatorAddresses(uint16[] calldata networkIds, bytes32[] calldata magpieAggregatorAddresses)
        external
        override
    {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.addMagpieAggregatorAddresses(networkIds, magpieAggregatorAddresses);
    }

    function swap(SwapArgs calldata swapArgs) external payable override returns (uint256 amountOut) {
        LibRouter.enforceDeadline(swapArgs.deadline);
        LibPauser.enforceIsNotPaused();
        LibGuard.enforcePreGuard();
        amountOut = LibAggregator.swap(swapArgs);
        LibGuard.enforcePostGuard();
    }

    function swapIn(SwapInArgs calldata swapInArgs) external payable override returns (uint256 amountOut) {
        LibRouter.enforceDeadline(swapInArgs.swapArgs.deadline);
        LibPauser.enforceIsNotPaused();
        LibGuard.enforcePreGuard();
        amountOut = LibAggregator.swapIn(swapInArgs);
        LibGuard.enforcePostGuard();
    }

    function swapOut(SwapOutArgs calldata swapOutArgs) external override returns (uint256 amountOut) {
        LibRouter.enforceDeadline(swapOutArgs.swapArgs.deadline);
        LibPauser.enforceIsNotPaused();
        LibGuard.enforcePreGuard();
        amountOut = LibAggregator.swapOut(swapOutArgs);
        LibGuard.enforcePostGuard();
    }

    function withdraw(address assetAddress) external override {
        LibPauser.enforceIsNotPaused();
        LibAggregator.withdraw(assetAddress);
    }

    function getDeposit(address assetAddress) external view override returns (uint256) {
        return LibAggregator.getDeposit(assetAddress);
    }

    function getPayload(
        DataTransferType dataTransferType,
        uint16 senderNetworkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) external view returns (bytes memory) {
        return LibAggregator.getPayload(dataTransferType, senderNetworkId, senderAddress, swapSequence);
    }

    function getDepositByUser(address assetAddress, address senderAddress) external view override returns (uint256) {
        return LibAggregator.getDepositByUser(assetAddress, senderAddress);
    }

    function isTransferKeyUsed(
        uint16 networkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) external view override returns (bool) {
        return LibAggregator.isTransferKeyUsed(networkId, senderAddress, swapSequence);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {DataTransferType} from "../../data-transfer/LibCommon.sol";
import {TransferKey} from "../../libraries/LibTransferKey.sol";
import {SwapArgs} from "../../router/LibRouter.sol";
import {Transaction} from "../../bridge/LibTransaction.sol";
import {SwapInArgs, SwapOutArgs} from "../LibAggregator.sol";

interface IAggregator {
    event UpdateWeth(address indexed sender, address weth);

    function updateWeth(address weth) external;

    event UpdateNetworkId(address indexed sender, uint16 networkId);

    function updateNetworkId(uint16 networkId) external;

    event AddMagpieAggregatorAddresses(
        address indexed sender,
        uint16[] networkIds,
        bytes32[] magpieAggregatorAddresses
    );

    function addMagpieAggregatorAddresses(uint16[] calldata networkIds, bytes32[] calldata magpieAggregatorAddresses)
        external;

    event Swap(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut
    );

    function swap(SwapArgs calldata swapArgs) external payable returns (uint256 amountOut);

    event SwapIn(
        address indexed fromAddress,
        bytes32 indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    function swapIn(SwapInArgs calldata swapInArgs) external payable returns (uint256 amountOut);

    event SwapOut(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    function swapOut(SwapOutArgs calldata swapOutArgs) external returns (uint256 amountOut);

    event Withdraw(address indexed sender, address indexed assetAddress, uint256 amount);

    function withdraw(address assetAddress) external;

    function getDeposit(address assetAddress) external view returns (uint256);

    function getPayload(
        DataTransferType dataTransferType,
        uint16 senderNetworkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) external view returns (bytes memory);

    function getDepositByUser(address assetAddress, address senderAddress) external view returns (uint256);

    function isTransferKeyUsed(
        uint16 networkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {TransferKey} from "../libraries/LibTransferKey.sol";
import {LibRouter, SwapArgs} from "../router/LibRouter.sol";
import {LibUint256Array} from "../libraries/LibUint256Array.sol";
import {BridgeArgs, BridgeInArgs, BridgeOutArgs} from "../bridge/LibCommon.sol";
import {LibTransaction, Transaction, TransactionValidation} from "../bridge/LibTransaction.sol";
import {DataTransferInArgs, DataTransferInProtocol, DataTransferOutArgs, DataTransferType} from "../data-transfer/LibCommon.sol";

struct SwapInArgs {
    SwapArgs swapArgs;
    BridgeArgs bridgeArgs;
    DataTransferInProtocol dataTransferInProtocol;
    TransactionValidation transactionValidation;
}

struct SwapOutArgs {
    SwapArgs swapArgs;
    BridgeArgs bridgeArgs;
    DataTransferOutArgs dataTransferOutArgs;
}

struct SwapOutVariables {
    address fromAssetAddress;
    address toAssetAddress;
    address toAddress;
    address transactionToAddress;
    uint256 bridgeAmount;
    uint256 amountIn;
}

error AggregatorDepositIsZero();
error AggregatorInvalidAmountIn();
error AggregatorInvalidAmountOutMin();
error AggregatorInvalidFromAssetAddress();
error AggregatorInvalidMagpieAggregatorAddress();
error AggregatorInvalidToAddress();
error AggregatorInvalidToAssetAddress();
error AggregatorInvalidTransferKey();
error AggregatorBridgeInCallFailed();
error AggregatorBridgeOutCallFailed();
error AggregatorDataTransferInCallFailed();
error AggregatorDataTransferOutCallFailed();

library LibAggregator {
    using LibAsset for address;
    using LibBytes for bytes;
    using LibUint256Array for uint256[];

    event UpdateWeth(address indexed sender, address weth);

    function updateWeth(address weth) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.weth = weth;

        emit UpdateWeth(msg.sender, weth);
    }

    event UpdateNetworkId(address indexed sender, uint16 networkId);

    function updateNetworkId(uint16 networkId) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.networkId = networkId;

        emit UpdateNetworkId(msg.sender, networkId);
    }

    event AddMagpieAggregatorAddresses(
        address indexed sender,
        uint16[] networkIds,
        bytes32[] magpieAggregatorAddresses
    );

    function addMagpieAggregatorAddresses(uint16[] memory networkIds, bytes32[] memory magpieAggregatorAddresses)
        internal
    {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 i;
        uint256 l = magpieAggregatorAddresses.length;
        for (i = 0; i < l; ) {
            s.magpieAggregatorAddresses[networkIds[i]] = magpieAggregatorAddresses[i];

            unchecked {
                i++;
            }
        }

        emit AddMagpieAggregatorAddresses(msg.sender, networkIds, magpieAggregatorAddresses);
    }

    event Swap(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut
    );

    function swap(SwapArgs memory swapArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        address toAddress = swapArgs.addresses.toAddress(0);
        address fromAssetAddress = swapArgs.addresses.toAddress(20);
        address toAssetAddress = swapArgs.addresses.toAddress(40);
        uint256 amountIn = swapArgs.amountIns.sum();

        fromAssetAddress.deposit(s.weth, amountIn);

        amountOut = LibRouter.swap(swapArgs, !toAssetAddress.isNative());

        if (toAssetAddress.isNative()) {
            toAssetAddress.withdraw(s.weth, toAddress, amountOut);
        }

        emit Swap(msg.sender, toAddress, fromAssetAddress, toAssetAddress, amountIn, amountOut);
    }

    event SwapIn(
        address indexed fromAddress,
        bytes32 indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    function swapIn(SwapInArgs memory swapInArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (swapInArgs.swapArgs.addresses.toAddress(0) != address(this)) {
            revert AggregatorInvalidToAddress();
        }

        uint256 amountIn = swapInArgs.swapArgs.amountIns.sum();
        address fromAssetAddress = swapInArgs.swapArgs.addresses.toAddress(20);
        address toAssetAddress = swapInArgs.swapArgs.addresses.toAddress(40);

        fromAssetAddress.deposit(s.weth, amountIn);

        amountOut = LibRouter.swap(swapInArgs.swapArgs, false);

        s.swapSequence += 1;
        TransferKey memory transferKey = TransferKey({
            networkId: s.networkId,
            senderAddress: bytes32(uint256(uint160(address(this)))),
            swapSequence: s.swapSequence
        });

        bridgeIn(
            BridgeInArgs({
                recipientNetworkId: swapInArgs.dataTransferInProtocol.networkId,
                bridgeArgs: swapInArgs.bridgeArgs,
                amount: amountOut,
                toAssetAddress: toAssetAddress,
                transferKey: transferKey
            })
        );

        Transaction memory transaction = Transaction({
            dataTransferType: swapInArgs.dataTransferInProtocol.dataTransferType,
            bridgeType: swapInArgs.bridgeArgs.bridgeType,
            recipientNetworkId: swapInArgs.dataTransferInProtocol.networkId,
            fromAssetAddress: swapInArgs.transactionValidation.fromAssetAddress,
            toAssetAddress: swapInArgs.transactionValidation.toAssetAddress,
            toAddress: swapInArgs.transactionValidation.toAddress,
            recipientAggregatorAddress: s.magpieAggregatorAddresses[swapInArgs.dataTransferInProtocol.networkId],
            amountOutMin: swapInArgs.transactionValidation.amountOutMin,
            swapOutGasFee: swapInArgs.transactionValidation.swapOutGasFee
        });

        dataTransferIn(
            DataTransferInArgs({
                protocol: swapInArgs.dataTransferInProtocol,
                transferKey: transferKey,
                payload: LibTransaction.encode(transaction)
            })
        );

        emit SwapIn(
            msg.sender,
            transaction.toAddress,
            fromAssetAddress,
            toAssetAddress,
            amountIn,
            amountOut,
            transferKey,
            transaction
        );
    }

    event SwapOut(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    function swapOut(SwapOutArgs memory swapOutArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        (TransferKey memory transferKey, bytes memory payload) = dataTransferOut(swapOutArgs.dataTransferOutArgs);

        if (s.usedTransferKeys[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence]) {
            revert AggregatorInvalidTransferKey();
        }

        s.usedTransferKeys[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence] = true;

        Transaction memory transaction = LibTransaction.decode(payload);

        SwapOutVariables memory v = SwapOutVariables({
            bridgeAmount: bridgeOut(
                BridgeOutArgs({bridgeArgs: swapOutArgs.bridgeArgs, transaction: transaction, transferKey: transferKey})
            ),
            amountIn: swapOutArgs.swapArgs.amountIns.sum(),
            toAddress: swapOutArgs.swapArgs.addresses.toAddress(0),
            transactionToAddress: address(uint160(uint256(transaction.toAddress))),
            fromAssetAddress: swapOutArgs.swapArgs.addresses.toAddress(20),
            toAssetAddress: swapOutArgs.swapArgs.addresses.toAddress(40)
        });

        if (v.transactionToAddress == msg.sender) {
            transaction.swapOutGasFee = 0;
            transaction.amountOutMin = swapOutArgs.swapArgs.amountOutMin;
        } else {
            swapOutArgs.swapArgs.amountOutMin = transaction.amountOutMin;
        }

        if (address(uint160(uint256(transaction.fromAssetAddress))) != v.fromAssetAddress) {
            revert AggregatorInvalidFromAssetAddress();
        }

        if (msg.sender != v.transactionToAddress) {
            if (address(uint160(uint256(transaction.toAssetAddress))) != v.toAssetAddress) {
                revert AggregatorInvalidToAssetAddress();
            }
        }

        if (v.transactionToAddress != v.toAddress || v.transactionToAddress == address(this)) {
            revert AggregatorInvalidToAddress();
        }

        if (address(uint160(uint256(transaction.recipientAggregatorAddress))) != address(this)) {
            revert AggregatorInvalidMagpieAggregatorAddress();
        }

        if (swapOutArgs.swapArgs.amountOutMin < transaction.amountOutMin) {
            revert AggregatorInvalidAmountOutMin();
        }

        if (swapOutArgs.swapArgs.amountIns[0] <= transaction.swapOutGasFee) {
            revert AggregatorInvalidAmountIn();
        }

        if (v.amountIn > v.bridgeAmount) {
            revert AggregatorInvalidAmountIn();
        }

        swapOutArgs.swapArgs.amountIns[0] =
            swapOutArgs.swapArgs.amountIns[0] +
            (v.bridgeAmount > v.amountIn ? v.bridgeAmount - v.amountIn : 0) -
            transaction.swapOutGasFee;
        v.amountIn = swapOutArgs.swapArgs.amountIns.sum();

        if (transaction.swapOutGasFee > 0) {
            s.deposits[v.fromAssetAddress] += transaction.swapOutGasFee;
            s.depositsByUser[v.fromAssetAddress][msg.sender] += transaction.swapOutGasFee;
        }

        amountOut = LibRouter.swap(swapOutArgs.swapArgs, !v.toAssetAddress.isNative());

        if (v.toAssetAddress.isNative()) {
            v.toAssetAddress.withdraw(s.weth, v.toAddress, amountOut);
        }

        emit SwapOut(
            msg.sender,
            v.toAddress,
            v.fromAssetAddress,
            v.toAssetAddress,
            v.amountIn,
            amountOut,
            transferKey,
            transaction
        );
    }

    event Withdraw(address indexed sender, address indexed assetAddress, uint256 amount);

    function withdraw(address assetAddress) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 deposit = s.depositsByUser[assetAddress][msg.sender];

        if (deposit == 0) {
            revert AggregatorDepositIsZero();
        }

        s.deposits[assetAddress] -= deposit;
        s.depositsByUser[assetAddress][msg.sender] = 0;

        assetAddress.transfer(msg.sender, deposit);

        emit Withdraw(msg.sender, assetAddress, deposit);
    }

    function getDeposit(address assetAddress) internal view returns (uint256) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        return s.deposits[assetAddress];
    }

    function getPayload(
        DataTransferType dataTransferType,
        uint16 senderNetworkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) internal view returns (bytes memory) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        return s.payloads[uint16(dataTransferType)][senderNetworkId][senderAddress][swapSequence];
    }

    function getDepositByUser(address assetAddress, address senderAddress) internal view returns (uint256) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        return s.depositsByUser[assetAddress][senderAddress];
    }

    function isTransferKeyUsed(
        uint16 networkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) internal view returns (bool) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        return s.usedTransferKeys[networkId][senderAddress][swapSequence];
    }

    function bridgeIn(BridgeInArgs memory bridgeInArgs) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"2312b1a3";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory bridgeInCall = abi.encodeWithSelector(selector, bridgeInArgs);
        (bool success, ) = address(facet).delegatecall(bridgeInCall);
        if (!success) {
            revert AggregatorBridgeInCallFailed();
        }
    }

    function bridgeOut(BridgeOutArgs memory bridgeOutArgs) internal returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"c6687b9d";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory bridgeOutCall = abi.encodeWithSelector(selector, bridgeOutArgs);
        (bool success, bytes memory data) = address(facet).delegatecall(bridgeOutCall);
        if (!success) {
            revert AggregatorBridgeOutCallFailed();
        }

        return abi.decode(data, (uint256));
    }

    function dataTransferIn(DataTransferInArgs memory dataTransferInArgs) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"7f2bf445";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory dataTransferInCall = abi.encodeWithSelector(selector, dataTransferInArgs);
        (bool success, ) = address(facet).delegatecall(dataTransferInCall);
        if (!success) {
            revert AggregatorDataTransferInCallFailed();
        }
    }

    function dataTransferOut(DataTransferOutArgs memory dataTransferOutArgs)
        internal
        returns (TransferKey memory, bytes memory)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"83d5b76e";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory dataTransferOutCall = abi.encodeWithSelector(selector, dataTransferOutArgs);
        (bool success, bytes memory data) = address(facet).delegatecall(dataTransferOutCall);
        if (!success) {
            revert AggregatorDataTransferOutCallFailed();
        }

        return abi.decode(data, (TransferKey, bytes));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibBytes} from "../libraries/LibBytes.sol";
import {TransferKey} from "../libraries/LibTransferKey.sol";
import {Transaction} from "./LibTransaction.sol";

enum BridgeType {
    Wormhole,
    Stargate
}

struct BridgeArgs {
    BridgeType bridgeType;
    bytes payload;
}

struct BridgeInArgs {
    uint16 recipientNetworkId;
    BridgeArgs bridgeArgs;
    uint256 amount;
    address toAssetAddress;
    TransferKey transferKey;
}

struct BridgeOutArgs {
    BridgeArgs bridgeArgs;
    Transaction transaction;
    TransferKey transferKey;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {BridgeType} from "../bridge/LibCommon.sol";
import {DataTransferType} from "../data-transfer/LibCommon.sol";

struct TransactionValidation {
    bytes32 fromAssetAddress;
    bytes32 toAssetAddress;
    bytes32 toAddress;
    uint256 amountOutMin;
    uint256 swapOutGasFee;
}

struct Transaction {
    DataTransferType dataTransferType;
    BridgeType bridgeType;
    uint16 recipientNetworkId;
    bytes32 fromAssetAddress;
    bytes32 toAssetAddress;
    bytes32 toAddress;
    bytes32 recipientAggregatorAddress;
    uint256 amountOutMin;
    uint256 swapOutGasFee;
}

library LibTransaction {
    function encode(Transaction memory transaction) internal pure returns (bytes memory transactionPayload) {
        transactionPayload = new bytes(204);

        assembly {
            mstore(add(transactionPayload, 32), shl(248, mload(transaction))) // dataTransferType
            mstore(add(transactionPayload, 33), shl(248, mload(add(transaction, 32)))) // bridgeType
            mstore(add(transactionPayload, 34), shl(240, mload(add(transaction, 64)))) // recipientNetworkId
            mstore(add(transactionPayload, 36), mload(add(transaction, 96))) // fromAssetAddress
            mstore(add(transactionPayload, 68), mload(add(transaction, 128))) // toAssetAddress
            mstore(add(transactionPayload, 100), mload(add(transaction, 160))) // to
            mstore(add(transactionPayload, 132), mload(add(transaction, 192))) // recipientAggregatorAddress
            mstore(add(transactionPayload, 164), mload(add(transaction, 224))) // amountOutMin
            mstore(add(transactionPayload, 196), mload(add(transaction, 256))) // swapOutGasFee
        }
    }

    function decode(bytes memory transactionPayload) internal pure returns (Transaction memory transaction) {
        assembly {
            mstore(transaction, shr(248, mload(add(transactionPayload, 32)))) // dataTransferType
            mstore(add(transaction, 32), shr(248, mload(add(transactionPayload, 33)))) // bridgeType
            mstore(add(transaction, 64), shr(240, mload(add(transactionPayload, 34)))) // recipientNetworkId
            mstore(add(transaction, 96), mload(add(transactionPayload, 36))) // fromAssetAddress
            mstore(add(transaction, 128), mload(add(transactionPayload, 68))) // toAssetAddress
            mstore(add(transaction, 160), mload(add(transactionPayload, 100))) // to
            mstore(add(transaction, 192), mload(add(transactionPayload, 132))) // recipientAggregatorAddress
            mstore(add(transaction, 224), mload(add(transactionPayload, 164))) // amountOutMin
            mstore(add(transaction, 256), mload(add(transactionPayload, 196))) // swapOutGasFee
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {TransferKey} from "../libraries/LibTransferKey.sol";

enum DataTransferType {
    Wormhole,
    LayerZero
}

struct DataTransferInProtocol {
    uint16 networkId;
    DataTransferType dataTransferType;
    bytes payload;
}

struct DataTransferInArgs {
    DataTransferInProtocol protocol;
    TransferKey transferKey;
    bytes payload;
}

struct DataTransferOutArgs {
    DataTransferType dataTransferType;
    bytes payload;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IAddressProvider {
    function admin() external view returns (address);

    function get_registry() external view returns (address);

    function get_address(uint256 idx) external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "../interfaces/IWETH.sol";

error AssetNotReceived();

library LibAsset {
    using LibAsset for address;

    address constant NATIVE_ASSETID = address(0);

    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    function getBalanceOf(address self, address target) internal view returns (uint256) {
        return self.isNative() ? target.balance : IERC20(self).balanceOf(target);
    }

    function getBalance(address self) internal view returns (uint256) {
        return self.isNative() ? address(this).balance : IERC20(self).balanceOf(address(this));
    }

    function transferFrom(
        address self,
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeERC20.safeTransferFrom(IERC20(self), from, to, amount);
    }

    function transfer(
        address self,
        address recipient,
        uint256 amount
    ) internal {
        if (self.isNative()) {
            Address.sendValue(payable(recipient), amount);
        } else {
            SafeERC20.safeTransfer(IERC20(self), recipient, amount);
        }
    }

    function approve(
        address self,
        address spender,
        uint256 amount
    ) internal {
        SafeERC20.forceApprove(IERC20(self), spender, amount);
    }

    function getAllowance(
        address self,
        address owner,
        address spender
    ) internal view returns (uint256) {
        return IERC20(self).allowance(owner, spender);
    }

    function deposit(
        address self,
        address weth,
        uint256 amount
    ) internal {
        if (self.isNative()) {
            if (msg.value < amount) {
                revert AssetNotReceived();
            }
            IWETH(weth).deposit{value: amount}();
        } else {
            self.transferFrom(msg.sender, address(this), amount);
        }
    }

    function withdraw(
        address self,
        address weth,
        address to,
        uint256 amount
    ) internal {
        if (self.isNative()) {
            IWETH(weth).withdraw(amount);
        }
        self.transfer(payable(to), amount);
    }

    function getDecimals(address self) internal view returns (uint8 tokenDecimals) {
        tokenDecimals = 18;

        if (!self.isNative()) {
            (, bytes memory queriedDecimals) = self.staticcall(abi.encodeWithSignature("decimals()"));
            tokenDecimals = abi.decode(queriedDecimals, (uint8));
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

error AddressOutOfBounds();

library LibBytes {
    using LibBytes for bytes;

    function toAddress(bytes memory self, uint256 start) internal pure returns (address) {
        if (self.length < start + 20) {
            revert AddressOutOfBounds();
        }
        address tempAddress;

        assembly {
            tempAddress := mload(add(add(self, 20), start))
        }

        return tempAddress;
    }

    function slice(
        bytes memory self,
        uint256 start,
        uint256 length
    ) internal pure returns (bytes memory) {
        require(length + 31 >= length, "slice_overflow");
        require(self.length >= start + length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(length)
            case 0 {
                tempBytes := mload(0x40)
                let lengthmod := and(length, 31)
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, length)

                for {
                    let cc := add(add(add(self, lengthmod), mul(0x20, iszero(lengthmod))), start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function concat(bytes memory self, bytes memory postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            tempBytes := mload(0x40)

            let length := mload(self)
            mstore(tempBytes, length)

            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(self, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            mc := end
            end := add(mc, length)

            for {
                let cc := add(postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(0x40, and(add(add(end, iszero(add(length, mload(self)))), 31), not(31)))
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";

error ReentrantCall();

library LibGuard {
    function enforcePreGuard() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (s.guarded) {
            revert ReentrantCall();
        }

        s.guarded = true;
    }

    function enforcePostGuard() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.guarded = false;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

struct CurveSettings {
    address mainRegistry;
    address cryptoRegistry;
    address cryptoFactory;
}

struct Amm {
    uint8 protocolId;
    bytes4 selector;
    address addr;
}

struct WormholeBridgeSettings {
    address bridgeAddress;
}

struct StargateSettings {
    address routerAddress;
}

struct WormholeSettings {
    address bridgeAddress;
    uint8 consistencyLevel;
}

struct LayerZeroSettings {
    address routerAddress;
}

struct AppStorage {
    address weth;
    uint16 networkId;
    mapping(uint16 => bytes32) magpieAggregatorAddresses;
    mapping(address => uint256) deposits;
    mapping(address => mapping(address => uint256)) depositsByUser;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => bool))) usedTransferKeys;
    uint64 swapSequence;
    // Pausable
    bool paused;
    // Reentrancy Guard
    bool guarded;
    // Amm
    mapping(uint16 => Amm) amms;
    // Curve Amm
    CurveSettings curveSettings;
    // Data Transfer
    mapping(uint16 => mapping(uint16 => mapping(bytes32 => mapping(uint64 => bytes)))) payloads;
    // Stargate Bridge
    StargateSettings stargateSettings;
    mapping(uint16 => bytes32) magpieStargateBridgeAddresses;
    // Wormhole Bridge
    WormholeBridgeSettings wormholeBridgeSettings;
    mapping(uint64 => uint64) wormholeTokenSequences;
    // Wormhole Data Transfer
    WormholeSettings wormholeSettings;
    mapping(uint16 => uint16) wormholeNetworkIds;
    mapping(uint64 => uint64) wormholeCoreSequences;
    // LayerZero Data Transfer
    LayerZeroSettings layerZeroSettings;
    mapping(uint16 => uint16) layerZeroChainIds;
    mapping(uint16 => uint16) layerZeroNetworkIds;
}

library LibMagpieAggregator {
    function getStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

struct TransferKey {
    uint16 networkId;
    bytes32 senderAddress;
    uint64 swapSequence;
}

error InvalidTransferKey();

library LibTransferKey {
    function encode(TransferKey memory transferKey) internal pure returns (bytes memory) {
        bytes memory payload = new bytes(42);

        assembly {
            mstore(add(payload, 32), shl(240, mload(transferKey)))
            mstore(add(payload, 34), mload(add(transferKey, 32)))
            mstore(add(payload, 66), shl(192, mload(add(transferKey, 64))))
        }

        return payload;
    }

    function decode(bytes memory payload) internal pure returns (TransferKey memory transferKey) {
        assembly {
            mstore(transferKey, shr(240, mload(add(payload, 32))))
            mstore(add(transferKey, 32), mload(add(payload, 34)))
            mstore(add(transferKey, 64), shr(192, mload(add(payload, 66))))
        }
    }

    function validate(TransferKey memory self, TransferKey memory transferKey) internal pure {
        if (
            self.networkId != transferKey.networkId ||
            self.senderAddress != transferKey.senderAddress ||
            self.swapSequence != transferKey.swapSequence
        ) {
            revert InvalidTransferKey();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

library LibUint256Array {
    function sum(uint256[] memory self) internal pure returns (uint256 amountOut) {
        uint256 selfLength = self.length * 32;

        assembly {
            let selfPosition := add(self, 32)
            let endPosition := add(selfPosition, selfLength)

            for {

            } lt(selfPosition, endPosition) {
                selfPosition := add(selfPosition, 32)
            } {
                amountOut := add(amountOut, mload(selfPosition))
            }
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";

error ContractIsPaused();

library LibPauser {
    event Paused(address sender);

    function pause() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.paused = true;
        emit Paused(msg.sender);
    }

    event Unpaused(address sender);

    function unpause() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.paused = false;
        emit Paused(msg.sender);
    }

    function enforceIsNotPaused() internal view {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (s.paused) {
            revert ContractIsPaused();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";

struct Hop {
    address addr;
    uint256 amountIn;
    address recipient;
    bytes[] poolDataList;
    address[] path;
}

error InvalidSingleHop();

library LibHop {
    using LibAsset for address;

    function enforceSingleHop(Hop memory self) internal pure {
        if (self.path.length != 2) {
            revert InvalidSingleHop();
        }
    }

    function enforceTransferToRecipient(Hop memory self) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        address path = self.path[self.path.length - 1];

        if (self.recipient != address(this)) {
            path.transfer(self.recipient, path.getBalance() - s.deposits[path]);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import {IAddressProvider} from "../interfaces/curve/IAddressProvider.sol";
import {Amm, AppStorage, CurveSettings, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {LibUint256Array} from "../libraries/LibUint256Array.sol";
import {Hop} from "./LibHop.sol";

struct SwapArgs {
    uint256 amountOutMin;
    uint256 deadline;
    uint256[] amountIns;
    bytes32[] hops;
    bytes addresses;
    bytes poolData;
}

struct SwapState {
    uint256 i;
    uint256 lastAmountOut;
    uint256 hopsLength;
    uint256 amountIn;
    uint256 amountInAcc;
    address fromAssetAddress;
    address toAssetAddress;
    address currentFromAssetAddress;
    address recipient;
}

error RouterAmmCallFailed(bytes returnData);
error RouterInvalidPath();
error RouterExpiredTransaction();
error RouterInsufficientOutputAmount();
error RouterInvalidAmountIn();
error RouterInvalidProtocol();
error RouterInvalidHops();

library LibRouter {
    using LibAsset for address;
    using LibBytes for bytes;
    using LibUint256Array for uint256[];

    function getHopParams(
        bytes32 data,
        bytes memory addresses,
        bytes memory poolData,
        uint256[] memory amountIns
    )
        public
        pure
        returns (
            uint16 ammId,
            uint256 amountIn,
            address[] memory path,
            bytes[] memory poolDataList
        )
    {
        uint256 pl;
        uint256 pdl;
        uint256 poolDataPosition;
        uint256 poolDataLength;

        assembly {
            amountIn := mload(add(amountIns, add(32, mul(shr(248, data), 32))))
            ammId := shr(240, shl(8, data))
            pl := shr(248, shl(24, data))
            pdl := shr(248, shl(32, data))
        }

        path = new address[](pl);

        assembly {
            let i := 0
            let pathPosition := add(path, 32)

            for {

            } lt(i, pl) {
                i := add(i, 1)
                pathPosition := add(pathPosition, 32)
            } {
                mstore(
                    pathPosition,
                    shr(
                        96,
                        mload(
                            add(
                                add(addresses, 32),
                                mul(
                                    shr(248, shl(mul(add(5, i), 8), data)), /* pathIndex */
                                    20
                                )
                            )
                        )
                    )
                )
            }
        }

        poolDataList = new bytes[](pdl);

        for (uint256 i = 0; i < pdl; ) {
            assembly {
                poolDataPosition := shr(248, shl(mul(add(9, i), 8), data))
                poolDataLength := shr(240, shl(mul(add(13, mul(i, 2)), 8), data))
            }

            poolDataList[i] = poolData.slice(poolDataPosition, poolDataLength);

            unchecked {
                i++;
            }
        }
    }

    function swap(SwapArgs memory swapArgs, bool transferToRecipient) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        SwapState memory ss = SwapState({
            i: 0,
            lastAmountOut: 0,
            hopsLength: swapArgs.hops.length,
            amountIn: swapArgs.amountIns.sum(),
            amountInAcc: 0,
            fromAssetAddress: swapArgs.addresses.toAddress(20),
            toAssetAddress: swapArgs.addresses.toAddress(40),
            currentFromAssetAddress: swapArgs.addresses.toAddress(20),
            recipient: transferToRecipient ? swapArgs.addresses.toAddress(0) : address(this)
        });

        if (ss.fromAssetAddress.isNative()) {
            ss.fromAssetAddress = s.weth;
            ss.currentFromAssetAddress = s.weth;
        } else if (ss.toAssetAddress.isNative()) {
            ss.toAssetAddress = s.weth;
        }

        uint256 startingBalance = ss.toAssetAddress.getBalanceOf(ss.recipient);

        Hop memory hop = Hop({
            addr: address(0),
            amountIn: 0,
            recipient: ss.recipient,
            poolDataList: new bytes[](0),
            path: new address[](0)
        });

        if (ss.hopsLength == 0) {
            ss.amountInAcc = ss.amountIn;
            amountOut = ss.amountIn;
        }

        for (ss.i; ss.i < ss.hopsLength; ) {
            uint16 ammId;
            uint256 amountIn;
            (ammId, amountIn, hop.path, hop.poolDataList) = getHopParams(
                swapArgs.hops[ss.i],
                swapArgs.addresses,
                swapArgs.poolData,
                swapArgs.amountIns
            );
            hop.addr = s.amms[ammId].addr;

            if (hop.path.length < 2) {
                revert RouterInvalidPath();
            }

            if (hop.path[0].isNative()) {
                hop.path[0] = s.weth;
            } else if (hop.path[hop.path.length - 1].isNative()) {
                hop.path[hop.path.length - 1] = s.weth;
            }

            if ((ss.currentFromAssetAddress == ss.toAssetAddress || ss.i == 0) && ss.fromAssetAddress == hop.path[0]) {
                ss.currentFromAssetAddress = ss.fromAssetAddress;
                hop.amountIn = amountIn;
                ss.amountInAcc += hop.amountIn;
            } else {
                hop.amountIn = ss.lastAmountOut;
            }

            address hopToAssetAddress = hop.path[hop.path.length - 1];

            if (ss.i == ss.hopsLength - 1 && hopToAssetAddress != ss.toAssetAddress) {
                revert RouterInvalidHops();
            }

            if (ss.currentFromAssetAddress != hop.path[0]) {
                revert RouterInvalidPath();
            }

            if (s.amms[ammId].protocolId == 0) {
                revert RouterInvalidProtocol();
            }

            hop.recipient = hopToAssetAddress == ss.toAssetAddress ? ss.recipient : address(this);

            address facet = ds.selectorToFacetAndPosition[s.amms[ammId].selector].facetAddress;
            if (facet == address(0)) {
                revert RouterInvalidProtocol();
            }
            bytes memory ammCall = abi.encodeWithSelector(s.amms[ammId].selector, hop);
            (bool success, bytes memory returnData) = address(facet).delegatecall(ammCall);
            if (!success) {
                revert RouterAmmCallFailed(returnData);
            }

            ss.lastAmountOut = hopToAssetAddress.getBalance() - s.deposits[hopToAssetAddress];

            if (ss.i == ss.hopsLength - 1) {
                uint256 balance = hopToAssetAddress.getBalanceOf(ss.recipient);
                amountOut = balance > startingBalance ? balance - startingBalance : 0;
            } else if (hop.recipient == address(this)) {
                ss.lastAmountOut = hopToAssetAddress.getBalance() - s.deposits[hopToAssetAddress];
            }

            ss.currentFromAssetAddress = hopToAssetAddress;

            unchecked {
                ss.i++;
            }
        }

        if (amountOut < swapArgs.amountOutMin || amountOut == 0) {
            revert RouterInsufficientOutputAmount();
        }

        if (ss.amountIn != ss.amountInAcc) {
            revert RouterInvalidAmountIn();
        }

        if (transferToRecipient && ss.hopsLength == 0) {
            swapArgs.addresses.toAddress(40).withdraw(s.weth, swapArgs.addresses.toAddress(0), amountOut);
        }
    }

    function enforceDeadline(uint256 deadline) internal view {
        if (deadline < block.timestamp) {
            revert RouterExpiredTransaction();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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