// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ExchangeBase.sol";
import "./TransferManager.sol";
import "../utils/royalties/IRoyaltiesProvider.sol";

contract Exchange is ExchangeBase, TransferManager {
  function initialize(
    INftTransferProxy _transferProxy,
    IERC20TransferProxy _erc20TransferProxy,
    uint256 newProtocolFee,
    address newDefaultFeeReceiver,
    IRoyaltiesProvider newRoyaltiesProvider
  ) external initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
    __TransferExecutor_init_unchained(_transferProxy, _erc20TransferProxy);
    __TransferManager_init_unchained(
      newProtocolFee,
      newDefaultFeeReceiver,
      newRoyaltiesProvider
    );
    __OrderValidator_init_unchained();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./lib/LibFill.sol";
import "./lib/LibOrder.sol";
import "./OrderValidator.sol";
import "./AssetMatcher.sol";
import "./interfaces/ITransferManager.sol";
import "./TransferExecutor.sol";
import "./lib/LibTransfer.sol";

abstract contract ExchangeBase is
  Initializable,
  OwnableUpgradeable,
  AssetMatcher,
  TransferExecutor,
  OrderValidator,
  ITransferManager
{
  using SafeMathUpgradeable for uint256;
  using LibTransfer for address;

  uint256 private constant UINT256_MAX = 2**256 - 1;

  //state of the orders
  mapping(bytes32 => uint256) public fills;

  //events
  event Cancel(
    bytes32 hash,
    address maker,
    LibAsset.AssetType makeAssetType,
    LibAsset.AssetType takeAssetType
  );
  event Match(
    bytes32 leftHash,
    bytes32 rightHash,
    address leftMaker,
    address rightMaker,
    uint256 newLeftFill,
    uint256 newRightFill,
    LibAsset.AssetType leftAsset,
    LibAsset.AssetType rightAsset
  );

  function cancel(LibOrder.Order memory order) external {
    require(_msgSender() == order.maker, "not a maker");
    require(order.salt != 0, "0 salt can't be used");
    bytes32 orderKeyHash = LibOrder.hashKey(order);
    fills[orderKeyHash] = UINT256_MAX;
    emit Cancel(
      orderKeyHash,
      order.maker,
      order.makeAsset.assetType,
      order.takeAsset.assetType
    );
  }

  function matchOrders(
    LibOrder.Order memory orderLeft,
    bytes memory signatureLeft,
    LibOrder.Order memory orderRight,
    bytes memory signatureRight
  ) external payable {
    validateFull(orderLeft, signatureLeft);
    validateFull(orderRight, signatureRight);
    if (orderLeft.taker != address(0)) {
      require(
        orderRight.maker == orderLeft.taker,
        "leftOrder.taker verification failed"
      );
    }
    if (orderRight.taker != address(0)) {
      require(
        orderRight.taker == orderLeft.maker,
        "rightOrder.taker verification failed"
      );
    }
    matchAndTransfer(orderLeft, orderRight);
  }

  function matchAndTransfer(
    LibOrder.Order memory orderLeft,
    LibOrder.Order memory orderRight
  ) internal {
    (
      LibAsset.AssetType memory makeMatch,
      LibAsset.AssetType memory takeMatch
    ) = matchAssets(orderLeft, orderRight);
    bytes32 leftOrderKeyHash = LibOrder.hashKey(orderLeft);
    bytes32 rightOrderKeyHash = LibOrder.hashKey(orderRight);

    LibOrderData.Data memory leftOrderData = LibOrderData.parse(orderLeft);
    LibOrderData.Data memory rightOrderData = LibOrderData.parse(
      orderRight
    );

    LibFill.FillResult memory newFill = getFillSetNew(
      orderLeft,
      orderRight,
      leftOrderKeyHash,
      rightOrderKeyHash,
      leftOrderData,
      rightOrderData
    );

    (uint256 totalMakeValue, uint256 totalTakeValue) = doTransfers(
      makeMatch,
      takeMatch,
      newFill,
      orderLeft,
      orderRight,
      leftOrderData,
      rightOrderData
    );
    if (makeMatch.assetClass == LibAsset.ETH_ASSET_CLASS) {
      require(takeMatch.assetClass != LibAsset.ETH_ASSET_CLASS);
      require(msg.value >= totalMakeValue, "not enough eth");
      if (msg.value > totalMakeValue) {
        address(msg.sender).transferEth(msg.value.sub(totalMakeValue));
      }
    } else if (takeMatch.assetClass == LibAsset.ETH_ASSET_CLASS) {
      require(msg.value >= totalTakeValue, "not enough eth");
      if (msg.value > totalTakeValue) {
        address(msg.sender).transferEth(msg.value.sub(totalTakeValue));
      }
    }
    emit Match(
      leftOrderKeyHash,
      rightOrderKeyHash,
      orderLeft.maker,
      orderRight.maker,
      newFill.rightValue,
      newFill.leftValue,
      makeMatch,
      takeMatch
    );
  }

  function getHasKkey(
    LibOrder.Order memory orderLeft,
    LibOrder.Order memory orderRight
  ) public pure returns (bytes32 leftOrderKeyHash, bytes32 rightOrderKeyHash) {
    leftOrderKeyHash = LibOrder.hashKey(orderLeft);
    rightOrderKeyHash = LibOrder.hashKey(orderRight);
  }

  function getFillSetNew(
    LibOrder.Order memory orderLeft,
    LibOrder.Order memory orderRight,
    bytes32 leftOrderKeyHash,
    bytes32 rightOrderKeyHash,
    LibOrderData.Data memory leftOrderData,
    LibOrderData.Data memory rightOrderData
  ) public returns (LibFill.FillResult memory) {
    uint256 leftOrderFill = getOrderFill(orderLeft, leftOrderKeyHash);
    uint256 rightOrderFill = getOrderFill(orderRight, rightOrderKeyHash);
    LibFill.FillResult memory newFill = LibFill.fillOrder(
      orderLeft,
      orderRight,
      leftOrderFill,
      rightOrderFill,
      leftOrderData.isMakeFill,
      rightOrderData.isMakeFill
    );

    require(newFill.rightValue > 0 && newFill.leftValue > 0, "nothing to fill");

    if (orderLeft.salt != 0) {
      if (leftOrderData.isMakeFill) {
        fills[leftOrderKeyHash] = leftOrderFill.add(newFill.leftValue);
      } else {
        fills[leftOrderKeyHash] = leftOrderFill.add(newFill.rightValue);
      }
    }

    if (orderRight.salt != 0) {
      if (rightOrderData.isMakeFill) {
        fills[rightOrderKeyHash] = rightOrderFill.add(newFill.rightValue);
      } else {
        fills[rightOrderKeyHash] = rightOrderFill.add(newFill.leftValue);
      }
    }
    return newFill;
  }

  function getOrderFill(LibOrder.Order memory order, bytes32 hash)
    internal
    view
    returns (uint256 fill)
  {
    if (order.salt == 0) {
      fill = 0;
    } else {
      fill = fills[hash];
    }
  }

  function matchAssets(
    LibOrder.Order memory orderLeft,
    LibOrder.Order memory orderRight
  )
    public
    view
    returns (
      LibAsset.AssetType memory makeMatch,
      LibAsset.AssetType memory takeMatch
    )
  {
    makeMatch = matchMakeAssets(orderLeft, orderRight);
    require(makeMatch.assetClass != 0, "assets don't match");
    takeMatch = matchTakeAssets(orderLeft, orderRight);
    require(takeMatch.assetClass != 0, "assets don't match");
  }

  function validateFull(LibOrder.Order memory order, bytes memory signature)
    internal
    view
  {
    LibOrder.validate(order);
    validate(order, signature);
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../utils/lib-asset/LibAsset.sol";
import "../utils/royalties/IRoyaltiesProvider.sol";
import "../utils/lazy-mint/erc-721/LibERC721LazyMint.sol";
import "../utils/lazy-mint/erc-1155/LibERC1155LazyMint.sol";
import "./lib/LibFill.sol";
import "./lib/LibFeeSide.sol";
import "./interfaces/ITransferManager.sol";
import "./TransferExecutor.sol";
import "./lib/BpLibrary.sol";

abstract contract TransferManager is
  OwnableUpgradeable,
  ITransferManager
{
  using BpLibrary for uint256;
  using SafeMathUpgradeable for uint256;

  uint256 public protocolFee;
  IRoyaltiesProvider public royaltiesRegistry;

  address public defaultFeeReceiver;
  mapping(address => address) public feeReceivers;

  function __TransferManager_init_unchained(
    uint256 newProtocolFee,
    address newDefaultFeeReceiver,
    IRoyaltiesProvider newRoyaltiesProvider
  ) internal initializer {
    protocolFee = newProtocolFee;
    defaultFeeReceiver = newDefaultFeeReceiver;
    royaltiesRegistry = newRoyaltiesProvider;
  }

  function setRoyaltiesRegistry(IRoyaltiesProvider newRoyaltiesRegistry)
    external
    onlyOwner
  {
    royaltiesRegistry = newRoyaltiesRegistry;
  }

  function setProtocolFee(uint256 newProtocolFee) external onlyOwner {
    protocolFee = newProtocolFee;
  }

  function setDefaultFeeReceiver(address payable newDefaultFeeReceiver)
    external
    onlyOwner
  {
    defaultFeeReceiver = newDefaultFeeReceiver;
  }

  function setFeeReceiver(address token, address wallet) external onlyOwner {
    feeReceivers[token] = wallet;
  }

  function encode(LibOrderData.Data memory data)
    external
    pure
    returns (bytes memory)
  {
    return abi.encode(data);
  }

  function encode721Lazy(
    address token,
    LibERC721LazyMint.Mint721Data memory data
  ) external pure returns (bytes memory) {
    return abi.encode(token, data);
  }

  function encode1155Lazy(
    address token,
    LibERC1155LazyMint.Mint1155Data memory data
  ) external pure returns (bytes memory) {
    return abi.encode(token, data);
  }

  function getFeeReceiver(address token) internal view returns (address) {
    address wallet = feeReceivers[token];
    if (wallet != address(0)) {
      return wallet;
    }
    return defaultFeeReceiver;
  }

  function doTransfers(
    LibAsset.AssetType memory makeMatch,
    LibAsset.AssetType memory takeMatch,
    LibFill.FillResult memory fill,
    LibOrder.Order memory leftOrder,
    LibOrder.Order memory rightOrder,
    LibOrderData.Data memory leftOrderData,
    LibOrderData.Data memory rightOrderData
  ) internal override returns (uint256 totalMakeValue, uint256 totalTakeValue) {
    LibFeeSide.FeeSide feeSide = LibFeeSide.getFeeSide(
      makeMatch.assetClass,
      takeMatch.assetClass
    );
    totalMakeValue = fill.leftValue;
    totalTakeValue = fill.rightValue;
    if (feeSide == LibFeeSide.FeeSide.MAKE) {
      totalMakeValue = doTransfersWithFees(
        fill.leftValue,
        leftOrder.maker,
        leftOrderData,
        rightOrderData,
        makeMatch,
        takeMatch,
        TO_TAKER
      );
      transferPayouts(
        takeMatch,
        fill.rightValue,
        rightOrder.maker,
        leftOrderData.payouts,
        TO_MAKER
      );
    } else if (feeSide == LibFeeSide.FeeSide.TAKE) {
      totalTakeValue = doTransfersWithFees(
        fill.rightValue,
        rightOrder.maker,
        rightOrderData,
        leftOrderData,
        takeMatch,
        makeMatch,
        TO_MAKER
      );
      transferPayouts(
        makeMatch,
        fill.leftValue,
        leftOrder.maker,
        rightOrderData.payouts,
        TO_TAKER
      );
    } else {
      transferPayouts(
        makeMatch,
        fill.leftValue,
        leftOrder.maker,
        rightOrderData.payouts,
        TO_TAKER
      );
      transferPayouts(
        takeMatch,
        fill.rightValue,
        rightOrder.maker,
        leftOrderData.payouts,
        TO_MAKER
      );
    }
  }

  function doTransfersWithFees(
    uint256 amount,
    address from,
    LibOrderData.Data memory dataCalculate,
    LibOrderData.Data memory dataNft,
    LibAsset.AssetType memory matchCalculate,
    LibAsset.AssetType memory matchNft,
    bytes4 transferDirection
  ) internal returns (uint256 totalAmount) {
    totalAmount = calculateTotalAmount(
      amount,
      protocolFee,
      dataCalculate.originFees
    );
    uint256 rest = transferProtocolFee(
      totalAmount,
      amount,
      from,
      matchCalculate,
      transferDirection
    );
    rest = transferRoyalties(
      matchCalculate,
      matchNft,
      rest,
      amount,
      from,
      transferDirection
    );
    (rest, ) = transferFees(
      matchCalculate,
      rest,
      amount,
      dataCalculate.originFees,
      from,
      transferDirection,
      ORIGIN
    );
    (rest, ) = transferFees(
      matchCalculate,
      rest,
      amount,
      dataNft.originFees,
      from,
      transferDirection,
      ORIGIN
    );
    transferPayouts(
      matchCalculate,
      rest,
      from,
      dataNft.payouts,
      transferDirection
    );
  }

  function transferProtocolFee(
    uint256 totalAmount,
    uint256 amount,
    address from,
    LibAsset.AssetType memory matchCalculate,
    bytes4 transferDirection
  ) internal returns (uint256) {
    (uint256 rest, uint256 fee) = subFeeInBp(
      totalAmount,
      amount,
      protocolFee.mul(2)
    );
    if (fee > 0) {
      address tokenAddress = address(0);
      if (matchCalculate.assetClass == LibAsset.ERC20_ASSET_CLASS) {
        tokenAddress = abi.decode(matchCalculate.data, (address));
      } else if (matchCalculate.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
        uint256 tokenId;
        (tokenAddress, tokenId) = abi.decode(
          matchCalculate.data,
          (address, uint256)
        );
      }
      transfer(
        LibAsset.Asset(matchCalculate, fee),
        from,
        getFeeReceiver(tokenAddress),
        transferDirection,
        PROTOCOL
      );
    }
    return rest;
  }

  function transferRoyalties(
    LibAsset.AssetType memory matchCalculate,
    LibAsset.AssetType memory matchNft,
    uint256 rest,
    uint256 amount,
    address from,
    bytes4 transferDirection
  ) internal returns (uint256) {
    LibPart.Part[] memory fees = getRoyaltiesByAssetType(matchNft);

    (uint256 result, uint256 totalRoyalties) = transferFees(
      matchCalculate,
      rest,
      amount,
      fees,
      from,
      transferDirection,
      ROYALTY
    );
    require(totalRoyalties <= 5000, "Royalties are too high (>50%)");
    return result;
  }

  function getRoyaltiesByAssetType(LibAsset.AssetType memory matchNft)
    internal
    returns (LibPart.Part[] memory)
  {
    if (
      matchNft.assetClass == LibAsset.ERC1155_ASSET_CLASS ||
      matchNft.assetClass == LibAsset.ERC721_ASSET_CLASS
    ) {
      (address token, uint256 tokenId) = abi.decode(
        matchNft.data,
        (address, uint256)
      );
      return royaltiesRegistry.getRoyalties(token, tokenId);
    } else if (
      matchNft.assetClass == LibERC1155LazyMint.ERC1155_LAZY_ASSET_CLASS
    ) {
      (, LibERC1155LazyMint.Mint1155Data memory data) = abi.decode(
        matchNft.data,
        (address, LibERC1155LazyMint.Mint1155Data)
      );
      return data.royalties;
    } else if (
      matchNft.assetClass == LibERC721LazyMint.ERC721_LAZY_ASSET_CLASS
    ) {
      (, LibERC721LazyMint.Mint721Data memory data) = abi.decode(
        matchNft.data,
        (address, LibERC721LazyMint.Mint721Data)
      );
      return data.royalties;
    }
    LibPart.Part[] memory empty;
    return empty;
  }

  function transferFees(
    LibAsset.AssetType memory matchCalculate,
    uint256 rest,
    uint256 amount,
    LibPart.Part[] memory fees,
    address from,
    bytes4 transferDirection,
    bytes4 transferType
  ) internal returns (uint256 restValue, uint256 totalFees) {
    totalFees = 0;
    restValue = rest;
    for (uint256 i = 0; i < fees.length; i++) {
      totalFees = totalFees.add(fees[i].value);
      (uint256 newRestValue, uint256 feeValue) = subFeeInBp(
        restValue,
        amount,
        fees[i].value
      );
      restValue = newRestValue;
      if (feeValue > 0) {
        transfer(
          LibAsset.Asset(matchCalculate, feeValue),
          from,
          fees[i].account,
          transferDirection,
          transferType
        );
      }
    }
  }

  function transferPayouts(
    LibAsset.AssetType memory matchCalculate,
    uint256 amount,
    address from,
    LibPart.Part[] memory payouts,
    bytes4 transferDirection
  ) internal {
    uint256 sumBps = 0;
    uint256 restValue = amount;
    for (uint256 i = 0; i < payouts.length - 1; i++) {
      uint256 currentAmount = amount.bp(payouts[i].value);
      sumBps = sumBps.add(payouts[i].value);
      if (currentAmount > 0) {
        restValue = restValue.sub(currentAmount);
        transfer(
          LibAsset.Asset(matchCalculate, currentAmount),
          from,
          payouts[i].account,
          transferDirection,
          PAYOUT
        );
      }
    }
    LibPart.Part memory lastPayout = payouts[payouts.length - 1];
    sumBps = sumBps.add(lastPayout.value);
    require(sumBps == 10000, "Sum payouts Bps not equal 100%");
    if (restValue > 0) {
      transfer(
        LibAsset.Asset(matchCalculate, restValue),
        from,
        lastPayout.account,
        transferDirection,
        PAYOUT
      );
    }
  }

  function calculateTotalAmount(
    uint256 amount,
    uint256 feeOnTopBp,
    LibPart.Part[] memory orderOriginFees
  ) internal pure returns (uint256 total) {
    total = amount.add(amount.bp(feeOnTopBp));
    for (uint256 i = 0; i < orderOriginFees.length; i++) {
      total = total.add(amount.bp(orderOriginFees[i].value));
    }
  }

  function subFeeInBp(
    uint256 value,
    uint256 total,
    uint256 feeInBp
  ) internal pure returns (uint256 newValue, uint256 realFee) {
    return subFee(value, total.bp(feeInBp));
  }

  function subFee(uint256 value, uint256 fee)
    internal
    pure
    returns (uint256 newValue, uint256 realFee)
  {
    if (value > fee) {
      newValue = value.sub(fee);
      realFee = fee;
    } else {
      newValue = 0;
      realFee = value;
    }
  }

  uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./LibPart.sol";

interface IRoyaltiesProvider {
  struct RoyaltiesSetting {
    bool initialized;
    LibPart.Part[] royalties;
  }

  function getRoyalties(address token, uint256 tokenId)
    external
    returns (LibPart.Part[] memory);

  function setRoyaltiesCacheByTokenAndTokenId(
    address token,
    uint256 tokenId,
    LibPart.Part[] memory royalties
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibOrder.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

library LibFill {
  using SafeMathUpgradeable for uint256;

  struct FillResult {
    uint256 leftValue;
    uint256 rightValue;
  }

  /**
   * @dev Should return filled values
   * @param leftOrder left order
   * @param rightOrder right order
   * @param leftOrderFill current fill of the left order (0 if order is unfilled)
   * @param rightOrderFill current fill of the right order (0 if order is unfilled)
   * @param leftIsMakeFill true if left orders fill is calculated from the make side, false if from the take side
   * @param rightIsMakeFill true if right orders fill is calculated from the make side, false if from the take side
   */
  function fillOrder(
    LibOrder.Order memory leftOrder,
    LibOrder.Order memory rightOrder,
    uint256 leftOrderFill,
    uint256 rightOrderFill,
    bool leftIsMakeFill,
    bool rightIsMakeFill
  ) internal pure returns (FillResult memory) {
    (uint256 leftMakeValue, uint256 leftTakeValue) = LibOrder
      .calculateRemaining(leftOrder, leftOrderFill, leftIsMakeFill);
    (uint256 rightMakeValue, uint256 rightTakeValue) = LibOrder
      .calculateRemaining(rightOrder, rightOrderFill, rightIsMakeFill);

    //We have 3 cases here:
    if (rightTakeValue > leftMakeValue) {
      //1nd: left order should be fully filled
      return
        fillLeft(
          leftMakeValue,
          leftTakeValue,
          rightOrder.makeAsset.value,
          rightOrder.takeAsset.value
        );
    } //2st: right order should be fully filled or 3d: both should be fully filled if required values are the same
    return
      fillRight(
        leftOrder.makeAsset.value,
        leftOrder.takeAsset.value,
        rightMakeValue,
        rightTakeValue
      );
  }

  function checkFillOrder(
    LibOrder.Order memory leftOrder,
    LibOrder.Order memory rightOrder,
    uint256 leftOrderFill,
    uint256 rightOrderFill,
    bool leftIsMakeFill,
    bool rightIsMakeFill
  )
    public
    pure
    returns (
      uint256 leftMakeValue,
      uint256 leftTakeValue,
      uint256 rightMakeValue,
      uint256 rightTakeValue
    )
  {
    (leftMakeValue, leftTakeValue) = LibOrder.calculateRemaining(
      leftOrder,
      leftOrderFill,
      leftIsMakeFill
    );
    (rightMakeValue, rightTakeValue) = LibOrder.calculateRemaining(
      rightOrder,
      rightOrderFill,
      rightIsMakeFill
    );
  }

  function fillRight(
    uint256 leftMakeValue,
    uint256 leftTakeValue,
    uint256 rightMakeValue,
    uint256 rightTakeValue
  ) public pure returns (FillResult memory result) {
    uint256 makerValue = LibMath.safeGetPartialAmountFloor(
      rightTakeValue,
      leftMakeValue,
      leftTakeValue
    );
    require(makerValue <= rightMakeValue, "fillRight: unable to fill");
    return FillResult(rightTakeValue, makerValue);
  }

  function fillLeft(
    uint256 leftMakeValue,
    uint256 leftTakeValue,
    uint256 rightMakeValue,
    uint256 rightTakeValue
  ) public pure returns (FillResult memory result) {
    uint256 rightTake = LibMath.safeGetPartialAmountFloor(
      leftTakeValue,
      rightMakeValue,
      rightTakeValue
    );
    require(rightTake <= leftMakeValue, "fillLeft: unable to fill");
    return FillResult(leftMakeValue, leftTakeValue);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibMath.sol";
import "../../utils/lib-asset/LibAsset.sol";
import "./LibOrderData.sol";

library LibOrder {
    using SafeMathUpgradeable for uint;

    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address maker,Asset makeAsset,address taker,Asset takeAsset,uint256 salt,uint256 start,uint256 end,bytes4 dataType,bytes data)Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    struct Order {
        address maker;
        LibAsset.Asset makeAsset;
        address taker;
        LibAsset.Asset takeAsset;
        uint salt;
        uint start;
        uint end;
        bytes4 dataType;
        bytes data;
    }

    function calculateRemaining(Order memory order, uint fill, bool isMakeFill) internal pure returns (uint makeValue, uint takeValue) {
        if (isMakeFill){
            makeValue = order.makeAsset.value.sub(fill);
            takeValue = LibMath.safeGetPartialAmountFloor(order.takeAsset.value, order.makeAsset.value, makeValue);
        } else {
            takeValue = order.takeAsset.value.sub(fill);
            makeValue = LibMath.safeGetPartialAmountFloor(order.makeAsset.value, order.takeAsset.value, takeValue); 
        } 
    }

    function hashKey(Order memory order) internal pure returns (bytes32) {
        //order.data is in hash for V1 orders
        if (order.dataType == LibOrderData.V1){
            return keccak256(abi.encode(
                order.maker,
                LibAsset.hash(order.makeAsset.assetType),
                LibAsset.hash(order.takeAsset.assetType),
                order.salt,
                order.data
            ));
        } else {
            return keccak256(abi.encode(
                order.maker,
                LibAsset.hash(order.makeAsset.assetType),
                LibAsset.hash(order.takeAsset.assetType),
                order.salt
            ));
        }
        
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ORDER_TYPEHASH,
                order.maker,
                LibAsset.hash(order.makeAsset),
                order.taker,
                LibAsset.hash(order.takeAsset),
                order.salt,
                order.start,
                order.end,
                order.dataType,
                keccak256(order.data)
            ));
    }

    function validate(LibOrder.Order memory order) internal view {
        require(order.start == 0 || order.start < block.timestamp, "Order start validation failed");
        require(order.end == 0 || order.end > block.timestamp, "Order end validation failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC1271.sol";
import "./lib/LibOrder.sol";
import "../utils/libraries/LibSignature.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

abstract contract OrderValidator is
  Initializable,
  ContextUpgradeable,
  EIP712Upgradeable
{
  using LibSignature for bytes32;
  using AddressUpgradeable for address;

  bytes4 internal constant MAGICVALUE = 0x1626ba7e;

  function __OrderValidator_init_unchained() internal initializer {
    __EIP712_init_unchained("Exchange", "1");
  }

  function validate(LibOrder.Order memory order, bytes memory signature)
    internal
    view
  {
    if (order.salt == 0) {
      if (order.maker != address(0)) {
        require(_msgSender() == order.maker, "maker is not tx sender");
      } else {
        order.maker = _msgSender();
      }
    } else {
      if (_msgSender() != order.maker) {
        bytes32 hash = LibOrder.hash(order);
        address signer;
        if (signature.length == 65) {
          signer = _hashTypedDataV4(hash).recover(signature);
        }
        if (signer != order.maker) {
          if (order.maker.isContract()) {
            require(
              IERC1271(order.maker).isValidSignature(
                _hashTypedDataV4(hash),
                signature
              ) == MAGICVALUE,
              "contract order signature verification error"
            );
          } else {
            revert("order signature verification error");
          }
        }
      }
    }
  }

    function getSigner(LibOrder.Order memory order, bytes memory signature)
    public
    view returns ( address signer)
  {
    if (order.salt == 0) {
      if (order.maker != address(0)) {
        require(_msgSender() == order.maker, "maker is not tx sender");
      } else {
        order.maker = _msgSender();
      }
    } else {
      if (_msgSender() != order.maker) {
        bytes32 hash = LibOrder.hash(order);
        if (signature.length == 65) {
          signer = _hashTypedDataV4(hash).recover(signature);
        }
      }
    }
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./lib/LibOrder.sol";
import "../utils/exchange-interfaces/IAssetMatcher.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract AssetMatcher is Initializable, OwnableUpgradeable {
  bytes constant EMPTY = "";
  mapping(bytes4 => address) matchers;

  event MatcherChange(bytes4 indexed assetType, address matcher);

  function setAssetMatcher(bytes4 assetType, address matcher)
    external
    onlyOwner
  {
    matchers[assetType] = matcher;
    emit MatcherChange(assetType, matcher);
  }

  function matchMakeAssets(
    LibOrder.Order memory orderLeft,
    LibOrder.Order memory orderRight
  ) internal view returns (LibAsset.AssetType memory) {
    LibAsset.AssetType memory result = matchAssetOneSide(
      orderLeft.makeAsset.assetType,
      orderRight.takeAsset.assetType
    );
    if (result.assetClass == 0) {
      return matchAssetOneSide(orderRight.takeAsset.assetType, orderLeft.makeAsset.assetType);
    } else {
      return result;
    }
  }

  function matchTakeAssets(
    LibOrder.Order memory orderLeft,
    LibOrder.Order memory orderRight
  ) internal view returns (LibAsset.AssetType memory) {
    LibAsset.AssetType memory result = matchAssetOneSide(
      orderLeft.takeAsset.assetType,
      orderRight.makeAsset.assetType
    );
    if (result.assetClass == 0) {
      return matchAssetOneSide(orderLeft.takeAsset.assetType, orderRight.makeAsset.assetType);
    } else {
      return result;
    }
  }

  function matchAssetOneSide(
    LibAsset.AssetType memory leftAssetType,
    LibAsset.AssetType memory rightAssetType
  ) private view returns (LibAsset.AssetType memory) {
    bytes4 classLeft = leftAssetType.assetClass;
    bytes4 classRight = rightAssetType.assetClass;
    if (classLeft == LibAsset.ETH_ASSET_CLASS) {
      if (classRight == LibAsset.ETH_ASSET_CLASS) {
        return leftAssetType;
      }
      return LibAsset.AssetType(0, EMPTY);
    }
    if (classLeft == LibAsset.ERC20_ASSET_CLASS) {
      if (classRight == LibAsset.ERC20_ASSET_CLASS) {
        return simpleMatch(leftAssetType, rightAssetType);
      }
      return LibAsset.AssetType(0, EMPTY);
    }
    if (classLeft == LibAsset.ERC721_ASSET_CLASS) {
      if (classRight == LibAsset.ERC721_ASSET_CLASS) {
        return simpleMatch(leftAssetType, rightAssetType);
      }
      return LibAsset.AssetType(0, EMPTY);
    }
    if (classLeft == LibAsset.ERC1155_ASSET_CLASS) {
      if (classRight == LibAsset.ERC1155_ASSET_CLASS) {
        return simpleMatch(leftAssetType, rightAssetType);
      }
      return LibAsset.AssetType(0, EMPTY);
    }
    address matcher = matchers[classLeft];
    if (matcher != address(0)) {
      return IAssetMatcher(matcher).matchAssets(leftAssetType, rightAssetType);
    }
    if (classLeft == classRight) {
      return simpleMatch(leftAssetType, rightAssetType);
    }
    revert("not found IAssetMatcher");
  }

  function simpleMatch(
    LibAsset.AssetType memory leftAssetType,
    LibAsset.AssetType memory rightAssetType
  ) private pure returns (LibAsset.AssetType memory) {
    bytes32 leftHash = keccak256(leftAssetType.data);
    bytes32 rightHash = keccak256(rightAssetType.data);
    if (leftHash == rightHash) {
      return leftAssetType;
    }
    return LibAsset.AssetType(0, EMPTY);
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../utils/lib-asset/LibAsset.sol";
import "../lib/LibFill.sol";
import "../TransferExecutor.sol";
import "../lib/LibOrderData.sol";

abstract contract ITransferManager is ITransferExecutor {
    bytes4 constant TO_MAKER = bytes4(keccak256("TO_MAKER"));
    bytes4 constant TO_TAKER = bytes4(keccak256("TO_TAKER"));
    bytes4 constant PROTOCOL = bytes4(keccak256("PROTOCOL"));
    bytes4 constant ROYALTY = bytes4(keccak256("ROYALTY"));
    bytes4 constant ORIGIN = bytes4(keccak256("ORIGIN"));
    bytes4 constant PAYOUT = bytes4(keccak256("PAYOUT"));

    function doTransfers(
        LibAsset.AssetType memory makeMatch,
        LibAsset.AssetType memory takeMatch,
        LibFill.FillResult memory fill,
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        LibOrderData.Data memory leftOrderData,
        LibOrderData.Data memory rightOrderData
    ) internal virtual returns (uint totalMakeValue, uint totalTakeValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/exchange-interfaces/INftTransferProxy.sol";
import "../utils/exchange-interfaces/IERC20TransferProxy.sol";
import "./interfaces/ITransferExecutor.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/LibTransfer.sol";

abstract contract TransferExecutor is
  Initializable,
  OwnableUpgradeable,
  ITransferExecutor
{
  using LibTransfer for address;

  mapping(bytes4 => address) proxies;

  event ProxyChange(bytes4 indexed assetType, address proxy);

  function __TransferExecutor_init_unchained(
    INftTransferProxy transferProxy,
    IERC20TransferProxy erc20TransferProxy
  ) internal {
    proxies[LibAsset.ERC20_ASSET_CLASS] = address(erc20TransferProxy);
    proxies[LibAsset.ERC721_ASSET_CLASS] = address(transferProxy);
    proxies[LibAsset.ERC1155_ASSET_CLASS] = address(transferProxy);
  }

  function setProxy(bytes4 assetType, address proxy)
    external
    onlyOwner
  {
    proxies[assetType] = proxy;
    emit ProxyChange(assetType, proxy);
  }

  function getBytes(string memory key)
    external
    pure
    returns (bytes memory result)
  {
    result = abi.encodePacked(key);
  }

  function getBytes4(string memory key) external pure returns (bytes4 result) {
    result = bytes4(keccak256(abi.encodePacked(key)));
  }

  function getAddress(uint key) external pure returns (address addr) {
    addr = address(bytes20(sha256(abi.encodePacked(key >> 96))));
  }

  function getBytes32(string memory key)
    external
    pure
    returns (bytes32 result)
  {
    result = keccak256((abi.encodePacked(key)));
  }

  function transfer(
    LibAsset.Asset memory asset,
    address from,
    address to,
    bytes4 transferDirection,
    bytes4 transferType
  ) internal override {
    if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
      to.transferEth(asset.value);
    } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
      address token = abi.decode(asset.assetType.data, (address));
      IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS])
        .erc20safeTransferFrom(IERC20Upgradeable(token), from, to, asset.value);
    } else if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
      (address token, uint256 tokenId) = abi.decode(
        asset.assetType.data,
        (address, uint256)
      );
      require(asset.value == 1, "erc721 value error");
      INftTransferProxy(proxies[LibAsset.ERC721_ASSET_CLASS])
        .erc721safeTransferFrom(IERC721Upgradeable(token), from, to, tokenId);
    } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
      (address token, uint256 tokenId) = abi.decode(
        asset.assetType.data,
        (address, uint256)
      );
      INftTransferProxy(proxies[LibAsset.ERC1155_ASSET_CLASS])
        .erc1155safeTransferFrom(
          IERC1155Upgradeable(token),
          from,
          to,
          tokenId,
          asset.value,
          ""
        );
    } else {
      INftTransferProxy(proxies[asset.assetType.assetClass]).mintAndTransfer(
        asset,
        to
      );
    }
    emit Transfer(asset, from, to, transferDirection, transferType);
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibTransfer {
    function transferEth(address to, uint value) internal {
        (bool success,) = to.call{ value: value }("");
        require(success, "transfer failed");
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
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library LibMath {
    using SafeMathUpgradeable for uint;

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorFloor(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = numerator.mul(target).div(denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * target)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = remainder.mul(1000) >= numerator.mul(target);
    }

    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorCeil(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = numerator.mul(target).add(denominator.sub(1)).div(denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = denominator.sub(remainder) % denominator;
        isError = remainder.mul(1000) >= numerator.mul(target);
        return isError;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibAsset {
  bytes4 public constant ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
  bytes4 public constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
  bytes4 public constant NFT_ASSET_CLASS = bytes4(keccak256("NFT"));
  bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
  bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
  bytes4 public constant COLLECTION = bytes4(keccak256("COLLECTION"));
  bytes4 public constant CRYPTO_PUNKS = bytes4(keccak256("CRYPTO_PUNKS"));

  bytes32 constant ASSET_TYPE_TYPEHASH =
    keccak256("AssetType(bytes4 assetClass,bytes data)");

  bytes32 constant ASSET_TYPEHASH =
    keccak256(
      "Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

  struct AssetType {
    bytes4 assetClass;
    bytes data;
  }

  struct Asset {
    AssetType assetType;
    uint256 value;
  }

  function hash(AssetType memory assetType) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          ASSET_TYPE_TYPEHASH,
          assetType.assetClass,
          keccak256(assetType.data)
        )
      );
  }

  function hash(Asset memory asset) internal pure returns (bytes32) {
    return
      keccak256(abi.encode(ASSET_TYPEHASH, hash(asset.assetType), asset.value));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../utils/royalties/LibPart.sol";
import "./LibOrder.sol";

library LibOrderData {
    bytes4 constant public V1 = bytes4(keccak256("V1"));

    struct Data {
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
        bool isMakeFill;
    }

    function decodeOrderData(bytes memory data) internal pure returns (Data memory orderData) {
        orderData = abi.decode(data, (Data));
    }

    function parse(LibOrder.Order memory order) pure internal returns (LibOrderData.Data memory dataOrder) {
        if (order.dataType == LibOrderData.V1) {
            dataOrder = LibOrderData.decodeOrderData(order.data);
        } else if (order.dataType == 0xffffffff) {
        } else {
            revert("Unknown Order data type");
        }
        if (dataOrder.payouts.length == 0) {
            dataOrder.payouts = payoutSet(order.maker);
        }
    }

    function payoutSet(address orderAddress) pure internal returns (LibPart.Part[] memory) {
        LibPart.Part[] memory payout = new LibPart.Part[](1);
        payout[0].account = payable(orderAddress);
        payout[0].value = 10000;
        return payout;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1271 {

    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _hash Hash of the data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibSignature {
  /**
   * @dev Returns the address that signed a hashed message (`hash`) with
   * `signature`. This address can then be used for verification purposes.
   *
   * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
   * this function rejects them by requiring the `s` value to be in the lower
   * half order, and the `v` value to be either 27 or 28.
   *
   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
   * verification to be secure: it is possible to craft signatures that
   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
   * this is by receiving a hash of the original message (which may otherwise
   * be too long), and then calling {toEthSignedMessageHash} on it.
   */
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    // Check the signature length
    if (signature.length != 65) {
      revert("ECDSA: invalid signature length");
    }

    // Divide the signature in r, s and v variables
    bytes32 r;
    bytes32 s;
    uint8 v;

    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solhint-disable-next-line no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    return recover(hash, v, r, s);
  }

  /**
   * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
   * `r` and `s` signature fields separately.
   */
  function recover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    require(
      uint256(s) <=
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
      "ECDSA: invalid signature 's' value"
    );

    // If the signature is valid (and not malleable), return the signer address
    // v > 30 is a special case, we need to adjust hash with "\x19Ethereum Signed Message:\n32"
    // and v = v - 4
    address signer;
    if (v > 30) {
      require(v - 4 == 27 || v - 4 == 28, "ECDSA: invalid signature 'v' value");
      signer = ecrecover(toEthSignedMessageHash(hash), v - 4, r, s);
    } else {
      require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
      signer = ecrecover(hash, v, r, s);
    }

    require(signer != address(0), "ECDSA: invalid signature");

    return signer;
  }

  /**
   * @dev Returns an Ethereum Signed Message, created from a `hash`. This
   * replicates the behavior of the
   * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
   * JSON-RPC method.
   *
   * See {recover}.
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib-asset/LibAsset.sol";

interface IAssetMatcher {
  function matchAssets(
    LibAsset.AssetType memory leftAssetType,
    LibAsset.AssetType memory rightAssetType
  ) external view returns (LibAsset.AssetType memory);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib-asset/LibAsset.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface INftTransferProxy {
  function erc721safeTransferFrom(
    IERC721Upgradeable token,
    address from,
    address to,
    uint256 tokenId
  ) external;

  function erc1155safeTransferFrom(
    IERC1155Upgradeable token,
    address from,
    address to,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external;

  function mintAndTransfer(
    LibAsset.Asset calldata asset,
    address to
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20TransferProxy {
  function erc20safeTransferFrom(
    IERC20Upgradeable token,
    address from,
    address to,
    uint256 value
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../utils/lib-asset/LibAsset.sol";

abstract contract ITransferExecutor {

    //events
    event Transfer(LibAsset.Asset asset, address from, address to, bytes4 transferDirection, bytes4 transferType);

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        bytes4 transferDirection,
        bytes4 transferType
    ) internal virtual;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

pragma solidity ^0.8.0;

import "../../royalties/LibPart.sol";

library LibERC721LazyMint {
  bytes4 public constant ERC721_LAZY_ASSET_CLASS =
    bytes4(keccak256("ERC721_LAZY"));
  bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x8486f69f;

  struct Mint721Data {
    uint256 tokenId;
    string tokenURI;
    LibPart.Part[] creators;
    LibPart.Part[] royalties;
    bytes[] signatures;
  }

  bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
    keccak256(
      "Mint721(uint256 tokenId,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)"
    );

  function hash(Mint721Data memory data) internal pure returns (bytes32) {
    bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
    for (uint256 i = 0; i < data.royalties.length; i++) {
      royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
    }
    bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
    for (uint256 i = 0; i < data.creators.length; i++) {
      creatorsBytes[i] = LibPart.hash(data.creators[i]);
    }
    return
      keccak256(
        abi.encode(
          MINT_AND_TRANSFER_TYPEHASH,
          data.tokenId,
          keccak256(bytes(data.tokenURI)),
          keccak256(abi.encodePacked(creatorsBytes)),
          keccak256(abi.encodePacked(royaltiesBytes))
        )
      );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../royalties/LibPart.sol";

library LibERC1155LazyMint {
  bytes4 public constant ERC1155_LAZY_ASSET_CLASS =
    bytes4(keccak256("ERC1155_LAZY"));
  bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x6db15a0f;

  struct Mint1155Data {
    uint256 tokenId;
    string tokenURI;
    uint256 supply;
    LibPart.Part[] creators;
    LibPart.Part[] royalties;
    bytes[] signatures;
  }

  bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
    keccak256(
      "Mint1155(uint256 tokenId,uint256 supply,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)"
    );

  function hash(Mint1155Data memory data) internal pure returns (bytes32) {
    bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
    for (uint256 i = 0; i < data.royalties.length; i++) {
      royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
    }
    bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
    for (uint256 i = 0; i < data.creators.length; i++) {
      creatorsBytes[i] = LibPart.hash(data.creators[i]);
    }
    return
      keccak256(
        abi.encode(
          MINT_AND_TRANSFER_TYPEHASH,
          data.tokenId,
          data.supply,
          keccak256(bytes(data.tokenURI)),
          keccak256(abi.encodePacked(creatorsBytes)),
          keccak256(abi.encodePacked(royaltiesBytes))
        )
      );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/lib-asset/LibAsset.sol";

library LibFeeSide {

    enum FeeSide {NONE, MAKE, TAKE}

    function getFeeSide(bytes4 make, bytes4 take) internal pure returns (FeeSide) {
        if (make == LibAsset.ETH_ASSET_CLASS) {
            return FeeSide.MAKE;
        }
        if (take == LibAsset.ETH_ASSET_CLASS) {
            return FeeSide.TAKE;
        }
        if (make == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.MAKE;
        }
        if (take == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.TAKE;
        }
        if (make == LibAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.MAKE;
        }
        if (take == LibAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.TAKE;
        }
        return FeeSide.NONE;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library BpLibrary {
    using SafeMathUpgradeable for uint;

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}