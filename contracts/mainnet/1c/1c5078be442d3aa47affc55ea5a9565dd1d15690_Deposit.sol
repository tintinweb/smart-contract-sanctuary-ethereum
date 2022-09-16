/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
/// @title Sentible Pool Router Contract
/// @author Sentible
/// @notice This contract is used to deposit and withdraw from the Sentible Pool
// import "@aave/protocol-v2/contracts/interfaces/IAToken.sol";
// import "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
// import "@aave/protocol-v2/contracts/interfaces/IVariableDebtToken.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";


interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IDebtToken {
  function approveDelegation(address delegatee, uint256 amount) external;
}

interface IAaveProtocolDataProvider {
  function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}

interface AaveLendingPool {
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external;

  function paused() external view returns (bool);
}

contract Deposit {
  address owner;
  address public v2PoolAddress;
  bool public isPaused = false;
  AaveLendingPool aaveLendingPool = AaveLendingPool(v2PoolAddress);
  IAaveProtocolDataProvider provider = IAaveProtocolDataProvider(address(v2PoolAddress));

  // event NewDeposit(address owner, uint256 amount, address depositTo);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor() public {
    owner = msg.sender;
    v2PoolAddress = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
  }

  function approveAsset(address asset, uint256 amount, address spender) public onlyOwner {
    require(msg.sender == owner);
    IERC20(asset).approve(spender, amount);
  }

  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf
  ) public payable {
    uint allowedValue = IERC20(asset).allowance(address(this), msg.sender);
    require(allowedValue <=amount, "Allowance required");
    require(!aaveLendingPool.paused(), "Aave contract is paused");
    require(!isPaused, "Deposit contract is paused");

    IERC20(asset).approve(v2PoolAddress, amount);
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
    aaveLendingPool.deposit(asset, amount, onBehalfOf, 0);
  }

  function withdrawToken(
    address asset,
    uint256 amount,
    address to
  ) public payable {
    (address aTokenAddress,,) = provider.getReserveTokensAddresses(asset);
    address borrower = address(this);
    IERC20 assetToken = IERC20(asset);
    IERC20 aToken = IERC20(aTokenAddress);

    require(!aaveLendingPool.paused(), "Aave contract is paused");
    require(!isPaused, "Deposit contract is paused");
    require(aToken.allowance(to, borrower) >= amount, "Allowance required");

    aToken.approve(v2PoolAddress, amount);
    assetToken.approve(v2PoolAddress, amount);

    aToken.transferFrom(msg.sender, borrower, amount);
    aaveLendingPool.withdraw(address(assetToken), amount, borrower);
    assetToken.transferFrom(borrower, to, amount);
  }

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) public {
    IERC20 assetToken = IERC20(asset);
    require(!aaveLendingPool.paused(), "Aave contract is paused");
    require(!isPaused, "Deposit contract is paused");
    require(assetToken.approve(address(assetToken), amount), "Approve failed");

    assetToken.transferFrom(msg.sender, address(this), amount);
    assetToken.approve(v2PoolAddress, amount);
    aaveLendingPool.withdraw(address(assetToken), amount, address(this));
    assetToken.transferFrom(address(this), to, amount);
  }

  function setPoolAddress(address _poolAddress) public onlyOwner{
    require(msg.sender == owner, "Only owner can set pool address");
    v2PoolAddress = _poolAddress;
    aaveLendingPool = AaveLendingPool(_poolAddress);
    provider = IAaveProtocolDataProvider(address(_poolAddress));
  }

  function setPaused(bool _isPaused) public onlyOwner {
    require(msg.sender == owner, "Only owner can pause");
    isPaused = _isPaused;
  }
}