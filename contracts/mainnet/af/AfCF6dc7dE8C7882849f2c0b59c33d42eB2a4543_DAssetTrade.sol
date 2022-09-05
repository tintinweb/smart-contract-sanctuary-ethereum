// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Auction.sol";

contract DAssetTrade {

  address   public administrator;
  
  uint256   public feeRate = 40;            // 4%
  uint256   public collateralFactor = 100;  // 10%
  address   public feeTo;

  address[] public escrows;
  address[] public simpleSales;
  address[] public auctions;

  event escrowCreated(address _newEscrowAddr);
  event simpleSaleCreated(address _newProductAddr);
  event auctionCreated(address _newProductAddr);

  modifier onlyAdmin() {
    require( msg.sender == administrator );
    _;
  }  

  constructor () {
    administrator = msg.sender;
    feeTo         = msg.sender;
  }


  function changeAdmin(address _newAdmin) external onlyAdmin {
    administrator = _newAdmin;
  }

  function setFeeTo(address _feeTo) external onlyAdmin {
    feeTo = _feeTo;
  }

  function setFeeRate(uint _feeRate) external onlyAdmin {
    feeRate = _feeRate;
  }

  function setCollateralFactor(uint _collateralFactor) external onlyAdmin {
    collateralFactor = _collateralFactor;
  }

  function createEscrow(
    address  _buyer,
    uint256 _price,
    string memory _title,
    string memory _description
  ) external {
    Escrow escrow = new Escrow(administrator, msg.sender, _buyer, _price, _title, _description, feeTo, feeRate, collateralFactor);
    escrows.push(address(escrow));
    emit escrowCreated(address(escrow));
  }

  function createSimpleSale(
    uint256 _price,
    string memory _title,
    string memory _description
  ) external {
    SimpleSale simple = new SimpleSale(administrator, msg.sender, _price, _title, _description, feeTo, feeRate, collateralFactor);
    simpleSales.push(address(simple));
    emit simpleSaleCreated(address(simple));
  }

  function createAuction(
    uint256 _initialPrice,
    uint256 _maximumPrice,
    uint256 _bidStep,
    uint256 _period,
    string memory _title,
    string memory _description
  ) external {
    Auction auction = new Auction(administrator, msg.sender, _initialPrice, _maximumPrice, _bidStep, _period, _title, _description, feeTo, feeRate, collateralFactor);
    auctions.push(address(auction));
    emit auctionCreated(address(auction));
  }

  function getDetail() external view returns (address, address, uint256, uint256, address[] memory, address[] memory, address[] memory) {
    return (administrator, feeTo, feeRate, collateralFactor, escrows, simpleSales, auctions);
  }
}