// SPDX-License-Identifier: MIT
pragma solidity ^0.6.5;

abstract contract LibCommonRichErrors1 {

    // solhint-disable func-name-mixedcase

    function OnlyCallableBySelfError(address sender)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyCallableBySelfError(address)")),
            sender
        );
    }

    function IllegalReentrancyError(bytes4 selector, uint256 reentrancyFlags)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IllegalReentrancyError(bytes4,uint256)")),
            selector,
            reentrancyFlags
        );
    }
}

abstract contract LibLiquidityProviderRichErrors1 {

    // solhint-disable func-name-mixedcase

    function LiquidityProviderIncompleteSellError(
        address providerAddress,
        address makerToken,
        address takerToken,
        uint256 sellAmount,
        uint256 boughtAmount,
        uint256 minBuyAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("LiquidityProviderIncompleteSellError(address,address,address,uint256,uint256,uint256)")),
            providerAddress,
            makerToken,
            takerToken,
            sellAmount,
            boughtAmount,
            minBuyAmount
        );
    }
}

abstract contract LibMetaTransactionsRichErrors1 {

    // solhint-disable func-name-mixedcase

    function InvalidMetaTransactionsArrayLengthsError(
        uint256 mtxCount,
        uint256 signatureCount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidMetaTransactionsArrayLengthsError(uint256,uint256)")),
            mtxCount,
            signatureCount
        );
    }

    function MetaTransactionUnsupportedFunctionError(
        bytes32 mtxHash,
        bytes4 selector
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionUnsupportedFunctionError(bytes32,bytes4)")),
            mtxHash,
            selector
        );
    }

    function MetaTransactionWrongSenderError(
        bytes32 mtxHash,
        address sender,
        address expectedSender
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionWrongSenderError(bytes32,address,address)")),
            mtxHash,
            sender,
            expectedSender
        );
    }

    function MetaTransactionExpiredError(
        bytes32 mtxHash,
        uint256 time,
        uint256 expirationTime
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionExpiredError(bytes32,uint256,uint256)")),
            mtxHash,
            time,
            expirationTime
        );
    }

    function MetaTransactionGasPriceError(
        bytes32 mtxHash,
        uint256 gasPrice,
        uint256 minGasPrice,
        uint256 maxGasPrice
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionGasPriceError(bytes32,uint256,uint256,uint256)")),
            mtxHash,
            gasPrice,
            minGasPrice,
            maxGasPrice
        );
    }

    function MetaTransactionInsufficientEthError(
        bytes32 mtxHash,
        uint256 ethBalance,
        uint256 ethRequired
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionInsufficientEthError(bytes32,uint256,uint256)")),
            mtxHash,
            ethBalance,
            ethRequired
        );
    }

    function MetaTransactionInvalidSignatureError(
        bytes32 mtxHash,
        bytes memory signature,
        bytes memory errData
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionInvalidSignatureError(bytes32,bytes,bytes)")),
            mtxHash,
            signature,
            errData
        );
    }

    function MetaTransactionAlreadyExecutedError(
        bytes32 mtxHash,
        uint256 executedBlockNumber
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionAlreadyExecutedError(bytes32,uint256)")),
            mtxHash,
            executedBlockNumber
        );
    }

    function MetaTransactionCallFailedError(
        bytes32 mtxHash,
        bytes memory callData,
        bytes memory returnData
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MetaTransactionCallFailedError(bytes32,bytes,bytes)")),
            mtxHash,
            callData,
            returnData
        );
    }
}

