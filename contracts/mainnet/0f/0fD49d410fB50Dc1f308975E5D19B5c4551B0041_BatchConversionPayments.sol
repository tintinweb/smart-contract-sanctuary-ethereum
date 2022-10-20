// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './interfaces/IERC20ConversionProxy.sol';
import './interfaces/IEthConversionProxy.sol';
import './BatchNoConversionPayments.sol';

/**
 * @title BatchConversionPayments
 * @notice This contract makes multiple conversion payments with references, in one transaction:
 *          - on:
 *              - ERC20 tokens: using Erc20ConversionProxy and ERC20FeeProxy
 *              - Native tokens: (e.g. ETH) using EthConversionProxy and EthereumFeeProxy
 *          - to: multiple addresses
 *          - fees: conversion proxy fees and additional batch conversion fees are paid to the same address.
 *         batchPayments is the main function to batch all kinds of payments at once.
 *         If one transaction of the batch fails, all transactions are reverted.
 * @dev batchPayments is the main function, but other batch payment functions are "public" in order to do
 *      gas optimization in some cases.
 */
contract BatchConversionPayments is BatchNoConversionPayments {
  using SafeERC20 for IERC20;

  IERC20ConversionProxy public paymentErc20ConversionProxy;
  IEthConversionProxy public paymentNativeConversionProxy;

  /** payerAuthorized is set to true to workaround the non-payable aspect in batch native conversion */
  bool private payerAuthorized = false;

  /**
   * @dev Used by the batchPayments to handle information for heterogeneous batches, grouped by payment network:
   *  - paymentNetworkId: from 0 to 4, cf. `batchPayments()` method
   *  - requestDetails all the data required for conversion and no conversion requests to be paid
   */
  struct MetaDetail {
    uint256 paymentNetworkId;
    RequestDetail[] requestDetails;
  }

  /**
   * @param _paymentErc20Proxy The ERC20 payment proxy address to use.
   * @param _paymentNativeProxy The native payment proxy address to use.
   * @param _paymentErc20ConversionProxy The ERC20 Conversion payment proxy address to use.
   * @param _paymentNativeConversionFeeProxy The native Conversion payment proxy address to use.
   * @param _chainlinkConversionPath The address of the conversion path contract.
   * @param _owner Owner of the contract.
   */
  constructor(
    address _paymentErc20Proxy,
    address _paymentNativeProxy,
    address _paymentErc20ConversionProxy,
    address _paymentNativeConversionFeeProxy,
    address _chainlinkConversionPath,
    address _owner
  )
    BatchNoConversionPayments(
      _paymentErc20Proxy,
      _paymentNativeProxy,
      _chainlinkConversionPath,
      _owner
    )
  {
    paymentErc20ConversionProxy = IERC20ConversionProxy(_paymentErc20ConversionProxy);
    paymentNativeConversionProxy = IEthConversionProxy(_paymentNativeConversionFeeProxy);
  }

  /**
   * This contract is non-payable.
   * Making a Native payment with conversion requires the contract to accept incoming Native tokens.
   * @dev See the end of `paymentNativeConversionProxy.transferWithReferenceAndFee` where the leftover is given back.
   */
  receive() external payable override {
    require(payerAuthorized || msg.value == 0, 'Non-payable');
  }

  /**
   * @notice Batch payments on different payment networks at once.
   * @param metaDetails contains paymentNetworkId and requestDetails
   * - batchMultiERC20ConversionPayments, paymentNetworkId=0
   * - batchERC20Payments, paymentNetworkId=1
   * - batchMultiERC20Payments, paymentNetworkId=2
   * - batchNativePayments, paymentNetworkId=3
   * - batchNativeConversionPayments, paymentNetworkId=4
   * If metaDetails use paymentNetworkId = 4, it must be at the end of the list, or the transaction can be reverted.
   * @param pathsToUSD The list of paths into USD for every token, used to limit the batch fees.
   *                   For batch native, mock an array of array to apply the limit, e.g: [[]]
   *                   Without paths, there is not limitation, neither for the batch native functions.
   * @param feeAddress The address where fees should be paid.
   * @dev Use pathsToUSD only if you are pretty sure the batch fees will higher than the
   *      USD limit batchFeeAmountUSDLimit, because it increase gas consumption.
   *      batchPayments only reduces gas consumption when using more than a single payment network.
   *      For single payment network payments, it is more efficient to use the suited batch function.
   */
  function batchPayments(
    MetaDetail[] calldata metaDetails,
    address[][] calldata pathsToUSD,
    address feeAddress
  ) external payable {
    require(metaDetails.length < 6, 'more than 5 metaDetails');

    uint256 batchFeeAmountUSD = 0;
    for (uint256 i = 0; i < metaDetails.length; i++) {
      MetaDetail calldata metaDetail = metaDetails[i];
      if (metaDetail.paymentNetworkId == 0) {
        batchFeeAmountUSD += _batchMultiERC20ConversionPayments(
          metaDetail.requestDetails,
          batchFeeAmountUSD,
          pathsToUSD,
          feeAddress
        );
      } else if (metaDetail.paymentNetworkId == 1) {
        batchFeeAmountUSD += _batchERC20Payments(
          metaDetail.requestDetails,
          pathsToUSD,
          batchFeeAmountUSD,
          payable(feeAddress)
        );
      } else if (metaDetail.paymentNetworkId == 2) {
        batchFeeAmountUSD += _batchMultiERC20Payments(
          metaDetail.requestDetails,
          pathsToUSD,
          batchFeeAmountUSD,
          feeAddress
        );
      } else if (metaDetail.paymentNetworkId == 3) {
        if (metaDetails[metaDetails.length - 1].paymentNetworkId == 4) {
          // Set to false only if batchNativeConversionPayments is called after this function
          transferBackRemainingNativeTokens = false;
        }
        batchFeeAmountUSD += _batchNativePayments(
          metaDetail.requestDetails,
          pathsToUSD.length == 0,
          batchFeeAmountUSD,
          payable(feeAddress)
        );
        if (metaDetails[metaDetails.length - 1].paymentNetworkId == 4) {
          transferBackRemainingNativeTokens = true;
        }
      } else if (metaDetail.paymentNetworkId == 4) {
        batchFeeAmountUSD += _batchNativeConversionPayments(
          metaDetail.requestDetails,
          pathsToUSD.length == 0,
          batchFeeAmountUSD,
          payable(feeAddress)
        );
      } else {
        revert('Wrong paymentNetworkId');
      }
    }
  }

  /**
   * @notice Send a batch of ERC20 payments with amounts based on a request
   * currency (e.g. fiat), with fees and paymentReferences to multiple accounts, with multiple tokens.
   * @param requestDetails List of ERC20 requests denominated in fiat to pay.
   * @param pathsToUSD The list of paths into USD for every token, used to limit the batch fees.
   *                   Without paths, there is not a fee limitation, and it consumes less gas.
   * @param feeAddress The fee recipient.
   */
  function batchMultiERC20ConversionPayments(
    RequestDetail[] calldata requestDetails,
    address[][] calldata pathsToUSD,
    address feeAddress
  ) public returns (uint256) {
    return _batchMultiERC20ConversionPayments(requestDetails, 0, pathsToUSD, feeAddress);
  }

  /**
   * @notice Send a batch of Native conversion payments with fees and paymentReferences to multiple accounts.
   *         If one payment fails, the whole batch is reverted.
   * @param requestDetails List of native requests denominated in fiat to pay.
   * @param skipFeeUSDLimit Setting the value to true skips the USD fee limit, and reduce gas consumption.
   * @param feeAddress The fee recipient.
   * @dev It uses NativeConversionProxy (EthereumConversionProxy) to pay an invoice and fees.
   *      Please:
   *        Note that if there is not enough Native token attached to the function call,
   *        the following error is thrown: "revert paymentProxy transferExactEthWithReferenceAndFee failed"
   */
  function batchNativeConversionPayments(
    RequestDetail[] calldata requestDetails,
    bool skipFeeUSDLimit,
    address payable feeAddress
  ) public payable returns (uint256) {
    return _batchNativeConversionPayments(requestDetails, skipFeeUSDLimit, 0, feeAddress);
  }

  /**
   * @notice Send a batch of ERC20 payments with amounts based on a request
   * currency (e.g. fiat), with fees and paymentReferences to multiple accounts, with multiple tokens.
   * @param requestDetails List of ERC20 requests denominated in fiat to pay.
   * @param batchFeeAmountUSD The batch fee amount in USD already paid.
   * @param pathsToUSD The list of paths into USD for every token, used to limit the batch fees.
   *                   Without paths, there is not a fee limitation, and it consumes less gas.
   * @param feeAddress The fee recipient.
   */
  function _batchMultiERC20ConversionPayments(
    RequestDetail[] calldata requestDetails,
    uint256 batchFeeAmountUSD,
    address[][] calldata pathsToUSD,
    address feeAddress
  ) private returns (uint256) {
    Token[] memory uTokens = getUTokens(requestDetails);

    IERC20 requestedToken;
    // For each token: check allowance, transfer funds on the contract and approve the paymentProxy to spend if needed
    for (uint256 k = 0; k < uTokens.length && uTokens[k].amountAndFee > 0; k++) {
      uTokens[k].batchFeeAmount = (uTokens[k].amountAndFee * batchFee) / feeDenominator;
      requestedToken = IERC20(uTokens[k].tokenAddress);
      transferToContract(
        requestedToken,
        uTokens[k].amountAndFee,
        uTokens[k].batchFeeAmount,
        address(paymentErc20ConversionProxy)
      );
    }

    // Batch pays the requests using Erc20ConversionFeeProxy
    for (uint256 i = 0; i < requestDetails.length; i++) {
      RequestDetail calldata rD = requestDetails[i];
      paymentErc20ConversionProxy.transferFromWithReferenceAndFee(
        rD.recipient,
        rD.requestAmount,
        rD.path,
        rD.paymentReference,
        rD.feeAmount,
        feeAddress,
        rD.maxToSpend,
        rD.maxRateTimespan
      );
    }

    // Batch sends back to the payer the tokens not spent and pays the batch fee
    for (uint256 k = 0; k < uTokens.length && uTokens[k].amountAndFee > 0; k++) {
      requestedToken = IERC20(uTokens[k].tokenAddress);

      // Batch sends back to the payer the tokens not spent = excessAmount
      // excessAmount = maxToSpend - reallySpent, which is equal to the remaining tokens on the contract
      uint256 excessAmount = requestedToken.balanceOf(address(this));
      if (excessAmount > 0) {
        requestedToken.safeTransfer(msg.sender, excessAmount);
      }

      // Calculate batch fee to pay
      uint256 batchFeeToPay = ((uTokens[k].amountAndFee - excessAmount) * batchFee) /
        feeDenominator;

      (batchFeeToPay, batchFeeAmountUSD) = calculateBatchFeeToPay(
        batchFeeToPay,
        uTokens[k].tokenAddress,
        batchFeeAmountUSD,
        pathsToUSD
      );

      // Payer pays the exact batch fees amount
      require(
        safeTransferFrom(uTokens[k].tokenAddress, feeAddress, batchFeeToPay),
        'Batch fee transferFrom() failed'
      );
    }
    return batchFeeAmountUSD;
  }

  /**
   * @notice Send a batch of Native conversion payments with fees and paymentReferences to multiple accounts.
   *         If one payment fails, the whole batch is reverted.
   * @param requestDetails List of native requests denominated in fiat to pay.
   * @param skipFeeUSDLimit Setting the value to true skips the USD fee limit, and reduce gas consumption.
   * @param batchFeeAmountUSD The batch fee amount in USD already paid.
   * @param feeAddress The fee recipient.
   * @dev It uses NativeConversionProxy (EthereumConversionProxy) to pay an invoice and fees.
   *      Please:
   *        Note that if there is not enough Native token attached to the function call,
   *        the following error is thrown: "revert paymentProxy transferExactEthWithReferenceAndFee failed"
   */
  function _batchNativeConversionPayments(
    RequestDetail[] calldata requestDetails,
    bool skipFeeUSDLimit,
    uint256 batchFeeAmountUSD,
    address payable feeAddress
  ) private returns (uint256) {
    uint256 contractBalance = address(this).balance;
    payerAuthorized = true;

    // Batch contract pays the requests through nativeConversionProxy
    for (uint256 i = 0; i < requestDetails.length; i++) {
      RequestDetail calldata rD = requestDetails[i];
      paymentNativeConversionProxy.transferWithReferenceAndFee{value: address(this).balance}(
        payable(rD.recipient),
        rD.requestAmount,
        rD.path,
        rD.paymentReference,
        rD.feeAmount,
        feeAddress,
        rD.maxRateTimespan
      );
    }

    // Batch contract pays batch fee
    uint256 batchFeeToPay = (((contractBalance - address(this).balance)) * batchFee) /
      feeDenominator;

    if (skipFeeUSDLimit == false) {
      (batchFeeToPay, batchFeeAmountUSD) = calculateBatchFeeToPay(
        batchFeeToPay,
        pathsNativeToUSD[0][0],
        batchFeeAmountUSD,
        pathsNativeToUSD
      );
    }

    require(address(this).balance >= batchFeeToPay, 'Not enough funds for batch conversion fees');
    feeAddress.transfer(batchFeeToPay);

    // Batch contract transfers the remaining native tokens to the payer
    (bool sendBackSuccess, ) = payable(msg.sender).call{value: address(this).balance}('');
    require(sendBackSuccess, 'Could not send remaining funds to the payer');
    payerAuthorized = false;

    return batchFeeAmountUSD;
  }

  /*
   * Admin functions to edit the conversion proxies address and fees.
   */

  /**
   * @param _paymentErc20ConversionProxy The address of the ERC20 Conversion payment proxy to use.
   *        Update cautiously, the proxy has to match the invoice proxy.
   */
  function setPaymentErc20ConversionProxy(address _paymentErc20ConversionProxy) external onlyOwner {
    paymentErc20ConversionProxy = IERC20ConversionProxy(_paymentErc20ConversionProxy);
  }

  /**
   * @param _paymentNativeConversionProxy The address of the native Conversion payment proxy to use.
   *        Update cautiously, the proxy has to match the invoice proxy.
   */
  function setPaymentNativeConversionProxy(address _paymentNativeConversionProxy)
    external
    onlyOwner
  {
    paymentNativeConversionProxy = IEthConversionProxy(_paymentNativeConversionProxy);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20ConversionProxy {
  // Event to declare a conversion with a reference
  event TransferWithConversionAndReference(
    uint256 amount,
    address currency,
    bytes indexed paymentReference,
    uint256 feeAmount,
    uint256 maxRateTimespan
  );

  // Event to declare a transfer with a reference
  event TransferWithReferenceAndFee(
    address tokenAddress,
    address to,
    uint256 amount,
    bytes indexed paymentReference,
    uint256 feeAmount,
    address feeAddress
  );

  function transferFromWithReferenceAndFee(
    address _to,
    uint256 _requestAmount,
    address[] calldata _path,
    bytes calldata _paymentReference,
    uint256 _feeAmount,
    address _feeAddress,
    uint256 _maxToSpend,
    uint256 _maxRateTimespan
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IEthConversionProxy
 * @notice This contract converts from chainlink then swaps ETH (or native token)
 *         before paying a request thanks to a conversion payment proxy.
 *         The inheritance from ReentrancyGuard is required to perform
 *         "transferExactEthWithReferenceAndFee" on the eth-fee-proxy contract
 */
interface IEthConversionProxy {
  // Event to declare a conversion with a reference
  event TransferWithConversionAndReference(
    uint256 amount,
    address currency,
    bytes indexed paymentReference,
    uint256 feeAmount,
    uint256 maxRateTimespan
  );

  // Event to declare a transfer with a reference
  // This event is emitted by this contract from a delegate call of the payment-proxy
  event TransferWithReferenceAndFee(
    address to,
    uint256 amount,
    bytes indexed paymentReference,
    uint256 feeAmount,
    address feeAddress
  );

  /**
   * @notice Performs an ETH transfer with a reference computing the payment amount based on the request amount
   * @param _to Transfer recipient of the payement
   * @param _requestAmount Request amount
   * @param _path Conversion path
   * @param _paymentReference Reference of the payment related
   * @param _feeAmount The amount of the payment fee
   * @param _feeAddress The fee recipient
   * @param _maxRateTimespan Max time span with the oldestrate, ignored if zero
   */
  function transferWithReferenceAndFee(
    address _to,
    uint256 _requestAmount,
    address[] calldata _path,
    bytes calldata _paymentReference,
    uint256 _feeAmount,
    address _feeAddress,
    uint256 _maxRateTimespan
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './lib/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/ERC20FeeProxy.sol';
import './interfaces/EthereumFeeProxy.sol';
import './ChainlinkConversionPath.sol';

/**
 * @title BatchNoConversionPayments
 * @notice  This contract makes multiple payments with references, in one transaction:
 *          - on: ERC20 Payment Proxy and Native (ETH) Payment Proxy of the Request Network protocol
 *          - to: multiple addresses
 *          - fees: ERC20 and Native (ETH) proxies fees are paid to the same address
 *                  An additional batch fee is paid to the same address
 *         If one transaction of the batch fail, every transactions are reverted.
 * @dev It is a clone of BatchPayment.sol, with three main modifications:
 *         - function "receive" has one other condition: payerAuthorized
 *         - fees are now divided by 10_000 instead of 1_000 in previous version
 *         - batch payment functions have new names and are now public, instead of external
 */
contract BatchNoConversionPayments is Ownable {
  using SafeERC20 for IERC20;

  IERC20FeeProxy public paymentErc20Proxy;
  IEthereumFeeProxy public paymentNativeProxy;
  ChainlinkConversionPath public chainlinkConversionPath;

  /** Used to calculate batch fees: batchFee = 30 represent 0.30% of fee */
  uint16 public batchFee;
  /** Used to calculate batch fees: divide batchFee by feeDenominator */
  uint16 internal feeDenominator = 10000;
  /** The amount of the batch fee cannot exceed a predefined amount in USD, e.g:
      batchFeeAmountUSDLimit = 150 * 1e8 represents $150 */
  uint64 public batchFeeAmountUSDLimit;

  /** transferBackRemainingNativeTokens is set to false only if the payer use batchPayments
  and call both batchNativePayments and batchNativeConversionPayments */
  bool internal transferBackRemainingNativeTokens = true;

  address public USDAddress;
  address public NativeAddress;
  address[][] public pathsNativeToUSD;

  /** Contains the address of a token, the sum of the amount and fees paid with it, and the batch fee amount */
  struct Token {
    address tokenAddress;
    uint256 amountAndFee;
    uint256 batchFeeAmount;
  }

  /**
   * @dev All the information of a request, except the feeAddress
   *   recipient: Recipient address of the payment
   *   requestAmount: Request amount, in fiat for conversion payment
   *   path: Only for conversion payment: the conversion path
   *   paymentReference: Unique reference of the payment
   *   feeAmount: The fee amount, denominated in the first currency of `path` for conversion payment
   *   maxToSpend: Only for conversion payment:
   *               Maximum amount the payer wants to spend, denominated in the last currency of `path`:
   *                it includes fee proxy but NOT the batch fees to pay
   *   maxRateTimespan: Only for conversion payment:
   *                    Max acceptable times span for conversion rates, ignored if zero
   */
  struct RequestDetail {
    address recipient;
    uint256 requestAmount;
    address[] path;
    bytes paymentReference;
    uint256 feeAmount;
    uint256 maxToSpend;
    uint256 maxRateTimespan;
  }

  /**
   * @param _paymentErc20Proxy The address to the ERC20 fee payment proxy to use.
   * @param _paymentNativeProxy The address to the Native fee payment proxy to use.
   * @param _chainlinkConversionPath The address of the conversion path contract.
   * @param _owner Owner of the contract.
   */
  constructor(
    address _paymentErc20Proxy,
    address _paymentNativeProxy,
    address _chainlinkConversionPath,
    address _owner
  ) {
    paymentErc20Proxy = IERC20FeeProxy(_paymentErc20Proxy);
    paymentNativeProxy = IEthereumFeeProxy(_paymentNativeProxy);
    chainlinkConversionPath = ChainlinkConversionPath(_chainlinkConversionPath);
    transferOwnership(_owner);
    batchFee = 0;
  }

  /**
   * This contract is non-payable.
   * @dev See the end of `paymentNativeProxy.transferWithReferenceAndFee` where the leftover is given back.
   */
  receive() external payable virtual {
    require(msg.value == 0, 'Non-payable');
  }

  /**
   * @notice Send a batch of Native (or EVM native token) payments with fees and paymentReferences to multiple accounts.
   *         If one payment fails, the whole batch reverts.
   * @param requestDetails List of Native tokens requests to pay.
   * @param skipFeeUSDLimit Setting the value to true skips the USD fee limit, and reduce gas consumption.
   * @param feeAddress The fee recipient.
   * @dev It uses NativeFeeProxy (EthereumFeeProxy) to pay an invoice and fees with a payment reference.
   *      Make sure: msg.value >= sum(_amouts)+sum(_feeAmounts)+sumBatchFeeAmount
   */
  function batchNativePayments(
    RequestDetail[] calldata requestDetails,
    bool skipFeeUSDLimit,
    address payable feeAddress
  ) public payable returns (uint256) {
    return _batchNativePayments(requestDetails, skipFeeUSDLimit, 0, payable(feeAddress));
  }

  /**
   * @notice Send a batch of ERC20 payments with fees and paymentReferences to multiple accounts.
   * @param requestDetails List of ERC20 requests to pay, with only one ERC20 token.
   * @param pathsToUSD The list of paths into USD for every token, used to limit the batch fees.
   *                   Without paths, there is not a fee limitation, and it consumes less gas.
   * @param feeAddress The fee recipient.
   * @dev Uses ERC20FeeProxy to pay an invoice and fees, with a payment reference.
   *      Make sure this contract has enough allowance to spend the payer's token.
   *      Make sure the payer has enough tokens to pay the amount, the fee, and the batch fee.
   */
  function batchERC20Payments(
    RequestDetail[] calldata requestDetails,
    address[][] calldata pathsToUSD,
    address feeAddress
  ) public returns (uint256) {
    return _batchERC20Payments(requestDetails, pathsToUSD, 0, feeAddress);
  }

  /**
   * @notice Send a batch of ERC20 payments with fees and paymentReferences to multiple accounts, with multiple tokens.
   * @param requestDetails List of ERC20 requests to pay.
   * @param pathsToUSD The list of paths into USD for every token, used to limit the batch fees.
   *                   Without paths, there is not a fee limitation, and it consumes less gas.
   * @param feeAddress The fee recipient.
   * @dev It uses ERC20FeeProxy to pay an invoice and fees, with a payment reference.
   *      Make sure this contract has enough allowance to spend the payer's token.
   *      Make sure the payer has enough tokens to pay the amount, the fee, and the batch fee.
   */
  function batchMultiERC20Payments(
    RequestDetail[] calldata requestDetails,
    address[][] calldata pathsToUSD,
    address feeAddress
  ) public returns (uint256) {
    return _batchMultiERC20Payments(requestDetails, pathsToUSD, 0, feeAddress);
  }

  /**
   * @notice Send a batch of Native (or EVM native token) payments with fees and paymentReferences to multiple accounts.
   *         If one payment fails, the whole batch reverts.
   * @param requestDetails List of Native tokens requests to pay.
   * @param skipFeeUSDLimit Setting the value to true skips the USD fee limit, and reduce gas consumption.
   * @param batchFeeAmountUSD The batch fee amount in USD already paid.
   * @param feeAddress The fee recipient.
   * @dev It uses NativeFeeProxy (EthereumFeeProxy) to pay an invoice and fees with a payment reference.
   *      Make sure: msg.value >= sum(_amouts)+sum(_feeAmounts)+sumBatchFeeAmount
   */
  function _batchNativePayments(
    RequestDetail[] calldata requestDetails,
    bool skipFeeUSDLimit,
    uint256 batchFeeAmountUSD,
    address payable feeAddress
  ) internal returns (uint256) {
    // amount is used to get the total amount and then used as batch fee amount
    uint256 amount = 0;

    // Batch contract pays the requests thourgh NativeFeeProxy (EthFeeProxy)
    for (uint256 i = 0; i < requestDetails.length; i++) {
      RequestDetail calldata rD = requestDetails[i];
      require(address(this).balance >= rD.requestAmount + rD.feeAmount, 'Not enough funds');
      amount += rD.requestAmount;

      paymentNativeProxy.transferWithReferenceAndFee{value: rD.requestAmount + rD.feeAmount}(
        payable(rD.recipient),
        rD.paymentReference,
        rD.feeAmount,
        payable(feeAddress)
      );
    }

    // amount is updated into batch fee amount
    amount = (amount * batchFee) / feeDenominator;
    if (skipFeeUSDLimit == false) {
      (amount, batchFeeAmountUSD) = calculateBatchFeeToPay(
        amount,
        pathsNativeToUSD[0][0],
        batchFeeAmountUSD,
        pathsNativeToUSD
      );
    }
    // Check that batch contract has enough funds to pay batch fee
    require(address(this).balance >= amount, 'Not enough funds for batch fee');
    // Batch pays batch fee
    feeAddress.transfer(amount);

    // Batch contract transfers the remaining Native tokens to the payer
    if (transferBackRemainingNativeTokens && address(this).balance > 0) {
      (bool sendBackSuccess, ) = payable(msg.sender).call{value: address(this).balance}('');
      require(sendBackSuccess, 'Could not send remaining funds to the payer');
    }
    return batchFeeAmountUSD;
  }

  /**
   * @notice Send a batch of ERC20 payments with fees and paymentReferences to multiple accounts.
   * @param requestDetails List of ERC20 requests to pay, with only one ERC20 token.
   * @param pathsToUSD The list of paths into USD for every token, used to limit the batch fees.
   *                   Without paths, there is not a fee limitation, and it consumes less gas.
   * @param batchFeeAmountUSD The batch fee amount in USD already paid.
   * @param feeAddress The fee recipient.
   * @dev Uses ERC20FeeProxy to pay an invoice and fees, with a payment reference.
   *      Make sure this contract has enough allowance to spend the payer's token.
   *      Make sure the payer has enough tokens to pay the amount, the fee, and the batch fee.
   */
  function _batchERC20Payments(
    RequestDetail[] calldata requestDetails,
    address[][] calldata pathsToUSD,
    uint256 batchFeeAmountUSD,
    address feeAddress
  ) internal returns (uint256) {
    uint256 amountAndFee = 0;
    uint256 batchFeeAmount = 0;
    for (uint256 i = 0; i < requestDetails.length; i++) {
      amountAndFee += requestDetails[i].requestAmount + requestDetails[i].feeAmount;
      batchFeeAmount += requestDetails[i].requestAmount;
    }
    batchFeeAmount = (batchFeeAmount * batchFee) / feeDenominator;

    // batchFeeToPay and batchFeeAmountUSD are updated if needed
    (batchFeeAmount, batchFeeAmountUSD) = calculateBatchFeeToPay(
      batchFeeAmount,
      requestDetails[0].path[0],
      batchFeeAmountUSD,
      pathsToUSD
    );

    IERC20 requestedToken = IERC20(requestDetails[0].path[0]);

    transferToContract(requestedToken, amountAndFee, batchFeeAmount, address(paymentErc20Proxy));

    // Payer pays batch fee amount
    require(
      safeTransferFrom(requestDetails[0].path[0], feeAddress, batchFeeAmount),
      'Batch fee transferFrom() failed'
    );

    // Batch contract pays the requests using Erc20FeeProxy
    for (uint256 i = 0; i < requestDetails.length; i++) {
      RequestDetail calldata rD = requestDetails[i];
      paymentErc20Proxy.transferFromWithReferenceAndFee(
        rD.path[0],
        rD.recipient,
        rD.requestAmount,
        rD.paymentReference,
        rD.feeAmount,
        feeAddress
      );
    }

    return batchFeeAmountUSD;
  }

  /**
   * @notice Send a batch of ERC20 payments with fees and paymentReferences to multiple accounts, with multiple tokens.
   * @param requestDetails List of ERC20 requests to pay.
   * @param pathsToUSD The list of paths into USD for every token, used to limit the batch fees.
   *                   Without paths, there is not a fee limitation, and it consumes less gas.
   * @param batchFeeAmountUSD The batch fee amount in USD already paid.
   * @param feeAddress The fee recipient.
   * @dev It uses ERC20FeeProxy to pay an invoice and fees, with a payment reference.
   *      Make sure this contract has enough allowance to spend the payer's token.
   *      Make sure the payer has enough tokens to pay the amount, the fee, and the batch fee.
   */
  function _batchMultiERC20Payments(
    RequestDetail[] calldata requestDetails,
    address[][] calldata pathsToUSD,
    uint256 batchFeeAmountUSD,
    address feeAddress
  ) internal returns (uint256) {
    Token[] memory uTokens = getUTokens(requestDetails);

    // The payer transfers tokens to the batch contract and pays batch fee
    for (uint256 i = 0; i < uTokens.length && uTokens[i].amountAndFee > 0; i++) {
      uTokens[i].batchFeeAmount = (uTokens[i].batchFeeAmount * batchFee) / feeDenominator;
      IERC20 requestedToken = IERC20(uTokens[i].tokenAddress);
      transferToContract(
        requestedToken,
        uTokens[i].amountAndFee,
        uTokens[i].batchFeeAmount,
        address(paymentErc20Proxy)
      );

      // Payer pays batch fee amount

      uint256 batchFeeToPay = uTokens[i].batchFeeAmount;

      (batchFeeToPay, batchFeeAmountUSD) = calculateBatchFeeToPay(
        batchFeeToPay,
        uTokens[i].tokenAddress,
        batchFeeAmountUSD,
        pathsToUSD
      );

      require(
        safeTransferFrom(uTokens[i].tokenAddress, feeAddress, batchFeeToPay),
        'Batch fee transferFrom() failed'
      );
    }

    // Batch contract pays the requests using Erc20FeeProxy
    for (uint256 i = 0; i < requestDetails.length; i++) {
      RequestDetail calldata rD = requestDetails[i];
      paymentErc20Proxy.transferFromWithReferenceAndFee(
        rD.path[0],
        rD.recipient,
        rD.requestAmount,
        rD.paymentReference,
        rD.feeAmount,
        feeAddress
      );
    }
    return batchFeeAmountUSD;
  }

  /*
   * Helper functions
   */

  /**
   * Top up the contract with enough `requestedToken` to pay `amountAndFee`.
   *
   * It also performs a few checks:
   * - checks that the batch contract has enough allowance from the payer
   * - checks that the payer has enough funds, including batch fees
   * - increases the allowance of the contract to use the payment proxy if needed
   *
   * @param requestedToken The token to pay
   * @param amountAndFee The amount and the fee for a token to pay
   * @param batchFeeAmount The batch fee amount for a token to pay
   * @param paymentProxyAddress The payment proxy address used to pay
   */
  function transferToContract(
    IERC20 requestedToken,
    uint256 amountAndFee,
    uint256 batchFeeAmount,
    address paymentProxyAddress
  ) internal {
    // Check proxy's allowance from user
    require(
      requestedToken.allowance(msg.sender, address(this)) >= amountAndFee,
      'Insufficient allowance for batch to pay'
    );
    // Check user's funds to pay amounts, it is an approximation for conversion payment
    require(
      requestedToken.balanceOf(msg.sender) >= amountAndFee + batchFeeAmount,
      'Not enough funds, including fees'
    );

    // Transfer the amount and fees (no batch fees) required for the token on the batch contract
    require(
      safeTransferFrom(address(requestedToken), address(this), amountAndFee),
      'payment transferFrom() failed'
    );

    // Batch contract approves Erc20ConversionProxy to spend the token
    if (requestedToken.allowance(address(this), paymentProxyAddress) < amountAndFee) {
      approvePaymentProxyToSpend(address(requestedToken), paymentProxyAddress);
    }
  }

  /**
   * It create a list of unique tokens used and the amounts associated.
   * It only considers tokens having: requestAmount + feeAmount > 0.
   * Regarding ERC20 no conversion payments:
   *   batchFeeAmount is the sum of requestAmount and feeAmount.
   *   Out of the function, batch fee rate is applied
   * @param requestDetails List of requests to pay.
   */
  function getUTokens(RequestDetail[] calldata requestDetails)
    internal
    pure
    returns (Token[] memory uTokens)
  {
    // A list of unique tokens, with the sum of maxToSpend by token
    uTokens = new Token[](requestDetails.length);
    for (uint256 i = 0; i < requestDetails.length; i++) {
      for (uint256 k = 0; k < requestDetails.length; k++) {
        RequestDetail calldata rD = requestDetails[i];
        // If the token is already in the existing uTokens list
        if (uTokens[k].tokenAddress == rD.path[rD.path.length - 1]) {
          if (rD.path.length > 1) {
            uTokens[k].amountAndFee += rD.maxToSpend;
          } else {
            // It is not a conversion payment
            uTokens[k].amountAndFee += rD.requestAmount + rD.feeAmount;
            uTokens[k].batchFeeAmount += rD.requestAmount;
          }
          break;
        }
        // If the token is not in the list (amountAndFee = 0)
        else if (
          uTokens[k].amountAndFee == 0 && (rD.maxToSpend > 0 || rD.requestAmount + rD.feeAmount > 0)
        ) {
          uTokens[k].tokenAddress = rD.path[rD.path.length - 1];

          if (rD.path.length > 1) {
            // amountAndFee is used to store _maxToSpend, useful to send enough tokens to this contract
            uTokens[k].amountAndFee = rD.maxToSpend;
          } else {
            // It is not a conversion payment
            uTokens[k].amountAndFee = rD.requestAmount + rD.feeAmount;
            uTokens[k].batchFeeAmount = rD.requestAmount;
          }
          break;
        }
      }
    }
  }

  /**
   * Calculate the batch fee amount to pay, using the USD fee limitation.
   * Without pathsToUSD or a wrong one, the fee limitation is not applied.
   * @param batchFeeToPay The amount of batch fee to pay
   * @param tokenAddress The address of the token
   * @param batchFeeAmountUSD The batch fee amount in USD already paid.
   * @param pathsToUSD The list of paths into USD for every token, used to limit the batch fees.
   *                   Without paths, there is not a fee limitation, and it consumes less gas.
   */
  function calculateBatchFeeToPay(
    uint256 batchFeeToPay,
    address tokenAddress,
    uint256 batchFeeAmountUSD,
    address[][] memory pathsToUSD
  ) internal view returns (uint256, uint256) {
    // Fees are not limited if there is no pathsToUSD
    // Excepted if batchFeeAmountUSD is already >= batchFeeAmountUSDLimit
    if (pathsToUSD.length == 0 && batchFeeAmountUSD < batchFeeAmountUSDLimit) {
      return (batchFeeToPay, batchFeeAmountUSD);
    }

    // Apply the fee limit and calculate if needed batchFeeToPay
    if (batchFeeAmountUSD < batchFeeAmountUSDLimit) {
      for (uint256 i = 0; i < pathsToUSD.length; i++) {
        // Check if the pathToUSD is right
        if (
          pathsToUSD[i][0] == tokenAddress && pathsToUSD[i][pathsToUSD[i].length - 1] == USDAddress
        ) {
          (uint256 conversionUSD, ) = chainlinkConversionPath.getConversion(
            batchFeeToPay,
            pathsToUSD[i]
          );
          // Calculate the batch fee to pay, taking care of the batchFeeAmountUSDLimit
          uint256 conversionToPayUSD = conversionUSD;
          if (batchFeeAmountUSD + conversionToPayUSD > batchFeeAmountUSDLimit) {
            conversionToPayUSD = batchFeeAmountUSDLimit - batchFeeAmountUSD;
            batchFeeToPay = (batchFeeToPay * conversionToPayUSD) / conversionUSD;
          }
          batchFeeAmountUSD += conversionToPayUSD;
          // Add only once the fees
          break;
        }
      }
    } else {
      batchFeeToPay = 0;
    }
    return (batchFeeToPay, batchFeeAmountUSD);
  }

  /**
   * @notice Authorizes the proxy to spend a new request currency (ERC20).
   * @param _erc20Address Address of an ERC20 used as the request currency.
   * @param _paymentErc20Proxy Address of the proxy.
   */
  function approvePaymentProxyToSpend(address _erc20Address, address _paymentErc20Proxy) internal {
    IERC20 erc20 = IERC20(_erc20Address);
    uint256 max = 2**256 - 1;
    erc20.safeApprove(address(_paymentErc20Proxy), max);
  }

  /**
   * @notice Call transferFrom ERC20 function and validates the return data of a ERC20 contract call.
   * @dev This is necessary because of non-standard ERC20 tokens that don't have a return value.
   * @return result The return value of the ERC20 call, returning true for non-standard tokens
   */
  function safeTransferFrom(
    address _tokenAddress,
    address _to,
    uint256 _amount
  ) internal returns (bool result) {
    /* solium-disable security/no-inline-assembly */
    // check if the address is a contract
    assembly {
      if iszero(extcodesize(_tokenAddress)) {
        revert(0, 0)
      }
    }

    // solium-disable-next-line security/no-low-level-calls
    (bool success, ) = _tokenAddress.call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', msg.sender, _to, _amount)
    );

    assembly {
      switch returndatasize()
      case 0 {
        // Not a standard erc20
        result := 1
      }
      case 32 {
        // Standard erc20
        returndatacopy(0, 0, 32)
        result := mload(0)
      }
      default {
        // Anything else, should revert for safety
        revert(0, 0)
      }
    }

    require(success, 'transferFrom() has been reverted');

    /* solium-enable security/no-inline-assembly */
    return result;
  }

  /*
   * Admin functions to edit the proxies address and fees
   */

  /**
   * @notice Fees added when using Erc20/Native batch functions
   * @param _batchFee Between 0 and 200, i.e: batchFee = 30 represent 0.30% of fee
   */
  function setBatchFee(uint16 _batchFee) external onlyOwner {
    // safety to avoid wrong setting
    require(_batchFee <= 200, 'The batch fee value is too high: > 2%');
    batchFee = _batchFee;
  }

  /**
   * @param _paymentErc20Proxy The address to the Erc20 fee payment proxy to use.
   */
  function setPaymentErc20Proxy(address _paymentErc20Proxy) external onlyOwner {
    paymentErc20Proxy = IERC20FeeProxy(_paymentErc20Proxy);
  }

  /**
   * @param _paymentNativeProxy The address to the Native fee payment proxy to use.
   */
  function setPaymentNativeProxy(address _paymentNativeProxy) external onlyOwner {
    paymentNativeProxy = IEthereumFeeProxy(_paymentNativeProxy);
  }

  /**
   * @notice Update the conversion path contract used to fetch conversions.
   * @param _chainlinkConversionPath The address of the conversion path contract.
   */
  function setChainlinkConversionPath(address _chainlinkConversionPath) external onlyOwner {
    chainlinkConversionPath = ChainlinkConversionPath(_chainlinkConversionPath);
  }

  /**
   * This function define variables allowing to limit the fees:
   * NativeAddress, USDAddress, and pathsNativeToUSD.
   * @param _NativeAddress The address representing the Native currency.
   * @param _USDAddress The address representing the USD currency.
   */
  function setNativeAndUSDAddress(address _NativeAddress, address _USDAddress) external onlyOwner {
    NativeAddress = _NativeAddress;
    USDAddress = _USDAddress;
    pathsNativeToUSD = [[NativeAddress, USDAddress]];
  }

  /**
   * @param _batchFeeAmountUSDLimit The limitation of the batch fee amount in USD, e.g:
   *                                batchFeeAmountUSDLimit = 150 * 1e8 represents $150
   */
  function setBatchFeeAmountUSDLimit(uint64 _batchFeeAmountUSDLimit) external onlyOwner {
    batchFeeAmountUSDLimit = _batchFeeAmountUSDLimit;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/**
 * @title SafeERC20
 * @notice Works around implementations of ERC20 with transferFrom not returning success status.
 */
library SafeERC20 {
  /**
   * @notice Call transferFrom ERC20 function and validates the return data of a ERC20 contract call.
   * @dev This is necessary because of non-standard ERC20 tokens that don't have a return value.
   * @return result The return value of the ERC20 call, returning true for non-standard tokens
   */
  function safeTransferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _amount
  ) internal returns (bool result) {
    // solium-disable-next-line security/no-low-level-calls
    (bool success, bytes memory data) = address(_token).call(
      abi.encodeWithSignature('transferFrom(address,address,uint256)', _from, _to, _amount)
    );

    return success && (data.length == 0 || abi.decode(data, (bool)));
  }

  /**
   * @notice Call approve ERC20 function and validates the return data of a ERC20 contract call.
   * @dev This is necessary because of non-standard ERC20 tokens that don't have a return value.
   * @return result The return value of the ERC20 call, returning true for non-standard tokens
   */
  function safeApprove(
    IERC20 _token,
    address _spender,
    uint256 _amount
  ) internal returns (bool result) {
    // solium-disable-next-line security/no-low-level-calls
    (bool success, bytes memory data) = address(_token).call(
      abi.encodeWithSignature('approve(address,uint256)', _spender, _amount)
    );

    return success && (data.length == 0 || abi.decode(data, (bool)));
  }

  /**
   * @notice Call transfer ERC20 function and validates the return data of a ERC20 contract call.
   * @dev This is necessary because of non-standard ERC20 tokens that don't have a return value.
   * @return result The return value of the ERC20 call, returning true for non-standard tokens
   */
  function safeTransfer(
    IERC20 _token,
    address _to,
    uint256 _amount
  ) internal returns (bool result) {
    // solium-disable-next-line security/no-low-level-calls
    (bool success, bytes memory data) = address(_token).call(
      abi.encodeWithSignature('transfer(address,uint256)', _to, _amount)
    );

    return success && (data.length == 0 || abi.decode(data, (bool)));
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
pragma solidity ^0.8.0;

interface IERC20FeeProxy {
  event TransferWithReferenceAndFee(
    address tokenAddress,
    address to,
    uint256 amount,
    bytes indexed paymentReference,
    uint256 feeAmount,
    address feeAddress
  );

  function transferFromWithReferenceAndFee(
    address _tokenAddress,
    address _to,
    uint256 _amount,
    bytes calldata _paymentReference,
    uint256 _feeAmount,
    address _feeAddress
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEthereumFeeProxy {
  event TransferWithReferenceAndFee(
    address to,
    uint256 amount,
    bytes indexed paymentReference,
    uint256 feeAmount,
    address feeAddress
  );

  function transferWithReferenceAndFee(
    address payable _to,
    bytes calldata _paymentReference,
    uint256 _feeAmount,
    address payable _feeAddress
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './legacy_openzeppelin/contracts/access/roles/WhitelistAdminRole.sol';

interface ERC20fraction {
  function decimals() external view returns (uint8);
}

interface AggregatorFraction {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);
}

/**
 * @title ChainlinkConversionPath
 *
 * @notice ChainlinkConversionPath is a contract computing currency conversion rates based on Chainlink aggretators
 */
contract ChainlinkConversionPath is WhitelistAdminRole {
  uint256 constant PRECISION = 1e18;
  uint256 constant NATIVE_TOKEN_DECIMALS = 18;
  uint256 constant FIAT_DECIMALS = 8;
  address public nativeTokenHash;

  /**
   * @param _nativeTokenHash hash of the native token
   */
  constructor(address _nativeTokenHash) {
    nativeTokenHash = _nativeTokenHash;
  }

  // Mapping of Chainlink aggregators (input currency => output currency => contract address)
  // input & output currencies are the addresses of the ERC20 contracts OR the sha3("currency code")
  mapping(address => mapping(address => address)) public allAggregators;

  // declare a new aggregator
  event AggregatorUpdated(address _input, address _output, address _aggregator);

  /**
   * @notice Update an aggregator
   * @param _input address representing the input currency
   * @param _output address representing the output currency
   * @param _aggregator address of the aggregator contract
   */
  function updateAggregator(
    address _input,
    address _output,
    address _aggregator
  ) external onlyWhitelistAdmin {
    allAggregators[_input][_output] = _aggregator;
    emit AggregatorUpdated(_input, _output, _aggregator);
  }

  /**
   * @notice Update a list of aggregators
   * @param _inputs list of addresses representing the input currencies
   * @param _outputs list of addresses representing the output currencies
   * @param _aggregators list of addresses of the aggregator contracts
   */
  function updateAggregatorsList(
    address[] calldata _inputs,
    address[] calldata _outputs,
    address[] calldata _aggregators
  ) external onlyWhitelistAdmin {
    require(_inputs.length == _outputs.length, 'arrays must have the same length');
    require(_inputs.length == _aggregators.length, 'arrays must have the same length');

    // For every conversions of the path
    for (uint256 i; i < _inputs.length; i++) {
      allAggregators[_inputs[i]][_outputs[i]] = _aggregators[i];
      emit AggregatorUpdated(_inputs[i], _outputs[i], _aggregators[i]);
    }
  }

  /**
   * @notice Computes the conversion of an amount through a list of intermediate conversions
   * @param _amountIn Amount to convert
   * @param _path List of addresses representing the currencies for the intermediate conversions
   * @return result The result after all the conversions
   * @return oldestRateTimestamp The oldest timestamp of the path
   */
  function getConversion(uint256 _amountIn, address[] calldata _path)
    external
    view
    returns (uint256 result, uint256 oldestRateTimestamp)
  {
    (uint256 rate, uint256 timestamp, uint256 decimals) = getRate(_path);

    // initialize the result
    result = (_amountIn * rate) / decimals;

    oldestRateTimestamp = timestamp;
  }

  /**
   * @notice Computes the conversion rate from a list of currencies
   * @param _path List of addresses representing the currencies for the conversions
   * @return rate The rate
   * @return oldestRateTimestamp The oldest timestamp of the path
   * @return decimals of the conversion rate
   */
  function getRate(address[] memory _path)
    public
    view
    returns (
      uint256 rate,
      uint256 oldestRateTimestamp,
      uint256 decimals
    )
  {
    // initialize the result with 18 decimals (for more precision)
    rate = PRECISION;
    decimals = PRECISION;
    oldestRateTimestamp = block.timestamp;

    // For every conversion of the path
    for (uint256 i; i < _path.length - 1; i++) {
      (
        AggregatorFraction aggregator,
        bool reverseAggregator,
        uint256 decimalsInput,
        uint256 decimalsOutput
      ) = getAggregatorAndDecimals(_path[i], _path[i + 1]);

      // store the latest timestamp of the path
      uint256 currentTimestamp = aggregator.latestTimestamp();
      if (currentTimestamp < oldestRateTimestamp) {
        oldestRateTimestamp = currentTimestamp;
      }

      // get the rate of the current step
      uint256 currentRate = uint256(aggregator.latestAnswer());
      // get the number of decimals of the current rate
      uint256 decimalsAggregator = uint256(aggregator.decimals());

      // mul with the difference of decimals before the current rate computation (for more precision)
      if (decimalsAggregator > decimalsInput) {
        rate = rate * (10**(decimalsAggregator - decimalsInput));
      }
      if (decimalsAggregator < decimalsOutput) {
        rate = rate * (10**(decimalsOutput - decimalsAggregator));
      }

      // Apply the current rate (if path uses an aggregator in the reverse way, div instead of mul)
      if (reverseAggregator) {
        rate = (rate * (10**decimalsAggregator)) / currentRate;
      } else {
        rate = (rate * currentRate) / (10**decimalsAggregator);
      }

      // div with the difference of decimals AFTER the current rate computation (for more precision)
      if (decimalsAggregator < decimalsInput) {
        rate = rate / (10**(decimalsInput - decimalsAggregator));
      }
      if (decimalsAggregator > decimalsOutput) {
        rate = rate / (10**(decimalsAggregator - decimalsOutput));
      }
    }
  }

  /**
   * @notice Gets aggregators and decimals of two currencies
   * @param _input input Address
   * @param _output output Address
   * @return aggregator to get the rate between the two currencies
   * @return reverseAggregator true if the aggregator returned give the rate from _output to _input
   * @return decimalsInput decimals of _input
   * @return decimalsOutput decimals of _output
   */
  function getAggregatorAndDecimals(address _input, address _output)
    private
    view
    returns (
      AggregatorFraction aggregator,
      bool reverseAggregator,
      uint256 decimalsInput,
      uint256 decimalsOutput
    )
  {
    // Try to get the right aggregator for the conversion
    aggregator = AggregatorFraction(allAggregators[_input][_output]);
    reverseAggregator = false;

    // if no aggregator found we try to find an aggregator in the reverse way
    if (address(aggregator) == address(0x00)) {
      aggregator = AggregatorFraction(allAggregators[_output][_input]);
      reverseAggregator = true;
    }

    require(address(aggregator) != address(0x00), 'No aggregator found');

    // get the decimals for the two currencies
    decimalsInput = getDecimals(_input);
    decimalsOutput = getDecimals(_output);
  }

  /**
   * @notice Gets decimals from an address currency
   * @param _addr address to check
   * @return decimals number of decimals
   */
  function getDecimals(address _addr) private view returns (uint256 decimals) {
    // by default we assume it is fiat
    decimals = FIAT_DECIMALS;
    // if address is the hash of the ETH currency
    if (_addr == nativeTokenHash) {
      decimals = NATIVE_TOKEN_DECIMALS;
    } else if (isContract(_addr)) {
      // otherwise, we get the decimals from the erc20 directly
      decimals = ERC20fraction(_addr).decimals();
    }
  }

  /**
   * @notice Checks if an address is a contract
   * @param _addr Address to check
   * @return true if the address hosts a contract, false otherwise
   */
  function isContract(address _addr) private view returns (bool) {
    uint32 size;
    // solium-disable security/no-inline-assembly
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import '../Roles.sol';

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
abstract contract WhitelistAdminRole is Context {
  using Roles for Roles.Role;

  event WhitelistAdminAdded(address indexed account);
  event WhitelistAdminRemoved(address indexed account);

  Roles.Role private _whitelistAdmins;

  constructor() {
    _addWhitelistAdmin(_msgSender());
  }

  modifier onlyWhitelistAdmin() {
    require(
      isWhitelistAdmin(_msgSender()),
      'WhitelistAdminRole: caller does not have the WhitelistAdmin role'
    );
    _;
  }

  function isWhitelistAdmin(address account) public view returns (bool) {
    return _whitelistAdmins.has(account);
  }

  function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
    _addWhitelistAdmin(account);
  }

  function renounceWhitelistAdmin() public {
    _removeWhitelistAdmin(_msgSender());
  }

  function _addWhitelistAdmin(address account) internal {
    _whitelistAdmins.add(account);
    emit WhitelistAdminAdded(account);
  }

  function _removeWhitelistAdmin(address account) internal {
    _whitelistAdmins.remove(account);
    emit WhitelistAdminRemoved(account);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
   * @dev Give an account access to this role.
   */
  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  /**
   * @dev Remove an account's access to this role.
   */
  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  /**
   * @dev Check if an account has this role.
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}