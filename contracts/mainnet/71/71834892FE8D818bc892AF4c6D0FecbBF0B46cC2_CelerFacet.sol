// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "SafeMath.sol";
import "GenericErrors.sol";
import "LibDiamond.sol";
import "LibBytes.sol";
import "LibCross.sol";
import "LibCelerMessageSender.sol";
import "ISo.sol";
import "ICelerMessageBus.sol";
import "ICelerBridge.sol";
import "ILibSoFee.sol";
import "ILibPriceV2.sol";
import "Swapper.sol";
import "ReentrancyGuard.sol";
import "CelerMessageReceiver.sol";

/// @title Celer Facet
/// @author OmniBTC
/// @notice Provides functionality for bridging through Celer
contract CelerFacet is Swapper, ReentrancyGuard, CelerMessageReceiver {
    using SafeMath for uint256;
    using LibBytes for bytes;

    /// Storage ///

    bytes32 internal constant NAMESPACE =
        hex"5a7c277686f4a9ab3396ccbfbeac4866fb97785944f0661a3f0935d16bc9848b"; // keccak256("com.so.facets.celer")

    uint256 public constant RAY = 1e27;
    uint256 public constant GasPerByte = 68;

    struct Storage {
        address messageBus; // The Celer MessageBus address
        address executorFeeTo; // The receiver of the executor fee.
        uint64 nextNonce; // The next nonce for celer bridge
        uint64 srcCelerChainId; // The Celer chain id of the source/current chain
        uint256 actualReserve; // [RAY]
        uint256 estimateReserve; // [RAY]
        mapping(uint64 => uint256) dstBaseGas; // For estimate destination chain execute gas
        mapping(address => bool) allowedList; // Permission to allow calls to executeMessageWithTransfer
    }

    /// Types ///

    struct CelerData {
        address sender;
        uint32 maxSlippage;  // The max slippage accepted
        uint64 dstCelerChainId; // The celer chain id of the destination chain
        address bridgeToken; // The bridge token address
        uint256 dstMaxGasPriceInWeiForExecutor; // The gas price on destination chain
        uint256 estimateCost; // The msg.value = message fee(for SGN) + executor fee(for executor) + native_gas(optional)
        address payable dstSoDiamond; // The destination SoDiamond address
    }

    struct CacheSrcSoSwap {
        bool flag;
        uint256 srcMessageFee;
        uint256 srcExecutorFee;
        uint256 srcMaybeInput;
        uint256 dstMaxGasForExecutor;
        uint256 bridgeAmount;
        bytes payload;
    }

    struct CacheCheck {
        bool flag;
        uint256 srcExecutorFee;
        uint256 userInput;
        uint256 dstMaxGasForExecutor;
        uint256 srsMessageFee;
        uint256 consumeValue;
    }

    struct CacheEstimate {
        ILibPriceV2 oracle;
        uint256 ratio;
        bytes message;
        uint256 srcMessageFee;
        uint256 dstExecutorGas;
        uint256 dstExecutorFee;
        uint256 srcExecutorFee;
        uint256 reserve;
    }

    struct CachePayload {
        address sender;
        ISo.NormalizedSoData soDataNo;
        LibSwap.NormalizedSwapData[] swapDataDstNo;
    }

    /// Events ///

    event CelerInitialized(address indexed messageBus, uint256 chainId);
    event SetMessageBus(address indexed messageBus);
    event SetAllowedList(address indexed messageBus, bool isAllowed);
    event UpdateCelerReserve(uint256 actualReserve, uint256 estimateReserve);
    event TransferFromCeler(
        bytes32 indexed celerTransferId,
        uint64 srcCelerChainId,
        uint64 dstCelerChainId,
        address bridgeToken,
        uint256 bridgeAmount,
        uint64 nonce
    );
    event RefundCelerToken(
        address indexed token,
        address sender,
        uint256 amount,
        bytes32 srcTxId
    );

    /// Init ///

    /// @notice Initializes local variables for the Celer MessgeBus
    /// @param messageBus: address of the Celer messageBus contract
    /// @param chainId: chainId of this deployed contract
    function initCeler(address messageBus, uint64 chainId) external {
        LibDiamond.enforceIsContractOwner();
        if (messageBus == address(0)) revert InvalidConfig();

        Storage storage s = getStorage();

        s.nextNonce = 1;
        s.messageBus = messageBus;
        s.executorFeeTo = LibDiamond.contractOwner();
        s.srcCelerChainId = chainId;
        s.actualReserve = (RAY).mul(11).div(10); // 110%
        s.estimateReserve = (RAY).mul(12).div(10); // 120%
        s.allowedList[messageBus] = true;
        s.allowedList[msg.sender] = true;

        emit CelerInitialized(messageBus, chainId);
    }

    /// @dev Set permissions to control calls to executeMessageWithTransfer
    function setAllowedAddress(address messageBus, bool isAllowed) external {
        LibDiamond.enforceIsContractOwner();

        Storage storage s = getStorage();
        s.allowedList[messageBus] = isAllowed;

        emit SetAllowedList(messageBus, isAllowed);
    }

    /// @dev Set new nonce
    /// Avoid celer revert "transfer exists" after redeploy this contract
    function setNonce(uint64 nonce) external
    {
        LibDiamond.enforceIsContractOwner();

        Storage storage s = getStorage();
        s.nextNonce = nonce;
    }

    /// @dev Set new receiver of the executor fee
    function setExecutorFeeTo(address feeTo) external
    {
        LibDiamond.enforceIsContractOwner();

        Storage storage s = getStorage();
        s.executorFeeTo = feeTo;
    }

    /// @dev Sets the scale to be used when calculating executor fees
    /// @param actualReserve percentage of actual use of executor fees, expressed as RAY
    /// @param estimateReserve estimated percentage of use at the time of call, expressed as RAY
    function setCelerReserve(uint256 actualReserve, uint256 estimateReserve) external
    {
        LibDiamond.enforceIsContractOwner();
        Storage storage s = getStorage();

        s.actualReserve = actualReserve;
        s.estimateReserve = estimateReserve;

        emit UpdateCelerReserve(actualReserve, estimateReserve);
    }

    /// @dev Set the minimum gas to be spent on the destination chain
    /// @param dstChainIds  a batch of destination chain id
    /// @param dstBaseGas  base gas for destination chain
    function setBaseGas(
        uint64[] calldata dstChainIds,
        uint256 dstBaseGas
    ) external {
        LibDiamond.enforceIsContractOwner();
        Storage storage s = getStorage();

        for (uint64 i; i < dstChainIds.length; i++ ) {
            s.dstBaseGas[dstChainIds[i]] = dstBaseGas;
        }
    }

    /// External Methods ///

    /// @notice Bridges tokens via Celer (support chainid [1,65535])
    /// @param soDataNo Data for tracking cross-chain transactions and a
    /// portion of the accompanying cross-chain messages
    /// @param swapDataSrcNo Contains a set of data required for Swap
    /// transactions on the source chain side
    /// @param celerData Data used to call Celer Message Bus for swap
    /// @param swapDataDstNo Contains a set of Swap transaction data executed
    /// on the destination chain.
    /// Call on source chain by user
    function soSwapViaCeler(
        ISo.NormalizedSoData calldata soDataNo,
        LibSwap.NormalizedSwapData[] calldata swapDataSrcNo,
        CelerData calldata celerData,
        LibSwap.NormalizedSwapData[] calldata swapDataDstNo
    ) external payable nonReentrant {
        require(msg.value == celerData.estimateCost, "FeeErr");

        CacheSrcSoSwap memory cache;

        // decode soDataNo and swapDataSrcNo
        ISo.SoData memory soData = LibCross.denormalizeSoData(soDataNo);
        LibSwap.SwapData[] memory swapDataSrc = LibCross.denormalizeSwapData(
            swapDataSrcNo
        );

        (
            cache.flag,
            cache.srcExecutorFee,
            cache.dstMaxGasForExecutor,
            cache.srcMaybeInput
        ) = checkExecutorFee(soDataNo, celerData, swapDataDstNo);

        require(cache.flag, "CheckFail");

        if (cache.srcExecutorFee > 0) {
            LibAsset.transferAsset(
                LibAsset.NATIVE_ASSETID,
                payable(getExecutorFeeTo()),
                cache.srcExecutorFee
            );
        }

        // deposit erc20 tokens to this contract
        if (!LibAsset.isNativeAsset(soData.sendingAssetId)) {
            LibAsset.depositAsset(soData.sendingAssetId, soData.amount);
        }

        // calculate bridgeAmount
        if (swapDataSrc.length == 0) {
            // direct bridge
            cache.bridgeAmount = soData.amount;
            transferWrappedAsset(
                soData.sendingAssetId,
                celerData.bridgeToken,
                cache.bridgeAmount
            );
        } else {
            // bridge after swap
            require(soData.amount == swapDataSrc[0].fromAmount, "AmountErr");
            try this.executeAndCheckSwaps(soData, swapDataSrc) returns (
                uint256 bridgeAmount
            ) {
                cache.bridgeAmount = bridgeAmount;
                transferWrappedAsset(
                    swapDataSrc[swapDataSrc.length - 1].receivingAssetId,
                    celerData.bridgeToken,
                    cache.bridgeAmount
                );
            } catch (bytes memory lowLevelData) {
                // Rethrowing exception
                assembly {
                    let start := add(lowLevelData, 0x20)
                    let end := add(lowLevelData, mload(lowLevelData))
                    revert(start, end)
                }
            }
        }

        cache.payload = encodeCelerPayload(
            celerData.sender,
            soDataNo,
            swapDataDstNo
        );

        cache.srcMessageFee = getCelerMessageFee2(cache.payload);

        startBridge(
            celerData,
            cache.srcMessageFee,
            cache.bridgeAmount,
            cache.payload
        );

        uint256 returnValue = msg.value
            .sub(cache.srcMessageFee)
            .sub(cache.srcExecutorFee)
            .sub(cache.srcMaybeInput);

        // return the redundant msg.value
        if (returnValue > 0) {
            LibAsset.transferAsset(
                LibAsset.NATIVE_ASSETID,
                payable(msg.sender),
                returnValue
            );
        }

        emit SoTransferStarted(soData.transactionId);
    }

    /// @notice Called by Celer MessageBus to execute a message with an associated token transfer.
    /// Call on destination chain by executor
    function executeMessageWithTransfer(
        address, //sender,
        address token,
        uint256 amount,
        uint64, // srcChainId
        bytes calldata message,
        address // executor
    ) external payable override returns (ExecutionStatus) {
        Storage storage s = getStorage();
        require(s.allowedList[msg.sender], "No permission");

        if (LibAsset.getOwnBalance(token) < amount) {
            // judge eth
            require(token == this.getNativeWrap(s.messageBus), "TokenErr");
            require(
                LibAsset.getOwnBalance(LibAsset.NATIVE_ASSETID) >= amount,
                "NotEnough"
            );

            token = LibAsset.NATIVE_ASSETID;
        }

        (
            ,
            ISo.NormalizedSoData memory soDataNo,
            LibSwap.NormalizedSwapData[] memory swapDataDstNo
        ) = decodeCelerPayload(message);

        ISo.SoData memory soData = LibCross.denormalizeSoData(soDataNo);
        LibSwap.SwapData[] memory swapDataDst = LibCross.denormalizeSwapData(
            swapDataDstNo
        );

        remoteSoSwap(token, amount, soData, swapDataDst);

        return ExecutionStatus.Success;
    }

    /// @notice Called by MessageBus to process refund of the original transfer from this contract.
    /// The contract is guaranteed to have received the refund before this function is called.
    /// Call on source chain by executor
    function executeMessageWithTransferRefund(
        address token,
        uint256 amount,
        bytes calldata message,
        address // executor
    ) external payable override returns (ExecutionStatus) {
        Storage storage s = getStorage();
        require(s.allowedList[msg.sender], "No permission");

        (
            address sender,
            ISo.NormalizedSoData memory soDataNo,
        ) = decodeCelerPayload(message);

        ISo.SoData memory soData = LibCross.denormalizeSoData(soDataNo);

        if (sender != address(0)) {
            LibAsset.transferAsset(
                token,
                payable(sender),
                amount
            );
        }

        emit RefundCelerToken(
            token,
            sender,
            amount,
            soData.transactionId
        );

        return ExecutionStatus.Success;
    }
    /// Public Methods ///

    /// @dev Check if enough value is passed in for payment
    function checkExecutorFee(
        ISo.NormalizedSoData calldata soData,
        CelerData calldata celerData,
        LibSwap.NormalizedSwapData[] calldata swapDataDst
    ) public returns (bool, uint256, uint256, uint256)
    {
        CacheCheck memory data;
        Storage storage s = getStorage();

        require(appStorage.gatewaySoFeeSelectors[s.messageBus] != address(0), "SoFeeEmpty");
        ILibPriceV2 oracle = ILibPriceV2(appStorage.gatewaySoFeeSelectors[s.messageBus]);

        oracle.updatePriceRatio(celerData.dstCelerChainId);

        (
            data.srsMessageFee,
            data.dstMaxGasForExecutor,
            data.srcExecutorFee
        ) = estCelerMessageFeeAndExecutorFee(
            celerData.dstCelerChainId,
            celerData.dstMaxGasPriceInWeiForExecutor,
            soData,
            swapDataDst,
            true
        );

        if (LibAsset.isNativeAsset(soData.sendingAssetId.toAddress(0))) {
            data.userInput = soData.amount;
        }

        data.consumeValue = data.srsMessageFee.add(data.srcExecutorFee).add(data.userInput);

        if (data.consumeValue <= celerData.estimateCost) {
            data.flag = true;
        }

        return (data.flag, data.srcExecutorFee, data.dstMaxGasForExecutor, data.userInput);
    }

    /// CrossData
    // 1. length + sender
    // 2. length + transactionId(SoData)
    // 3. length + receiver(SoData)
    // 4. length + receivingAssetId(SoData)
    // 5. length + swapDataLength(u8)
    // 6. length + callTo(SwapData)
    // 7. length + sendingAssetId(SwapData)
    // 8. length + receivingAssetId(SwapData)
    // 9. length + callData(SwapData)
    function encodeCelerPayload(
        address sender,
        ISo.NormalizedSoData memory soDataNo,
        LibSwap.NormalizedSwapData[] memory swapDataDstNo
    ) public pure returns (bytes memory) {
        bytes memory senderByte = abi.encodePacked(sender);

        bytes memory encodeData = abi.encodePacked(
            uint8(senderByte.length),
            senderByte,
            uint8(soDataNo.transactionId.length),
            soDataNo.transactionId,
            uint8(soDataNo.receiver.length),
            soDataNo.receiver,
            uint8(soDataNo.receivingAssetId.length),
            soDataNo.receivingAssetId
        );

        if (swapDataDstNo.length > 0) {
            bytes memory swapLenBytes = LibCross.serializeU256WithHexStr(
                swapDataDstNo.length
            );
            encodeData = encodeData.concat(
                abi.encodePacked(uint8(swapLenBytes.length), swapLenBytes)
            );
        }

        for (uint256 i = 0; i < swapDataDstNo.length; i++) {
            encodeData = encodeData.concat(
                abi.encodePacked(
                    uint8(swapDataDstNo[i].callTo.length),
                    swapDataDstNo[i].callTo,
                    uint8(swapDataDstNo[i].sendingAssetId.length),
                    swapDataDstNo[i].sendingAssetId,
                    uint8(swapDataDstNo[i].receivingAssetId.length),
                    swapDataDstNo[i].receivingAssetId,
                    uint16(swapDataDstNo[i].callData.length),
                    swapDataDstNo[i].callData
                )
            );
        }
        return encodeData;
    }

    /// CrossData
    // 1. length + sender
    // 2. length + transactionId(SoData)
    // 3. length + receiver(SoData)
    // 4. length + receivingAssetId(SoData)
    // 5. length + swapDataLength(u8)
    // 6. length + callTo(SwapData)
    // 7. length + sendingAssetId(SwapData)
    // 8. length + receivingAssetId(SwapData)
    // 9. length + callData(SwapData)
    function decodeCelerPayload(
        bytes memory celerPayload
    ) public pure returns (
        address,
        ISo.NormalizedSoData memory soDataNo,
        LibSwap.NormalizedSwapData[] memory swapDataDstNo
    )
    {
        CachePayload memory data;
        uint256 index;
        uint256 nextLen;

        nextLen = uint256(celerPayload.toUint8(index));
        index += 1;
        data.sender = LibCross.tryAddress(
            celerPayload.slice(index, nextLen)
        );
        index += nextLen;

        nextLen = uint256(celerPayload.toUint8(index));
        index += 1;
        data.soDataNo.transactionId = celerPayload.slice(index, nextLen);
        index += nextLen;

        nextLen = uint256(celerPayload.toUint8(index));
        index += 1;
        data.soDataNo.receiver = celerPayload.slice(index, nextLen);
        index += nextLen;

        nextLen = uint256(celerPayload.toUint8(index));
        index += 1;
        data.soDataNo.receivingAssetId = celerPayload.slice(index, nextLen);
        index += nextLen;

        if (index < celerPayload.length) {
            nextLen = uint256(celerPayload.toUint8(index));
            index += 1;
            uint256 swap_len = LibCross.deserializeU256WithHexStr(
                celerPayload.slice(index, nextLen)
            );
            index += nextLen;

            data.swapDataDstNo = new LibSwap.NormalizedSwapData[](swap_len);
            for (uint256 i = 0; i < swap_len; i++) {
                nextLen = uint256(celerPayload.toUint8(index));
                index += 1;
                data.swapDataDstNo[i].callTo = celerPayload.slice(
                    index,
                    nextLen
                );
                data.swapDataDstNo[i].approveTo = data.swapDataDstNo[i].callTo;
                index += nextLen;

                nextLen = uint256(celerPayload.toUint8(index));
                index += 1;
                data.swapDataDstNo[i].sendingAssetId = celerPayload.slice(
                    index,
                    nextLen
                );
                index += nextLen;

                nextLen = uint256(celerPayload.toUint8(index));
                index += 1;
                data.swapDataDstNo[i].receivingAssetId = celerPayload.slice(
                    index,
                    nextLen
                );
                index += nextLen;

                nextLen = uint256(celerPayload.toUint16(index));
                index += 2;
                data.swapDataDstNo[i].callData = celerPayload.slice(
                    index,
                    nextLen
                );
                index += nextLen;
            }
        }
        require(index == celerPayload.length, "LenErr");

        return (
            data.sender,
            data.soDataNo,
            data.swapDataDstNo
        );
    }

    /// @dev Estimate celer cross-chain message fee and executor fee
    function estCelerMessageFeeAndExecutorFee(
        uint64 dstCelerChainId,
        uint256 dstMaxGasPriceInWeiForExecutor,
        ISo.NormalizedSoData calldata soDataNo,
        LibSwap.NormalizedSwapData[] calldata swapDataDstNo,
        bool is_actual
    ) public view returns (uint256, uint256, uint256) {
        CacheEstimate memory c;
        Storage storage s = getStorage();

        require(appStorage.gatewaySoFeeSelectors[s.messageBus] != address(0), "SoFeeEmpty");
        c.oracle = ILibPriceV2(appStorage.gatewaySoFeeSelectors[s.messageBus]);

        (c.ratio, ) = c.oracle.getPriceRatio(dstCelerChainId);

        // Only for estimate gas
        c.message = encodeCelerPayload(
            address(0),
            soDataNo,
            swapDataDstNo
        );

        c.srcMessageFee = getCelerMessageFee1(s.messageBus, c.message);

        c.dstExecutorGas = s.dstBaseGas[dstCelerChainId]
            .add(GasPerByte.mul(c.message.length));

        c.dstExecutorFee = c.dstExecutorGas.mul(dstMaxGasPriceInWeiForExecutor);

        if (is_actual) {
            c.reserve = s.actualReserve;
        } else {
            c.reserve = s.estimateReserve;
        }

        c.srcExecutorFee = c.dstExecutorFee
            .mul(c.ratio)
            .div(c.oracle.RAY())
            .mul(c.reserve)
            .div(RAY);

        return (c.srcMessageFee, c.dstExecutorGas, c.srcExecutorFee);
    }

    /// @dev Calculate celer message fee
    function getCelerMessageFee1(
        address messageBus,
        bytes memory message
    ) public view returns (uint256) {
        return ICelerMessageBus(messageBus).calcFee(message);
    }

    /// @dev Calculate celer message fee
    function getCelerMessageFee2(
        bytes memory message
    ) public view returns (uint256) {
        Storage storage s = getStorage();
        return getCelerMessageFee1(s.messageBus, message);
    }

    /// @dev Get celer native wrap address
    function getNativeWrap(address messageBus) public view returns (address) {
        address bridge = ICelerMessageBus(messageBus).liquidityBridge();

        return ICelerBridge(bridge).nativeWrap();
    }

    /// @dev Get so fee
    function getCelerSoFee(uint256 amount) public view returns (uint256) {
        Storage storage s = getStorage();
        address soFee = appStorage.gatewaySoFeeSelectors[s.messageBus];
        if (soFee == address(0x0)) {
            return 0;
        } else {
            return ILibSoFee(soFee).getFees(amount);
        }
    }

    /// @dev Get nonce
    function getNonce() public view returns (uint64) {
        Storage storage s = getStorage();
        return s.nextNonce;
    }

    /// @dev Get base gas of destination chain
    function getBaseGas(uint64 dstChainId) public view returns(uint256) {
        Storage storage s = getStorage();
        return s.dstBaseGas[dstChainId];
    }

    /// @dev Get the receiver of the executor fee
    function getExecutorFeeTo() public view returns(address) {
        Storage storage s = getStorage();
        return s.executorFeeTo;
    }

    /// Private Methods ///

    /// @dev swap on destination chain
    function remoteSoSwap(
        address token,
        uint256 amount,
        ISo.SoData memory soData,
        LibSwap.SwapData[] memory swapDataDst
    ) private {
        uint256 soFee = getCelerSoFee(amount);
        if (soFee < amount) {
            amount = amount.sub(soFee);
        }

        if (swapDataDst.length == 0) {
            require(token == soData.receivingAssetId, "TokenErr");

            if (soFee > 0) {
                transferUnwrappedAsset(
                    token,
                    soData.receivingAssetId,
                    soFee,
                    LibDiamond.contractOwner()
                );
            }
            transferUnwrappedAsset(
                token,
                soData.receivingAssetId,
                amount,
                soData.receiver
            );
            emit SoTransferCompleted(soData.transactionId, amount);
        } else {
            require(token == swapDataDst[0].sendingAssetId, "TokenErr");

            if (soFee > 0) {
                transferUnwrappedAsset(
                    token,
                    swapDataDst[0].sendingAssetId,
                    soFee,
                    LibDiamond.contractOwner()
                );
            }
            transferUnwrappedAsset(
                token,
                swapDataDst[0].sendingAssetId,
                amount,
                address(this)
            );

            swapDataDst[0].fromAmount = amount;

            address correctSwap = appStorage.correctSwapRouterSelectors;

            if (correctSwap != address(0)) {
                swapDataDst[0].callData = ICorrectSwap(correctSwap).correctSwap(
                    swapDataDst[0].callData,
                    swapDataDst[0].fromAmount
                );
            }

            try this.executeAndCheckSwaps(soData, swapDataDst) returns (
                uint256 amountFinal
            ) {
                // may swap to weth
                transferUnwrappedAsset(
                    swapDataDst[swapDataDst.length - 1].receivingAssetId,
                    soData.receivingAssetId,
                    amountFinal,
                    soData.receiver
                );
                emit SoTransferCompleted(soData.transactionId, amountFinal);
            } catch Error(string memory revertReason) {
                LibAsset.transferAsset(
                    swapDataDst[0].sendingAssetId,
                    soData.receiver,
                    amount
                );
                emit SoTransferFailed(soData.transactionId, revertReason, bytes(""));
            } catch (bytes memory returnData) {
                LibAsset.transferAsset(
                    swapDataDst[0].sendingAssetId,
                    soData.receiver,
                    amount
                );
                emit SoTransferFailed(soData.transactionId, "", returnData);
            }
        }
    }

    /// @dev Checks for celer pool-based bridge
    function checkBridge(
        CelerData memory celerData,
        address messageBus,
        uint256 bridgeAmount
    ) private view {
        address bridge = ICelerMessageBus(messageBus).liquidityBridge();
        uint256 minSend = ICelerBridge(bridge).minSend(celerData.bridgeToken);
        uint256 maxSend = ICelerBridge(bridge).maxSend(celerData.bridgeToken);
        uint256 minMaxSlippage = ICelerBridge(bridge).minimalMaxSlippage();

        require(minSend < bridgeAmount && bridgeAmount <= maxSend, "bridgeAmountErr");
        require(celerData.maxSlippage > minMaxSlippage, "maxSlippageErr");
    }

    /// @dev Conatains the business logic for the bridge via Celer
    function startBridge(
        CelerData memory celerData,
        uint256 messageFee,
        uint256 bridgeAmount,
        bytes memory payload
    ) private {
        Storage storage s = getStorage();
        address messageBus = s.messageBus;

        if (s.srcCelerChainId == celerData.dstCelerChainId)
            revert CannotBridgeToSameNetwork();

        checkBridge(celerData, messageBus, bridgeAmount);

        // 2023.02: only evm chains
        bytes32 transferId = LibCelerMessageSender.sendMessageWithTransfer(
            celerData.dstSoDiamond,
            celerData.bridgeToken,
            bridgeAmount,
            celerData.dstCelerChainId,
            s.nextNonce,
            celerData.maxSlippage,
            payload,
            messageBus,
            messageFee
        );

        emit TransferFromCeler(
            transferId,
            s.srcCelerChainId,
            celerData.dstCelerChainId,
            celerData.bridgeToken,
            bridgeAmount,
            s.nextNonce
        );

        // Update nonce
        s.nextNonce = s.nextNonce + 1;
    }

    /// @dev fetch local storage
    function getStorage() private pure returns (Storage storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

error InvalidAmount(); // 0x2c5211c6
error TokenAddressIsZero(); // 0xdc2e5e8d
error CannotBridgeToSameNetwork(); // 0x4ac09ad3
error ZeroPostSwapBalance(); // 0xf74e8909
error InvalidBridgeConfigLength(); // 0x10502ef9
error NoSwapDataProvided(); // 0x0503c3ed
error NotSupportedSwapRouter(); // 0xe986f686
error NativeValueWithERC(); // 0x003f45b5
error ContractCallNotAllowed(); // 0x94539804
error NullAddrIsNotAValidSpender(); // 0x63ba9bff
error NullAddrIsNotAnERC20Token(); // 0xd1bebf0c
error NoTransferToNullAddress(); // 0x21f74345
error NativeAssetTransferFailed(); // 0x5a046737
error InvalidContract(); // 0x6eefed20
error InvalidConfig(); // 0x35be3ac8

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IDiamondCut} from "IDiamondCut.sol";

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

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

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            // solhint-disable-next-line avoid-low-level-calls
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

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
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
pragma solidity 0.8.13;

library LibBytes {
    // solhint-disable no-inline-assembly

    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function indexOf(
        bytes memory _bytes,
        uint8 _e,
        uint256 _start
    ) internal pure returns (uint256) {
        while (_start < _bytes.length) {
            if (toUint8(_bytes, _start) == _e) {
                return _start;
            }
            _start += 1;
        }
        return _bytes.length;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint32)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint64)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint96)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint128)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        // solhint-disable-next-line no-empty-blocks
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ISo} from "ISo.sol";
import {LibSwap} from "LibSwap.sol";
import {LibBytes} from "LibBytes.sol";