abstract contract LibNativeOrdersRichErrors1 {

    // solhint-disable func-name-mixedcase

    function ProtocolFeeRefundFailed(
        address receiver,
        uint256 refundAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("ProtocolFeeRefundFailed(address,uint256)")),
            receiver,
            refundAmount
        );
    }

    function OrderNotFillableByOriginError(
        bytes32 orderHash,
        address txOrigin,
        address orderTxOrigin
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableByOriginError(bytes32,address,address)")),
            orderHash,
            txOrigin,
            orderTxOrigin
        );
    }

    function OrderNotFillableError(
        bytes32 orderHash,
        uint8 orderStatus
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableError(bytes32,uint8)")),
            orderHash,
            orderStatus
        );
    }

    function OrderNotSignedByMakerError(
        bytes32 orderHash,
        address signer,
        address maker
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotSignedByMakerError(bytes32,address,address)")),
            orderHash,
            signer,
            maker
        );
    }

    function InvalidSignerError(
        address maker,
        address signer
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidSignerError(address,address)")),
            maker,
            signer
        );
    }

    function OrderNotFillableBySenderError(
        bytes32 orderHash,
        address sender,
        address orderSender
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableBySenderError(bytes32,address,address)")),
            orderHash,
            sender,
            orderSender
        );
    }

    function OrderNotFillableByTakerError(
        bytes32 orderHash,
        address taker,
        address orderTaker
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableByTakerError(bytes32,address,address)")),
            orderHash,
            taker,
            orderTaker
        );
    }

    function CancelSaltTooLowError(
        uint256 minValidSalt,
        uint256 oldMinValidSalt
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("CancelSaltTooLowError(uint256,uint256)")),
            minValidSalt,
            oldMinValidSalt
        );
    }

    function FillOrKillFailedError(
        bytes32 orderHash,
        uint256 takerTokenFilledAmount,
        uint256 takerTokenFillAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("FillOrKillFailedError(bytes32,uint256,uint256)")),
            orderHash,
            takerTokenFilledAmount,
            takerTokenFillAmount
        );
    }

    function OnlyOrderMakerAllowed(
        bytes32 orderHash,
        address sender,
        address maker
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyOrderMakerAllowed(bytes32,address,address)")),
            orderHash,
            sender,
            maker
        );
    }

    function BatchFillIncompleteError(
        bytes32 orderHash,
        uint256 takerTokenFilledAmount,
        uint256 takerTokenFillAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("BatchFillIncompleteError(bytes32,uint256,uint256)")),
            orderHash,
            takerTokenFilledAmount,
            takerTokenFillAmount
        );
    }
}

abstract contract LibNFTOrdersRichErrors1 {

    // solhint-disable func-name-mixedcase

    function OverspentEthError(
        uint256 ethSpent,
        uint256 ethAvailable
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OverspentEthError(uint256,uint256)")),
            ethSpent,
            ethAvailable
        );
    }

    function InsufficientEthError(
        uint256 ethAvailable,
        uint256 orderAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InsufficientEthError(uint256,uint256)")),
            ethAvailable,
            orderAmount
        );
    }

    function ERC721TokenMismatchError(
        address token1,
        address token2
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("ERC721TokenMismatchError(address,address)")),
            token1,
            token2
        );
    }

    function ERC1155TokenMismatchError(
        address token1,
        address token2
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("ERC1155TokenMismatchError(address,address)")),
            token1,
            token2
        );
    }

    function ERC20TokenMismatchError(
        address token1,
        address token2
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("ERC20TokenMismatchError(address,address)")),
            token1,
            token2
        );
    }

    function NegativeSpreadError(
        uint256 sellOrderAmount,
        uint256 buyOrderAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NegativeSpreadError(uint256,uint256)")),
            sellOrderAmount,
            buyOrderAmount
        );
    }

    function SellOrderFeesExceedSpreadError(
        uint256 sellOrderFees,
        uint256 spread
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("SellOrderFeesExceedSpreadError(uint256,uint256)")),
            sellOrderFees,
            spread
        );
    }

    function OnlyTakerError(
        address sender,
        address taker
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyTakerError(address,address)")),
            sender,
            taker
        );
    }

    function InvalidSignerError(
        address maker,
        address signer
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidSignerError(address,address)")),
            maker,
            signer
        );
    }

    function OrderNotFillableError(
        address maker,
        uint256 nonce,
        uint8 orderStatus
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OrderNotFillableError(address,uint256,uint8)")),
            maker,
            nonce,
            orderStatus
        );
    }

    function TokenIdMismatchError(
        uint256 tokenId,
        uint256 orderTokenId
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("TokenIdMismatchError(uint256,uint256)")),
            tokenId,
            orderTokenId
        );
    }

    function PropertyValidationFailedError(
        address propertyValidator,
        address token,
        uint256 tokenId,
        bytes memory propertyData,
        bytes memory errorData
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("PropertyValidationFailedError(address,address,uint256,bytes,bytes)")),
            propertyValidator,
            token,
            tokenId,
            propertyData,
            errorData
        );
    }

    function ExceedsRemainingOrderAmount(
        uint128 remainingOrderAmount,
        uint128 fillAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("ExceedsRemainingOrderAmount(uint128,uint128)")),
            remainingOrderAmount,
            fillAmount
        );
    }
}

