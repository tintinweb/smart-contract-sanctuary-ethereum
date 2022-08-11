/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);
  function setMarketId(string calldata marketId) external;
  function setAddress(bytes32 id, address newAddress) external;
  function setAddressAsProxy(bytes32 id, address impl) external;
  function getAddress(bytes32 id) external view returns (address);
  function getLendingPool() external view returns (address);
  function setLendingPoolImpl(address pool) external;
  function getLendingPoolConfigurator() external view returns (address);
  function setLendingPoolConfiguratorImpl(address configurator) external;
  function getLendingPoolCollateralManager() external view returns (address);
  function setLendingPoolCollateralManager(address manager) external;
  function getPoolAdmin() external view returns (address);
  function setPoolAdmin(address admin) external;
  function getEmergencyAdmin() external view returns (address);
  function setEmergencyAdmin(address admin) external;
  function getPriceOracle() external view returns (address);
  function setPriceOracle(address priceOracle) external;
  function getLendingRateOracle() external view returns (address);
  function setLendingRateOracle(address lendingRateOracle) external;
}

interface ILendingPool {

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
  ) external returns (uint256);

  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);
}

contract Step3{
    mapping(address=>uint256) balances;
    address public donor_recipient;
    address private weth =  0xd0A1E359811322d97991E03f863a0C30C2cF029C; //kovan
    address addressProvider = 0x88757f2f99175387aB4C6a4b3067c77A695b0349; // kovan

    fallback() external payable {    
    }
    receive() external payable {
    }

    function depositTo() payable public{
        balances[msg.sender] += msg.value;
        IWETH(weth).deposit{value: msg.value}();
        IWETH(weth).approve(ILendingPoolAddressesProvider(addressProvider).getLendingPool(),msg.value);
        ILendingPool(addressProvider).deposit(weth,msg.value,msg.sender,0);
        //IWETH(weth).transfer(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) payable public{
        require(balances[msg.sender]>= amount);
        balances[msg.sender] -= amount;
        ILendingPool(addressProvider).withdraw(weth,amount,msg.sender);
        payable(msg.sender).transfer(amount);
    }
    function check_balance(address account) public view returns(uint256){
        return balances[account];
    }

}