library LibCross {
    using LibBytes for bytes;

    function normalizeSoData(ISo.SoData memory soData)
        internal
        pure
        returns (ISo.NormalizedSoData memory)
    {
        ISo.NormalizedSoData memory data;
        data.transactionId = abi.encodePacked(soData.transactionId);
        data.receiver = abi.encodePacked(soData.receiver);
        data.sourceChainId = soData.sourceChainId;
        data.sendingAssetId = abi.encodePacked(soData.sendingAssetId);
        data.destinationChainId = soData.destinationChainId;
        data.receivingAssetId = abi.encodePacked(soData.receivingAssetId);
        data.amount = soData.amount;

        return data;
    }

    function tryAddress(bytes memory data) internal pure returns (address) {
        if (data.length == 20) {
            return data.toAddress(0);
        } else {
            return address(0);
        }
    }

    function denormalizeSoData(ISo.NormalizedSoData memory data)
        internal
        pure
        returns (ISo.SoData memory)
    {
        return
            ISo.SoData({
                transactionId: data.transactionId.toBytes32(0),
                receiver: payable(tryAddress(data.receiver)),
                sourceChainId: data.sourceChainId,
                sendingAssetId: tryAddress(data.sendingAssetId),
                destinationChainId: data.destinationChainId,
                receivingAssetId: tryAddress(data.receivingAssetId),
                amount: data.amount
            });
    }

    function normalizeSwapData(LibSwap.SwapData[] memory swapData)
        internal
        pure
        returns (LibSwap.NormalizedSwapData[] memory)
    {
        LibSwap.NormalizedSwapData[]
            memory data = new LibSwap.NormalizedSwapData[](swapData.length);

        for (uint256 i = 0; i < swapData.length; i++) {
            data[i].callTo = abi.encodePacked(swapData[i].callTo);
            data[i].approveTo = abi.encodePacked(swapData[i].approveTo);
            data[i].sendingAssetId = abi.encodePacked(
                swapData[i].sendingAssetId
            );
            data[i].receivingAssetId = abi.encodePacked(
                swapData[i].receivingAssetId
            );
            data[i].fromAmount = swapData[i].fromAmount;
            data[i].callData = abi.encodePacked(swapData[i].callData);
        }

        return data;
    }

    function denormalizeSwapData(LibSwap.NormalizedSwapData[] memory data)
        internal
        pure
        returns (LibSwap.SwapData[] memory)
    {
        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](
            data.length
        );
        for (uint256 i = 0; i < swapData.length; i++) {
            swapData[i].callTo = data[i].callTo.toAddress(0);
            swapData[i].approveTo = data[i].approveTo.toAddress(0);
            swapData[i].sendingAssetId = data[i].sendingAssetId.toAddress(0);
            swapData[i].receivingAssetId = data[i].receivingAssetId.toAddress(
                0
            );
            swapData[i].fromAmount = data[i].fromAmount;
            swapData[i].callData = data[i].callData;
        }
        return swapData;
    }

    function encodeNormalizedSoData(ISo.NormalizedSoData memory data)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encodeData = abi.encodePacked(
            uint64(data.transactionId.length),
            data.transactionId,
            uint64(data.receiver.length),
            data.receiver,
            data.sourceChainId
        );
        // Avoid variable value1 is 1 slot(s) too deep;
        encodeData = encodeData.concat(
            abi.encodePacked(
                uint64(data.sendingAssetId.length),
                data.sendingAssetId,
                data.destinationChainId,
                uint64(data.receivingAssetId.length),
                data.receivingAssetId,
                data.amount
            )
        );
        return encodeData;
    }

    function decodeNormalizedSoData(bytes memory soData)
        internal
        pure
        returns (ISo.NormalizedSoData memory)
    {
        ISo.NormalizedSoData memory data;
        uint256 index;
        uint256 nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.transactionId = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.receiver = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = 2;
        data.sourceChainId = soData.toUint16(index);
        index += nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.sendingAssetId = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = 2;
        data.destinationChainId = soData.toUint16(index);
        index += nextLen;

        nextLen = uint256(soData.toUint64(index));
        index += 8;
        data.receivingAssetId = soData.slice(index, nextLen);
        index += nextLen;

        nextLen = 32;
        data.amount = soData.toUint256(index);
        index += nextLen;

        require(index == soData.length, "Length error");

        return data;
    }

    function encodeNormalizedSwapData(LibSwap.NormalizedSwapData[] memory data)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encodeData = bytes("");

        if (data.length > 0) {
            encodeData = abi.encodePacked(uint64(data.length));
        }

        for (uint256 i = 0; i < data.length; i++) {
            encodeData = encodeData.concat(
                abi.encodePacked(
                    uint64(data[i].callTo.length),
                    data[i].callTo,
                    uint64(data[i].approveTo.length),
                    data[i].approveTo,
                    uint64(data[i].sendingAssetId.length),
                    data[i].sendingAssetId
                )
            );
            // Avoid variable value1 is 1 slot(s) too deep;
            encodeData = encodeData.concat(
                abi.encodePacked(
                    uint64(data[i].receivingAssetId.length),
                    data[i].receivingAssetId,
                    data[i].fromAmount,
                    uint64(data[i].callData.length),
                    data[i].callData
                )
            );
        }

        return encodeData;
    }

    function decodeNormalizedSwapData(bytes memory swapData)
        internal
        pure
        returns (LibSwap.NormalizedSwapData[] memory)
    {
        uint256 index;
        uint256 nextLen;

        nextLen = 8;
        uint256 swapLen = uint256(swapData.toUint64(index));
        index += nextLen;

        LibSwap.NormalizedSwapData[]
            memory data = new LibSwap.NormalizedSwapData[](swapLen);

        for (uint256 i = 0; i < swapLen; i++) {
            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].callTo = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].approveTo = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].sendingAssetId = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].receivingAssetId = swapData.slice(index, nextLen);
            index += nextLen;

            nextLen = 32;
            data[i].fromAmount = swapData.toUint256(index);
            index += nextLen;

            nextLen = uint256(swapData.toUint64(index));
            index += 8;
            data[i].callData = swapData.slice(index, nextLen);
            index += nextLen;
        }

        require(index == swapData.length, "Length error");

        return data;
    }

    function serializeU256WithHexStr(uint256 data)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encodeData = abi.encodePacked(uint8(data & 0xFF));
        data = data >> 8;

        while (data != 0) {
            encodeData = abi.encodePacked(uint8(data & 0xFF)).concat(
                encodeData
            );
            data = data >> 8;
        }
        return encodeData;
    }

    function deserializeU256WithHexStr(bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 buf = 0;
        for (uint256 i = 0; i < data.length; i++) {
            buf = (buf << 8) + data.toUint8(i);
        }
        return buf;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISo {
    /// Structs ///

    struct SoData {
        bytes32 transactionId; // unique identification id
        address payable receiver; // token receiving account
        uint16 sourceChainId; // source chain id
        address sendingAssetId; // The starting token address of the source chain
        uint16 destinationChainId; // destination chain id
        address receivingAssetId; // The final token address of the destination chain
        uint256 amount; // User enters amount
    }

    struct NormalizedSoData {
        bytes transactionId; // unique identification id
        bytes receiver; // token receiving account
        uint16 sourceChainId; // source chain id
        bytes sendingAssetId; // The starting token address of the source chain
        uint16 destinationChainId; // destination chain id
        bytes receivingAssetId; // The final token address of the destination chain
        uint256 amount; // User enters amount
    }

    /// Events ///

    event SoTransferStarted(bytes32 indexed transactionId);

    event SoTransferFailed(
        bytes32 indexed transactionId,
        string revertReason,
        bytes otherReason
    );

    event SoTransferCompleted(
        bytes32 indexed transactionId,
        uint256 receiveAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LibAsset, IERC20} from "LibAsset.sol";
import {LibUtil} from "LibUtil.sol";
import {InvalidContract} from "GenericErrors.sol";

library LibSwap {
    error NoSwapFromZeroBalance();

    struct SwapData {
        address callTo; // The swap address
        address approveTo; // The swap address
        address sendingAssetId; // The swap start token address
        address receivingAssetId; // The swap final token address
        uint256 fromAmount; // The swap start token amount
        bytes callData; // The swap callData
    }

    struct NormalizedSwapData {
        bytes callTo; // The swap address
        bytes approveTo; // The swap address
        bytes sendingAssetId; // The swap start token address
        bytes receivingAssetId; // The swap final token address
        uint256 fromAmount; // The swap start token amount
        bytes callData; // The swap callData
    }

    event AssetSwapped(
        bytes32 transactionId,
        address dex,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 timestamp
    );

    function swap(bytes32 transactionId, SwapData memory _swapData) internal {
        if (!LibAsset.isContract(_swapData.callTo)) revert InvalidContract();
        uint256 fromAmount = _swapData.fromAmount;
        if (fromAmount == 0) revert NoSwapFromZeroBalance();
        uint256 nativeValue = 0;
        address fromAssetId = _swapData.sendingAssetId;
        address toAssetId = _swapData.receivingAssetId;
        uint256 initialSendingAssetBalance = LibAsset.getOwnBalance(
            fromAssetId
        );
        uint256 initialReceivingAssetBalance = LibAsset.getOwnBalance(
            toAssetId
        );
        uint256 toDeposit = initialSendingAssetBalance < fromAmount
            ? fromAmount - initialSendingAssetBalance
            : 0;

        if (!LibAsset.isNativeAsset(fromAssetId)) {
            LibAsset.maxApproveERC20(
                IERC20(fromAssetId),
                _swapData.approveTo,
                fromAmount
            );
            if (toDeposit != 0) {
                LibAsset.transferFromERC20(
                    fromAssetId,
                    msg.sender,
                    address(this),
                    toDeposit
                );
            }
        } else {
            nativeValue = fromAmount;
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory res) = _swapData.callTo.call{
            value: nativeValue
        }(_swapData.callData);
        if (!success) {
            string memory reason = LibUtil.getRevertMsg(res);
            revert(reason);
        }

        emit AssetSwapped(
            transactionId,
            _swapData.callTo,
            _swapData.sendingAssetId,
            toAssetId,
            fromAmount,
            LibAsset.getOwnBalance(toAssetId) - initialReceivingAssetBalance,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
import {NullAddrIsNotAnERC20Token, NullAddrIsNotAValidSpender, NoTransferToNullAddress, InvalidAmount, NativeValueWithERC, NativeAssetTransferFailed} from "GenericErrors.sol";
import "SafeERC20.sol";
import "IERC20.sol";

/// @title LibAsset
/// @author Connext <[email protected]>
/// @notice This library contains helpers for dealing with onchain transfers
///         of assets, including accounting for the native asset `assetId`
///         conventions and any noncompliant ERC20 transfers
library LibAsset {
    uint256 private constant MAX_INT = type(uint256).max;

    address internal constant NULL_ADDRESS =
        0x0000000000000000000000000000000000000000; //address(0)

    /// @dev All native assets use the empty address for their asset id
    ///      by convention

    address internal constant NATIVE_ASSETID = NULL_ADDRESS; //address(0)

    /// @notice Gets the balance of the inheriting contract for the given asset
    /// @param assetId The asset identifier to get the balance of
    /// @return Balance held by contracts using this library
    function getOwnBalance(address assetId) internal view returns (uint256) {
        return
            assetId == NATIVE_ASSETID
                ? address(this).balance
                : IERC20(assetId).balanceOf(address(this));
    }

    /// @notice Transfers ether from the inheriting contract to a given
    ///         recipient
    /// @param recipient Address to send ether to
    /// @param amount Amount to send to given recipient
    function transferNativeAsset(address payable recipient, uint256 amount)
        private
    {
        if (recipient == NULL_ADDRESS) revert NoTransferToNullAddress();
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert NativeAssetTransferFailed();
    }

    /// @notice Gives MAX approval for another address to spend tokens
    /// @param assetId Token address to transfer
    /// @param spender Address to give spend approval to
    /// @param amount Amount to approve for spending
    function maxApproveERC20(
        IERC20 assetId,
        address spender,
        uint256 amount
    ) internal {
        if (address(assetId) == NATIVE_ASSETID) return;
        if (spender == NULL_ADDRESS) revert NullAddrIsNotAValidSpender();
        uint256 allowance = assetId.allowance(address(this), spender);
        if (allowance < amount)
            SafeERC20.safeApprove(IERC20(assetId), spender, MAX_INT);
    }

    /// @notice Transfers tokens from the inheriting contract to a given
    ///         recipient
    /// @param assetId Token address to transfer
    /// @param recipient Address to send token to
    /// @param amount Amount to send to given recipient
    function transferERC20(
        address assetId,
        address recipient,
        uint256 amount
    ) private {
        if (isNativeAsset(assetId)) revert NullAddrIsNotAnERC20Token();
        SafeERC20.safeTransfer(IERC20(assetId), recipient, amount);
    }

    /// @notice Transfers tokens from a sender to a given recipient
    /// @param assetId Token address to transfer
    /// @param from Address of sender/owner
    /// @param to Address of recipient/spender
    /// @param amount Amount to transfer from owner to spender
    function transferFromERC20(
        address assetId,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (assetId == NATIVE_ASSETID) revert NullAddrIsNotAnERC20Token();
        if (to == NULL_ADDRESS) revert NoTransferToNullAddress();
        SafeERC20.safeTransferFrom(IERC20(assetId), from, to, amount);
    }

    /// @notice Deposits an asset into the contract and performs checks to avoid NativeValueWithERC
    /// @param tokenId Token to deposit
    /// @param amount Amount to deposit
    /// @param isNative Wether the token is native or ERC20
    function depositAsset(
        address tokenId,
        uint256 amount,
        bool isNative
    ) internal {
        if (amount == 0) revert InvalidAmount();
        if (isNative) {
            if (msg.value != amount) revert InvalidAmount();
        } else {
            //            if (msg.value != 0) revert NativeValueWithERC();
            uint256 _fromTokenBalance = LibAsset.getOwnBalance(tokenId);
            LibAsset.transferFromERC20(
                tokenId,
                msg.sender,
                address(this),
                amount
            );
            if (LibAsset.getOwnBalance(tokenId) - _fromTokenBalance != amount)
                revert InvalidAmount();
        }
    }

    /// @notice Overload for depositAsset(address tokenId, uint256 amount, bool isNative)
    /// @param tokenId Token to deposit
    /// @param amount Amount to deposit
    function depositAsset(address tokenId, uint256 amount) internal {
        return depositAsset(tokenId, amount, tokenId == NATIVE_ASSETID);
    }

    /// @notice Determines whether the given assetId is the native asset
    /// @param assetId The asset identifier to evaluate
    /// @return Boolean indicating if the asset is the native asset
    function isNativeAsset(address assetId) internal pure returns (bool) {
        return assetId == NATIVE_ASSETID;
    }

    /// @notice Wrapper function to transfer a given asset (native or erc20) to
    ///         some recipient. Should handle all non-compliant return value
    ///         tokens as well by using the SafeERC20 contract by open zeppelin.
    /// @param assetId Asset id for transfer (address(0) for native asset,
    ///                token address for erc20s)
    /// @param recipient Address to send asset to
    /// @param amount Amount to send to given recipient
    function transferAsset(
        address assetId,
        address payable recipient,
        uint256 amount
    ) internal {
        (assetId == NATIVE_ASSETID)
            ? transferNativeAsset(recipient, amount)
            : transferERC20(assetId, recipient, amount);
    }

    /// @dev Checks whether the given address is a contract and contains code
    function isContract(address contractAddr) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(contractAddr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
pragma solidity 0.8.13;

import "LibBytes.sol";

library LibUtil {
    using LibBytes for bytes;

    function getRevertMsg(bytes memory _res)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) return "Transaction reverted silently";
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }

    function getSlice(
        bytes memory _data,
        uint256 _start,
        uint256 _end
    ) internal pure returns (bytes memory) {
        require(_start < _end && _end <= _data.length, "DataLength error!");
        bytes memory _out = bytes("");
        for (uint256 i = _start; i < _end; i++) {
            _out = bytes.concat(_out, _data[i]);
        }
        return _out;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "IERC20.sol";
import "SafeERC20.sol";
import "ICelerMessageBus.sol";
import "ICelerBridge.sol";

library LibCelerMessageSender {
    using SafeERC20 for IERC20;

    // ============== Internal library functions called by apps ==============

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        (bytes32 transferId, address bridge) = sendTokenTransfer(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            _nonce,
            _maxSlippage,
            _messageBus
        );
        if (_message.length > 0) {
            ICelerMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
                _receiver,
                _dstChainId,
                bridge,
                transferId,
                _message
            );
        }
        return transferId;
    }

    /**
     * @notice Sends a token transfer via a bridge.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     */
    function sendTokenTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        address _messageBus
    ) internal returns (bytes32 transferId, address bridge) {
        // Only applicable to the {MsgDataTypes.BridgeSendType.Liquidity}
        bridge = ICelerMessageBus(_messageBus).liquidityBridge();
        IERC20(_token).safeIncreaseAllowance(bridge, _amount);
        ICelerBridge(bridge).send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
        transferId = computeLiqBridgeTransferId(_receiver, _token, _amount, _dstChainId, _nonce);
    }

    function computeLiqBridgeTransferId(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(address(this), _receiver, _token, _amount, _dstChainId, _nonce, uint64(block.chainid))
            );
    }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "LibCelerMsgDataTypes.sol";

interface ICelerMessageBus {
    /**
     * @notice Send a message to a contract on another chain.
     * Sender needs to make sure the uniqueness of the message Id, which is computed as
     * hash(type.MessageOnly, sender, receiver, srcChainId, srcTxHash, dstChainId, message).
     * If messages with the same Id are sent, only one of them will succeed at dst chain..
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable;

    // same as above, except that receiver is an non-evm chain address,
    function sendMessage(
        bytes calldata _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Send a message associated with a token transfer to a contract on another chain.
     * If messages with the same srcTransferId are sent, only one of them will succeed at dst chain..
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        LibCelerMsgDataTypes.RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        LibCelerMsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        LibCelerMsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) external view returns (uint256);

    function liquidityBridge() external view returns (address);

    function pegBridge() external view returns (address);

    function pegBridgeV2() external view returns (address);

    function pegVault() external view returns (address);

    function pegVaultV2() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library LibCelerMsgDataTypes {
    string constant ABORT_PREFIX = "MSG::ABORT:";

    // bridge operation type at the sender side (src chain)
    enum BridgeSendType {
        Null,
        Liquidity,
        PegDeposit,
        PegBurn,
        PegV2Deposit,
        PegV2Burn,
        PegV2BurnFrom
    }

    // bridge operation type at the receiver side (dst chain)
    enum TransferType {
        Null,
        LqRelay, // relay through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw, // withdraw from original token vault
        PegV2Mint, // mint through pegged token bridge v2
        PegV2Withdraw // withdraw from original token vault v2
    }

    enum MsgType {
        MessageWithTransfer,
        MessageOnly
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback,
        Pending // transient state within a transaction
    }

    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 wdseq; // only needed for LqWithdraw (refund)
        uint64 srcChainId;
        bytes32 refId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    // used for msg from non-evm chains with longer-bytes address
    struct RouteInfo2 {
        bytes sender;
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash;
    }

    // combination of RouteInfo and RouteInfo2 for easier processing
    struct Route {
        address sender; // from RouteInfo
        bytes senderBytes; // from RouteInfo2
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash;
    }

    struct MsgWithTransferExecutionParams {
        bytes message;
        TransferInfo transfer;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }

    struct BridgeTransferParams {
        bytes request;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface ICelerBridge {
    // liquidity events
    event Send(
        bytes32 transferId,
        address sender,
        address receiver,
        address token,
        uint256 amount,
        uint64 dstChainId,
        uint64 nonce,
        uint32 maxSlippage
    );

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

    function minSend(address _token) external view returns (uint256);

    function maxSend(address _token) external view returns (uint256);

    function minimalMaxSlippage() external view returns (uint32);

    function nativeWrap() external view returns (address);

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ILibSoFee {
    function getFees(uint256 _amount) external view returns (uint256 s);

    function getRestoredAmount(uint256 _amount)
        external
        view
        returns (uint256 r);

    function getTransferForGas() external view returns (uint256);

    function getVersion() external view returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

// Celer chain id is u64, stargate and wormhole are u16
// ILibPriceV2 for Celer bridge
interface ILibPriceV2 {
    function getPriceRatio(uint64 _chainId) external view returns (uint256, bool);

    function updatePriceRatio(uint64 _chainId) external returns (uint256);

    function RAY() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IWETH} from "IWETH.sol";
import {ISo} from "ISo.sol";
import {ICorrectSwap} from "ICorrectSwap.sol";
import {LibSwap} from "LibSwap.sol";
import {LibAsset} from "LibAsset.sol";
import {LibUtil} from "LibUtil.sol";
import {LibStorage} from "LibStorage.sol";
import {LibAsset} from "LibAsset.sol";
import {InvalidAmount, ContractCallNotAllowed, NoSwapDataProvided, NotSupportedSwapRouter} from "GenericErrors.sol";

/// @title Swapper
/// @notice Abstract contract to provide swap functionality
contract Swapper is ISo {
    /// Storage ///

    LibStorage internal appStorage;

    /// Modifiers ///

    /// @dev Sends any leftover balances back to the user
    modifier noLeftovers(LibSwap.SwapData[] calldata swapData) {
        uint256 nSwaps = swapData.length;
        if (nSwaps != 1) {
            uint256[] memory initialBalances = _fetchBalances(swapData);
            address finalAsset = swapData[nSwaps - 1].receivingAssetId;
            uint256 curBalance = 0;

            _;

            for (uint256 i = 0; i < nSwaps - 1; i++) {
                address curAsset = swapData[i].receivingAssetId;
                if (curAsset == finalAsset) continue; // Handle multi-to-one swaps
                curBalance =
                    LibAsset.getOwnBalance(curAsset) -
                    initialBalances[i];
                if (curBalance > 0)
                    LibAsset.transferAsset(
                        curAsset,
                        payable(msg.sender),
                        curBalance
                    );
            }
        } else _;
    }

    /// External Methods ///

    /// @dev Validates input before executing swaps
    /// @param soData So tracking data
    /// @param swapData Array of data used to execute swaps
    function executeAndCheckSwaps(
        SoData memory soData,
        LibSwap.SwapData[] calldata swapData
    ) external returns (uint256) {
        require(msg.sender == address(this), "NotDiamond");
        uint256 nSwaps = swapData.length;
        if (nSwaps == 0) revert NoSwapDataProvided();
        address finalTokenId = swapData[swapData.length - 1].receivingAssetId;
        uint256 swapBalance = LibAsset.getOwnBalance(finalTokenId);
        _executeSwaps(soData, swapData);
        swapBalance = LibAsset.getOwnBalance(finalTokenId) - swapBalance;
        if (swapBalance == 0) revert InvalidAmount();
        return swapBalance;
    }

    /// Internal Methods ///

    /// @dev Convert eth to wrapped eth and Transfer.
    function transferWrappedAsset(
        address currentAssetId,
        address expectAssetId,
        uint256 amount
    ) internal {
        if (currentAssetId == expectAssetId) {
            require(
                LibAsset.getOwnBalance(currentAssetId) >= amount,
                "NotEnough"
            );
            return;
        }

        if (LibAsset.isNativeAsset(currentAssetId)) {
            // eth -> weth
            try IWETH(expectAssetId).deposit{value: amount}() {} catch {
                revert("DepositErr");
            }
        } else {
            // weth -> eth -> weth
            if (currentAssetId != expectAssetId) {
                try IWETH(currentAssetId).withdraw(amount) {} catch {
                    revert("DepositWithdrawErr");
                }
                try IWETH(expectAssetId).deposit{value: amount}() {} catch {
                    revert("WithdrawDepositErr");
                }
            }
        }
    }

    /// @dev Convert wrapped eth to eth and Transfer.
    function transferUnwrappedAsset(
        address currentAssetId,
        address expectAssetId,
        uint256 amount,
        address receiver
    ) internal {
        if (LibAsset.isNativeAsset(expectAssetId)) {
            if (currentAssetId != expectAssetId) {
                try IWETH(currentAssetId).withdraw(amount) {} catch {
                    revert("WithdrawErr");
                }
            }
        } else {
            require(currentAssetId == expectAssetId, "AssetIdErr");
        }
        if (receiver != address(this)) {
            require(
                LibAsset.getOwnBalance(expectAssetId) >= amount,
                "NotEnough"
            );
            LibAsset.transferAsset(expectAssetId, payable(receiver), amount);
        }
    }

    /// Private Methods ///

    /// @dev Executes swaps and checks that DEXs used are in the allowList
    /// @param soData So tracking data
    /// @param swapData Array of data used to execute swaps
    function _executeSwaps(
        SoData memory soData,
        LibSwap.SwapData[] calldata swapData
    ) private {
        LibSwap.SwapData memory currentSwapData = swapData[0];
        for (uint256 i = 0; i < swapData.length; i++) {
            address receivedToken = currentSwapData.receivingAssetId;
            uint256 swapBalance = LibAsset.getOwnBalance(receivedToken);

            if (
                !(appStorage.dexAllowlist[currentSwapData.approveTo] &&
                    appStorage.dexAllowlist[currentSwapData.callTo] &&
                    appStorage.dexFuncSignatureAllowList[
                        bytes32(
                            LibUtil.getSlice(currentSwapData.callData, 0, 4)
                        )
                    ])
            ) revert ContractCallNotAllowed();

            LibSwap.swap(soData.transactionId, currentSwapData);

            swapBalance = LibAsset.getOwnBalance(receivedToken) - swapBalance;

            if (i + 1 < swapData.length) {
                currentSwapData = swapData[i + 1];
                address correctSwap = appStorage.correctSwapRouterSelectors;
                if (correctSwap == address(0)) revert NotSupportedSwapRouter();
                currentSwapData.fromAmount = swapBalance;
                currentSwapData.callData = ICorrectSwap(correctSwap)
                    .correctSwap(
                        currentSwapData.callData,
                        currentSwapData.fromAmount
                    );
            }
        }
    }

    /// @dev Fetches balances of tokens to be swapped before swapping.
    /// @param swapData Array of data used to execute swaps
    /// @return uint256[] Array of token balances.
    function _fetchBalances(LibSwap.SwapData[] calldata swapData)
        private
        view
        returns (uint256[] memory)
    {
        uint256 length = swapData.length;
        uint256[] memory balances = new uint256[](length);
        for (uint256 i = 0; i < length; i++)
            balances[i] = LibAsset.getOwnBalance(swapData[i].receivingAssetId);
        return balances;
    }
}

pragma solidity 0.8.13;

import "IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ICorrectSwap {
    function correctSwap(bytes calldata, uint256)
        external
        pure
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct LibStorage {
    mapping(address => bool) dexAllowlist;
    mapping(bytes32 => bool) dexFuncSignatureAllowList;
    address[] dexs;
    // maps gateway facet addresses to sofee address
    mapping(address => address) gatewaySoFeeSelectors;
    // Storage correct swap address
    address correctSwapRouterSelectors;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title Reentrancy Guard
/// @author LI.FI (https://li.fi)
/// @notice Abstract contract to provide protection against reentrancy
abstract contract ReentrancyGuard {
    /// Storage ///

    bytes32 private constant NAMESPACE =
        hex"a65bb2f450488ab0858c00edc14abc5297769bf42adb48cfb77752890e8b697b";

    /// Types ///

    struct ReentrancyStorage {
        uint256 status;
    }

    /// Errors ///

    error ReentrancyError();

    /// Constants ///

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    /// Modifiers ///

    modifier nonReentrant() {
        ReentrancyStorage storage s = reentrancyStorage();
        if (s.status == _ENTERED) revert ReentrancyError();
        s.status = _ENTERED;
        _;
        s.status = _NOT_ENTERED;
    }

    /// Private Methods ///

    /// @dev fetch local storage
    function reentrancyStorage()
        private
        pure
        returns (ReentrancyStorage storage data)
    {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := position
        }
    }
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "ICelerMessageReceiver.sol";

abstract contract CelerMessageReceiver is ICelerMessageReceiver {
    /**
     * @notice Called by MessageBus to execute a message
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override returns (ExecutionStatus) {}

    // execute message from non-evm chain with bytes for sender address,
    // otherwise same as above.
    function executeMessage(
        bytes calldata _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override returns (ExecutionStatus) {}

    /**
     * @notice Called by MessageBus to execute a message with an associated token transfer.
     * The contract is guaranteed to have received the right amount of tokens before this function is called.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override returns (ExecutionStatus) {}

    /**
     * @notice Only called by MessageBus if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns ExecutionStatus.Fail
     * The contract is guaranteed to have received the right amount of tokens before this function is called.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override returns (ExecutionStatus) {}

    /**
     * @notice Called by MessageBus to process refund of the original transfer from this contract.
     * The contract is guaranteed to have received the refund before this function is called.
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    ) external payable virtual override returns (ExecutionStatus) {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface ICelerMessageReceiver {
    enum ExecutionStatus {
        Fail, // execution failed, finalized
        Success, // execution succeeded, finalized
        Retry // execution rejected, can retry later
    }

    /**
     * @notice Called by MessageBus to execute a message
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    // same as above, except that sender is an non-evm chain address,
    // otherwise same as above.
    function executeMessage(
        bytes calldata _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus to execute a message with an associated token transfer.
     * The contract is guaranteed to have received the right amount of tokens before this function is called.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Only called by MessageBus if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns ExecutionStatus.Fail
     * The contract is guaranteed to have received the right amount of tokens before this function is called.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus to process refund of the original transfer from this contract.
     * The contract is guaranteed to have received the refund before this function is called.
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);
}