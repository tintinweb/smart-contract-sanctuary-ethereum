// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './ILendingPoolAddressesProvider.sol';
import './ILendingPool.sol';
import './IWETHGateway.sol';
import './IPriceOracle.sol';

// interface IERC20 {
  

//     function transfer(address to, uint256 amount) external returns (bool);

//     event Transfer(address indexed from, address indexed to, uint256 value);


// }

contract DepositAave{
    string public name = "MY DeFi";

    mapping(address => uint256) public totalEthDeposited;
       mapping(address => uint256) public balance;
    // mapping(address => mapping(address => uint256)) public tokensDeposited;


    // references to Aave LendingPoolProvider and LendingPool
    ILendingPoolAddressesProvider public provider;
    ILendingPool public lendingPool;
    address addressLendingPool;
    address lendingPoolCore;
    
    // WETH Gateway to handle ETH deposits into protocol
    IWETHGateway public wethGateway; 

    // Price Oracle to get asset prices 
    IPriceOracle public priceOracle;

    event DepositedETH(
        address depositor,
        uint256 AmountDeposited,
        uint256 totalAmountDeposited  
        );

    event DepositToken(
        address depositor,
        uint256 AmountDeposited
        // uint256 tokensDeposited  
        );    
    

    constructor(){
        // Retrieve LendingPoolAddressesProvider & LendingPool using Aave Protocol V2
        // provider = ILendingPoolAddressesProvider(address(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5));  //mainnet
        //  0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5
        provider = ILendingPoolAddressesProvider(address(0x88757f2f99175387aB4C6a4b3067c77A695b0349));  //kovan
        addressLendingPool = provider.getLendingPool();
        lendingPool = ILendingPool(address(addressLendingPool));

        // Retrieve WETH Gateway
        // wethGateway = IWETHGateway(address(0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04));
        wethGateway = IWETHGateway(address(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70));   //kovan
        
       
    }

    receive() external payable {
    }

    function depositToken(address tokenAsset,uint256 _value) external payable{
        
        uint16 referralCode = 0; // referralCode 0 is like none
        uint256 amountToDeposit =_value * 1e18;
        address onBehalfOf = msg.sender;
 
        //Approve LendingPool contract to move your Asset
        IERC20(tokenAsset).approve(provider.getLendingPoolCore(), _value);


        require(IERC20(tokenAsset).transferFrom(onBehalfOf,address(this), amountToDeposit));
        balance[address(this)] += amountToDeposit;

        lendingPool.deposit(tokenAsset, amountToDeposit,address(this), referralCode);

        // Update totalDepositBalances of Token
        // tokensDeposited[msg.sender][tokenAsset] = tokensDeposited[msg.sender][tokenAsset] + amountToDeposit;

        emit DepositToken(
         msg.sender,
         msg.value
        //  tokensDeposited[msg.sender][tokenAsset]
        );
    }

    // function transfer(address _to,uint _amount) public override {
    //     require(balance[msg.sender]>=amount,"Not Enough Balance");

    // }

    function depositETH() public payable {
        uint16 referralCode = 0; // referralCode 0 is like none
        uint256 amountToDeposit = msg.value * 1e18;

     
      //WethGateWay Eth Deposit

        //  payable(address(this)).transfer(amountToDeposit);

        wethGateway.depositETH{value: msg.value}(addressLendingPool,msg.sender, referralCode);

        // Update totalDepositBalances
        totalEthDeposited[msg.sender] = totalEthDeposited[msg.sender] + amountToDeposit;

     emit DepositedETH(
         msg.sender,
         msg.value,
         totalEthDeposited[msg.sender]
        );
    }

    function balanceContract() public view returns(uint256){
        return address(this).balance;
    }
    
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

/************
@title IPriceOracle interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracle {
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address _asset) external view returns (uint256);

    /***********
    @dev sets the asset price, in wei
     */
    function setAssetPrice(address _asset, uint256 _price) external;

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IWETHGateway {
  function depositETH(
    address lendingPool,
    address onBehalfOf,
    uint16 referralCode
  ) external payable;

  function withdrawETH(
    address lendingPool,
    uint256 amount,
    address onBehalfOf
  ) external;

  function repayETH(
    address lendingPool,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external payable;

  function borrowETH(
    address lendingPool,
    uint256 amount,
    uint256 interesRateMode,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;


interface ILendingPool {
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);
  /**
   * @dev deposits The underlying asset into the reserve. A corresponding amount of the overlying asset (aTokens)
   * is minted.
   * @param reserve the address of the reserve
   * @param amount the amount to be deposited
   * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
   **/
  function deposit(
    address reserve,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev withdraws the assets of user.
   * @param reserve the address of the reserve
   * @param amount the underlying amount to be redeemed
   * @param to address that will receive the underlying
   **/
  function withdraw(
    address reserve,
    uint256 amount,
    address to
  ) external;

  /**
   * @dev Allows users to borrow a specific amount of the reserve currency, provided that the borrower
   * already deposited enough collateral.
   * @param reserve the address of the reserve
   * @param amount the amount to be borrowed
   * @param interestRateMode the interest rate mode at which the user wants to borrow. Can be 0 (STABLE) or 1 (VARIABLE)
   **/
  function borrow(
    address reserve,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice repays a borrow on the specific reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
   * @dev the target user is defined by onBehalfOf. If there is no repayment on behalf of another account,
   * onBehalfOf must be equal to msg.sender.
   * @param reserve the address of the reserve on which the user borrowed
   * @param amount the amount to repay, or uint256(-1) if the user wants to repay everything
   * @param onBehalfOf the address for which msg.sender is repaying.
   **/
  function repay(
    address reserve,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external;

  /**
   * @dev borrowers can user this function to swap between stable and variable borrow rate modes.
   * @param reserve the address of the reserve on which the user borrowed
   * @param rateMode the rate mode that the user wants to swap
   **/
  function swapBorrowRateMode(address reserve, uint256 rateMode) external;

  /**
   * @dev allows depositors to enable or disable a specific deposit as collateral.
   * @param reserve the address of the reserve
   * @param useAsCollateral true if the user wants to user the deposit as collateral, false otherwise.
   **/
  function setUserUseReserveAsCollateral(address reserve, bool useAsCollateral) external;

  /**
   * @dev users can invoke this function to liquidate an undercollateralized position.
   * @param reserve the address of the collateral to liquidated
   * @param reserve the address of the principal reserve
   * @param user the address of the borrower
   * @param purchaseAmount the amount of principal that the liquidator wants to repay
   * @param receiveAToken true if the liquidators wants to receive the aTokens, false if
   * he wants to receive the underlying asset directly
   **/
  function liquidationCall(
    address collateral,
    address reserve,
    address user,
    uint256 purchaseAmount,
    bool receiveAToken
  ) external;

  /**
   * @dev allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned. NOTE There are security concerns for developers of flashloan receiver contracts
   * that must be kept into consideration. For further details please visit https://developers.aave.com
   * @param receiver The address of the contract receiving the funds. The receiver should implement the IFlashLoanReceiver interface.
   * @param assets the address of the principal reserve
   * @param amounts the amount requested for this flashloan
   * @param modes the flashloan borrow modes
   * @param params a bytes array to be sent to the flashloan executor
   * @param referralCode the referral code of the caller
   **/
  function flashLoan(
    address receiver,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
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

  function getLendingPoolCore() external view returns (address payable);

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