abstract contract LibOwnableRichErrors1 {

    // solhint-disable func-name-mixedcase

    function OnlyOwnerError(
        address sender,
        address owner
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyOwnerError(address,address)")),
            sender,
            owner
        );
    }

    function TransferOwnerToZeroError()
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("TransferOwnerToZeroError()"))
        );
    }

    function MigrateCallFailedError(address target, bytes memory resultData)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("MigrateCallFailedError(address,bytes)")),
            target,
            resultData
        );
    }
}

abstract contract LibProxyRichErrors1 {

    // solhint-disable func-name-mixedcase

    function NotImplementedError(bytes4 selector)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NotImplementedError(bytes4)")),
            selector
        );
    }

    function InvalidBootstrapCallerError(address actual, address expected)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidBootstrapCallerError(address,address)")),
            actual,
            expected
        );
    }

    function InvalidDieCallerError(address actual, address expected)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidDieCallerError(address,address)")),
            actual,
            expected
        );
    }

    function BootstrapCallFailedError(address target, bytes memory resultData)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("BootstrapCallFailedError(address,bytes)")),
            target,
            resultData
        );
    }
}

abstract contract LibSignatureRichErrors1 {

    enum SignatureValidationErrorCodes {
        ALWAYS_INVALID,
        INVALID_LENGTH,
        UNSUPPORTED,
        ILLEGAL,
        WRONG_SIGNER,
        BAD_SIGNATURE_DATA
    }

    // solhint-disable func-name-mixedcase

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("SignatureValidationError(uint8,bytes32,address,bytes)")),
            code,
            hash,
            signerAddress,
            signature
        );
    }

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("SignatureValidationError(uint8,bytes32)")),
            code,
            hash
        );
    }
}

abstract contract LibSimpleFunctionRegistryRichErrors1 {

    // solhint-disable func-name-mixedcase

    function NotInRollbackHistoryError(bytes4 selector, address targetImpl)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NotInRollbackHistoryError(bytes4,address)")),
            selector,
            targetImpl
        );
    }
}

