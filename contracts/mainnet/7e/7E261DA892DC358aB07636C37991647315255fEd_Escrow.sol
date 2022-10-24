// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./IUSDT.sol";

contract Escrow {
  
  using SafeMath for uint256;

  struct Request {
    address     sender;
    RequestType reqType;
    uint256     reqValue;  // adjustment price
    uint256     reqAt;
    ReplyValue  replyValue;
    uint256     replyAt;
  }

  enum Status {
    Created,        
    ReadyToStart,        // seller and buyer both have deposited collateral funds.
    OnGoing,
    WaitingReply,
    WaitingAdminVerification,
    Finished       // contract has been completed.
  }

  enum RequestType {
    ReviewProduct,
    RejectProduct,
    AdjustPrice,
    AdminVerification
  }

  enum ReplyValue {
    Pending,
    Accept,
    Reject
  }

  address   public administrator;
  address   public seller;
  address   public buyer;
  uint256   public price;
  string    public title;
  string    public description;

  address   public feeTo;
  uint256   public feeRate;
  uint256   public collateralFactor; 
  uint256   public createdAt;
  Status    public status;

  uint256   public sellerCollateralAmount;
  uint256   public buyerCollateralAmount;

  Request public request;

  address   public USDToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  event Deposited(address depositer, uint256 amount);
  event Withdraw(address refunder, uint256 amount);
  event EscrowCompleted(uint256 amountToSeller, uint256 amountToBuyer);

  modifier onlyAdmin() {  
    require(msg.sender == administrator);
    _;
  }

  modifier onlySeller() {  
    require(msg.sender == seller);
    _;
  }

  modifier onlyBuyer() {
    require(msg.sender == buyer);
    _;
  }

  modifier onlySellerOrBuyer() {
    require(msg.sender == seller || msg.sender == buyer);
    _;
  }

  constructor(
    address _administrator,
    address _seller,
    address _buyer,
    uint256 _price,
    string  memory _title,
    string  memory _description,
    address _feeTo,
    uint256 _feeRate,
    uint256 _collateralFactor
  ) {

    administrator = _administrator;
    seller        = _seller;
    buyer         = _buyer;
    price         = _price;
    title         = _title;
    description   = _description;
    status        = Status.Created;
    createdAt     = block.timestamp;

    feeTo             = _feeTo;
    feeRate           = _feeRate;
    collateralFactor  = _collateralFactor;

    sellerCollateralAmount  = 0;
    buyerCollateralAmount   = 0;
  }

  function depositCollateral(uint256 amount) external virtual {
    require( msg.sender == seller || msg.sender == buyer);
    require( status == Status.Created );
    require( amount > 0 );

    if( msg.sender == seller ){
      sellerCollateralAmount = sellerCollateralAmount.add(amount);
    }
    else{
      buyerCollateralAmount = buyerCollateralAmount.add(amount);
    }

    TransferHelper.safeTransferFrom(USDToken, msg.sender, address(this), amount);

    if( buyerCollateralAmount >= price && sellerCollateralAmount >= price.mul(collateralFactor).div(1000) ){
      status = Status.ReadyToStart;
    }

    require(IUSDT(USDToken).balanceOf(address(this)) >= sellerCollateralAmount.add(buyerCollateralAmount));

    emit Deposited( msg.sender, amount);
  }

  function withdraw(uint256 amount) external onlySellerOrBuyer virtual {
    require ( status == Status.Created );
    require ( amount > 0 );

    if( msg.sender == seller ){
      sellerCollateralAmount = sellerCollateralAmount.sub(amount);
    }
    else{
      buyerCollateralAmount = buyerCollateralAmount.sub(amount);
    }
    
    TransferHelper.safeTransfer( USDToken, msg.sender, amount);

    require(IUSDT(USDToken).balanceOf(address(this)) >= sellerCollateralAmount.add(buyerCollateralAmount));

    emit Withdraw(msg.sender, amount);
  }

  function finalizeTransaction() external onlyBuyer {
    require ( status != Status.Finished );

    uint256 fee = price.mul(feeRate).div(1000);
    uint256 amountToSeller = sellerCollateralAmount.add(price).sub(fee);
    uint256 amountToBuyer = buyerCollateralAmount.sub(price);
    
    sellerCollateralAmount = 0;
    buyerCollateralAmount = 0;

    TransferHelper.safeTransfer(USDToken, feeTo, fee );
    TransferHelper.safeTransfer(USDToken, seller, amountToSeller);
    TransferHelper.safeTransfer(USDToken, buyer, amountToBuyer);

    status = Status.Finished;

    emit EscrowCompleted(amountToSeller, amountToBuyer);

  }

  function sendRequest(RequestType reqType, uint256 reqValue) external onlySellerOrBuyer {
 
    require( reqType >= RequestType.ReviewProduct && reqType <= RequestType.AdminVerification);

    if(reqType == RequestType.ReviewProduct){
      require( msg.sender == seller && status == Status.ReadyToStart);
    }else if(reqType == RequestType.AdminVerification){
      require( status == Status.ReadyToStart || status == Status.OnGoing || status == Status.WaitingReply);
    }else{
      require(msg.sender == buyer && status == Status.OnGoing);
    }

    if(reqType == RequestType.AdjustPrice){
      require(reqValue > 0 && reqValue < price);
    }else{
      require(reqValue == 0);
    }
    
    request = Request( msg.sender, reqType, reqValue, block.timestamp, ReplyValue.Pending, 0);
    status = Status.WaitingReply;

    if(reqType == RequestType.AdminVerification){
      status = Status.WaitingAdminVerification;
    }
  }

  function replyToRequest(ReplyValue _replyValue) external onlySellerOrBuyer {
    require(status == Status.WaitingReply);
    require( _replyValue == ReplyValue.Accept || _replyValue == ReplyValue.Reject);

    if(request.reqType == RequestType.ReviewProduct){
      require(msg.sender == buyer);
    }else{
      require(msg.sender == seller);
    }

    request.replyValue = _replyValue;
    request.replyAt = block.timestamp;

    if(request.reqType == RequestType.ReviewProduct){
      if( _replyValue == ReplyValue.Accept ){
        status = Status.OnGoing;
      }
      else{
        status = Status.ReadyToStart;
      }
    }else if(request.reqType == RequestType.RejectProduct){
      if( _replyValue == ReplyValue.Reject ){
        status = Status.OnGoing;
      }
      else{
        uint256 amountToSeller = sellerCollateralAmount;
        uint256 amountToBuyer = buyerCollateralAmount;

        sellerCollateralAmount = 0;
        buyerCollateralAmount = 0;

        TransferHelper.safeTransfer(USDToken, seller, amountToSeller);
        TransferHelper.safeTransfer(USDToken, buyer, amountToBuyer);

        status = Status.Finished;
        emit EscrowCompleted(amountToSeller, amountToBuyer);
      }
    }else if(request.reqType == RequestType.AdjustPrice){
      if(_replyValue == ReplyValue.Reject){
        status = Status.OnGoing;
      }
      else{
        price = request.reqValue;
        uint256 fee = price.mul(feeRate).div(1000);
        uint256 amountToSeller = sellerCollateralAmount.add(price).sub(fee);
        uint256 amountToBuyer = buyerCollateralAmount.sub(price);
        
        sellerCollateralAmount = 0;
        buyerCollateralAmount = 0;

        TransferHelper.safeTransfer(USDToken, feeTo, fee );
        TransferHelper.safeTransfer(USDToken, seller, amountToSeller);
        TransferHelper.safeTransfer(USDToken, buyer, amountToBuyer);

        status = Status.Finished;
        emit EscrowCompleted(amountToSeller, amountToBuyer);
      }
    }

  }

  function executeVerificationResult(uint256 amountToSeller, uint256 amountToBuyer ) external onlyAdmin {
    require(status == Status.WaitingAdminVerification);

    uint currentBalance = IUSDT(USDToken).balanceOf(address(this));
    require( currentBalance > amountToSeller.add(amountToBuyer) );
    request.replyValue = ReplyValue.Accept;
    request.replyAt = block.timestamp;

    uint256 fee = currentBalance.sub(amountToSeller).sub(amountToBuyer);

    sellerCollateralAmount = 0;
    buyerCollateralAmount = 0;

    TransferHelper.safeTransfer(USDToken, feeTo, fee );
    TransferHelper.safeTransfer(USDToken, seller, amountToSeller);
    TransferHelper.safeTransfer(USDToken, buyer, amountToBuyer);

    status = Status.Finished;
    emit EscrowCompleted(amountToSeller, amountToBuyer);
  }

  function setSellerCollateralFactor(uint256 _newCollateralFactor) external onlyBuyer {
    require(status == Status.Created);
    require(_newCollateralFactor < collateralFactor);
    collateralFactor = _newCollateralFactor;
  }

  function getDetail() external view returns(address, address, uint256, uint256, uint256, uint256, uint256, address, uint256) {
    return (
      seller,
      buyer,
      price,
      collateralFactor,
      createdAt,
      sellerCollateralAmount,
      buyerCollateralAmount,
      administrator,
      feeRate
    );
  }
}