abstract contract LibTransformERC20RichErrors1 {

    // solhint-disable func-name-mixedcase,separate-by-one-line-in-contract

    function InsufficientEthAttachedError(
        uint256 ethAttached,
        uint256 ethNeeded
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InsufficientEthAttachedError(uint256,uint256)")),
            ethAttached,
            ethNeeded
        );
    }

    function IncompleteTransformERC20Error(
        address outputToken,
        uint256 outputTokenAmount,
        uint256 minOutputTokenAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IncompleteTransformERC20Error(address,uint256,uint256)")),
            outputToken,
            outputTokenAmount,
            minOutputTokenAmount
        );
    }

    function NegativeTransformERC20OutputError(
        address outputToken,
        uint256 outputTokenLostAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NegativeTransformERC20OutputError(address,uint256)")),
            outputToken,
            outputTokenLostAmount
        );
    }

    function TransformerFailedError(
        address transformer,
        bytes memory transformerData,
        bytes memory resultData
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("TransformerFailedError(address,bytes,bytes)")),
            transformer,
            transformerData,
            resultData
        );
    }

    // Common Transformer errors ///////////////////////////////////////////////

    function OnlyCallableByDeployerError(
        address caller,
        address deployer
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("OnlyCallableByDeployerError(address,address)")),
            caller,
            deployer
        );
    }

    function InvalidExecutionContextError(
        address actualContext,
        address expectedContext
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidExecutionContextError(address,address)")),
            actualContext,
            expectedContext
        );
    }

    enum InvalidTransformDataErrorCode {
        INVALID_TOKENS,
        INVALID_ARRAY_LENGTH
    }

    function InvalidTransformDataError(
        InvalidTransformDataErrorCode errorCode,
        bytes memory transformData
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidTransformDataError(uint8,bytes)")),
            errorCode,
            transformData
        );
    }

    // FillQuoteTransformer errors /////////////////////////////////////////////

    function IncompleteFillSellQuoteError(
        address sellToken,
        uint256 soldAmount,
        uint256 sellAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IncompleteFillSellQuoteError(address,uint256,uint256)")),
            sellToken,
            soldAmount,
            sellAmount
        );
    }

    function IncompleteFillBuyQuoteError(
        address buyToken,
        uint256 boughtAmount,
        uint256 buyAmount
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("IncompleteFillBuyQuoteError(address,uint256,uint256)")),
            buyToken,
            boughtAmount,
            buyAmount
        );
    }

    function InsufficientTakerTokenError(
        uint256 tokenBalance,
        uint256 tokensNeeded
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InsufficientTakerTokenError(uint256,uint256)")),
            tokenBalance,
            tokensNeeded
        );
    }

    function InsufficientProtocolFeeError(
        uint256 ethBalance,
        uint256 ethNeeded
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InsufficientProtocolFeeError(uint256,uint256)")),
            ethBalance,
            ethNeeded
        );
    }

    function InvalidERC20AssetDataError(
        bytes memory assetData
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidERC20AssetDataError(bytes)")),
            assetData
        );
    }

    function InvalidTakerFeeTokenError(
        address token
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidTakerFeeTokenError(address)")),
            token
        );
    }
}

abstract contract LibWalletRichErrors1 {

    // solhint-disable func-name-mixedcase

    function WalletExecuteCallFailedError(
        address wallet,
        address callTarget,
        bytes memory callData,
        uint256 callValue,
        bytes memory errorData
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("WalletExecuteCallFailedError(address,address,bytes,uint256,bytes)")),
            wallet,
            callTarget,
            callData,
            callValue,
            errorData
        );
    }

    function WalletExecuteDelegateCallFailedError(
        address wallet,
        address callTarget,
        bytes memory callData,
        bytes memory errorData
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("WalletExecuteDelegateCallFailedError(address,address,bytes,bytes)")),
            wallet,
            callTarget,
            callData,
            errorData
        );
    }
}

abstract contract LibAuthorizableRichErrorsV06_1 {

    // bytes4(keccak256("AuthorizedAddressMismatchError(address,address)"))
    bytes4 public constant AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR =
        0x140a84db;

    // bytes4(keccak256("IndexOutOfBoundsError(uint256,uint256)"))
    bytes4 public constant INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR =
        0xe9f83771;

    // bytes4(keccak256("SenderNotAuthorizedError(address)"))
    bytes4 public constant SENDER_NOT_AUTHORIZED_ERROR_SELECTOR =
        0xb65a25b9;

    // bytes4(keccak256("TargetAlreadyAuthorizedError(address)"))
    bytes4 public constant TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR =
        0xde16f1a0;

    // bytes4(keccak256("TargetNotAuthorizedError(address)"))
    bytes4 public constant TARGET_NOT_AUTHORIZED_ERROR_SELECTOR =
        0xeb5108a2;

    // bytes4(keccak256("ZeroCantBeAuthorizedError()"))
    bytes public constant ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES =
        hex"57654fe4";

    // solhint-disable func-name-mixedcase
    function AuthorizedAddressMismatchError(
        address authorized,
        address target
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR,
            authorized,
            target
        );
    }

    function IndexOutOfBoundsError(
        uint256 index,
        uint256 length
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR,
            index,
            length
        );
    }

    function SenderNotAuthorizedError(address sender)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            SENDER_NOT_AUTHORIZED_ERROR_SELECTOR,
            sender
        );
    }

    function TargetAlreadyAuthorizedError(address target)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR,
            target
        );
    }

    function TargetNotAuthorizedError(address target)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TARGET_NOT_AUTHORIZED_ERROR_SELECTOR,
            target
        );
    }

    function ZeroCantBeAuthorizedError()
        public
        pure
        returns (bytes memory)
    {
        return ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES;
    }
}

abstract contract LibBytesRichErrorsV06_1 {

    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }

    // bytes4(keccak256("InvalidByteOperationError(uint8,uint256,uint256)"))
    bytes4 public constant INVALID_BYTE_OPERATION_ERROR_SELECTOR =
        0x28006595;

    // solhint-disable func-name-mixedcase
    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_BYTE_OPERATION_ERROR_SELECTOR,
            errorCode,
            offset,
            required
        );
    }
}

abstract contract LibMathRichErrorsV06_1 {

    // bytes4(keccak256("DivisionByZeroError()"))
    bytes public constant DIVISION_BY_ZERO_ERROR =
        hex"a791837c";

    // bytes4(keccak256("RoundingError(uint256,uint256,uint256)"))
    bytes4 public constant ROUNDING_ERROR_SELECTOR =
        0x339f3de2;

    // solhint-disable func-name-mixedcase
    function DivisionByZeroError()
        public
        pure
        returns (bytes memory)
    {
        return DIVISION_BY_ZERO_ERROR;
    }

    function RoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ROUNDING_ERROR_SELECTOR,
            numerator,
            denominator,
            target
        );
    }
}

abstract contract LibOwnableRichErrorsV06_1 {

    // bytes4(keccak256("OnlyOwnerError(address,address)"))
    bytes4 public constant ONLY_OWNER_ERROR_SELECTOR =
        0x1de45ad1;

    // bytes4(keccak256("TransferOwnerToZeroError()"))
    bytes public constant TRANSFER_OWNER_TO_ZERO_ERROR_BYTES =
        hex"e69edc3e";

    // solhint-disable func-name-mixedcase
    function OnlyOwnerError(
        address sender,
        address owner
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_OWNER_ERROR_SELECTOR,
            sender,
            owner
        );
    }

    function TransferOwnerToZeroError()
        public
        pure
        returns (bytes memory)
    {
        return TRANSFER_OWNER_TO_ZERO_ERROR_BYTES;
    }
}

abstract contract LibReentrancyGuardRichErrorsV06_1 {

    // bytes4(keccak256("IllegalReentrancyError()"))
    bytes public constant ILLEGAL_REENTRANCY_ERROR_SELECTOR_BYTES =
        hex"0c3b823f";

    // solhint-disable func-name-mixedcase
    function IllegalReentrancyError()
        public
        pure
        returns (bytes memory)
    {
        return ILLEGAL_REENTRANCY_ERROR_SELECTOR_BYTES;
    }
}

abstract contract LibRichErrorsV06_1 {

    // bytes4(keccak256("Error(string)"))
    bytes4 public constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        public
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

abstract contract LibSafeMathRichErrorsV06_1 {

    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 public constant UINT256_BINOP_ERROR_SELECTOR =
        0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 public constant UINT256_DOWNCAST_ERROR_SELECTOR =
        0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_BINOP_ERROR_SELECTOR,
            errorCode,
            a,
            b
        );
    }

    function Uint256DowncastError(
        DowncastErrorCodes errorCode,
        uint256 a
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_DOWNCAST_ERROR_SELECTOR,
            errorCode,
            a
        );
    }
}

contract DummyErrors1 is 
    LibCommonRichErrors1,
    LibLiquidityProviderRichErrors1,
    LibMetaTransactionsRichErrors1,
    LibNFTOrdersRichErrors1,
    LibOwnableRichErrors1,
    LibProxyRichErrors1,
    LibSignatureRichErrors1,
    LibSimpleFunctionRegistryRichErrors1,
    LibTransformERC20RichErrors1,
    LibWalletRichErrors1,
    LibAuthorizableRichErrorsV06_1,
    LibBytesRichErrorsV06_1,
    LibMathRichErrorsV06_1,
    LibReentrancyGuardRichErrorsV06_1,
    LibRichErrorsV06_1,
    LibSafeMathRichErrorsV06_1
{ }

contract DummyErrors2 is 
    LibNativeOrdersRichErrors1,
    LibOwnableRichErrorsV06_1
{ }