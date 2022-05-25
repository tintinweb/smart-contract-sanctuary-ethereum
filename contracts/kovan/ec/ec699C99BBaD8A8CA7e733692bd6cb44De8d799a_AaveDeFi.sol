// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './ILendingPoolAddressesProvider.sol';
import './ILendingPool.sol';
import './IWETHGateway.sol';
import './IPriceOracle.sol';

 contract AaveDeFi {

    string public name = "MY DeFi";

    // Keep track balances contract
    mapping(address => uint256) public totalETHDeposits;
    mapping(address => uint256) public totalDAIBorrows;
    // mapping(address => uint256) public totalUSDCBorrows;
    // mapping(address => uint256) public totalSUSDBorrows;
    
    // Keep track latest DAI/ETH price
    uint256 public daiEthprice;
    
    // references to Aave LendingPoolProvider and LendingPool
    ILendingPoolAddressesProvider public provider;
    ILendingPool public lendingPool;
    address addressLendingPool;
    
    // WETH Gateway to handle ETH deposits into protocol
    IWETHGateway public wethGateway; 

    // Price Oracle to get asset prices 
    IPriceOracle public priceOracle;

    /// @notice DepositBorrow event emitted on success
    event DepositBorrow(
        uint256 ethAmountDeposited, 
        uint256 totalETHDeposits,
        uint256 priceDAI, 
        uint256 safeMaxDAIBorrow, 
        uint256 totalDAIBorrows
        );

    event DepositBorrow1(
        uint256 ethAmountDeposited, 
        uint256 totalETHDeposits,
        uint256 priceUSDC, 
        uint256 safeMaxUSDCBorrow, 
        uint256 totalUSDCBorrows
        );

    event DepositBorrow2(
        uint256 ethAmountDeposited, 
        uint256 totalETHDeposits,
        uint256 priceSUSD, 
        uint256 safeMaxSUSDBorrow, 
        uint256 totalSUSDBorrows
        );

    constructor(){
        // Retrieve LendingPoolAddressesProvider & LendingPool using Aave Protocol V2
        // provider = ILendingPoolAddressesProvider(address(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5)); 
        provider = ILendingPoolAddressesProvider(address(0x88757f2f99175387aB4C6a4b3067c77A695b0349));  //kovan
        addressLendingPool = provider.getLendingPool();
        lendingPool = ILendingPool(address(addressLendingPool));
        // Retrieve WETH Gateway
        // wethGateway = IWETHGateway(address(0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04));
        wethGateway = IWETHGateway(address(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70));   //kovan
        // Retrieve Price Oracle
        // priceOracle = IPriceOracle(address(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9));
        priceOracle = IPriceOracle(address(0xB8bE51E6563BB312Cbb2aa26e352516c25c26ac1));   //kovan
    }

    
    receive() external payable {
    }

    /// @notice Function to deposit ETH collateral into Aave and immediately borrow maximum safe amount of DAI  
    /// @dev DepositBorrow event emitted if successfully borrows 
    function borrowDAIAgainstETH() external payable {

        // Update ethDepositBalances
        totalETHDeposits[msg.sender] = totalETHDeposits[msg.sender] + msg.value;

        // Input variables 
        
        // address daiAddress = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI mainnet address
        address daiAddress = address(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD);  //kovan dai
 
        uint16 referralCode = 0; // referralCode 0 is like none
        uint256 variableRate = 2; // 1 is stable rate, 2 is variable rate. We will make use of variable rates
        uint ltv = 80; // The maximum Loan To Value (LTV) Ratio for the deposited asset/ETH = 0.8
        address onBehalfOf = msg.sender; 
        
        // address wethAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        address wethAddress = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C); //kovan
       

        // Deposit the ETH sent with msg.value transfering aWETH to onBehalfOf who accrues the respective deposit power
        // function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode)
        wethGateway.depositETH{value: msg.value}(addressLendingPool,address(this), referralCode);
        //require(IERC20(wethAddress).transfer(msg.sender, msg.value)); // ? risk profile is contract or individual
    
        // Use Oracle to DAI price in wei (ETH value)
        // function getAssetPrice(address asset) external view returns (uint256);
        // check result if it around value from https://www.coingecko.com/en/coins/dai/eth 
        uint priceDAI = priceOracle.getAssetPrice(daiAddress);
        daiEthprice = priceDAI;

        // Calculate the maximum safe DAI value you can borrow
        assert(priceDAI != 0);
        uint safeMaxDAIBorrow = ltv * msg.value * (10**18) / (priceDAI * 100); // remember scaling in front end
        uint256 userDAI = safeMaxDAIBorrow*99/100;
        uint256 contractDAI = safeMaxDAIBorrow*1/100;
        // Borrow the safeMaxDAIBorrow amount from protocol
        // function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        lendingPool.borrow(daiAddress, safeMaxDAIBorrow, variableRate, referralCode, address(this));

        // Send the borrowed DAI to borrower
        // require(IERC20(daiAddress).transfer(msg.sender, safeMaxDAIBorrow));
        require(IERC20(daiAddress).transfer(msg.sender, userDAI));
        

        //require(IERC20(daiAddress).transferFrom(address(this), msg.sender,safeMaxDAIBorrow));

        // Update daiBorrowBalances
        totalDAIBorrows[msg.sender] = totalDAIBorrows[msg.sender] + safeMaxDAIBorrow;

        emit DepositBorrow(
            msg.value, 
            totalETHDeposits[msg.sender],
            priceDAI, 
            safeMaxDAIBorrow, 
            totalDAIBorrows[msg.sender]      
        );
    }
    // function borrowUSDCAgainstETH() external payable {

    //     // Update ethDepositBalances
    //     totalETHDeposits[msg.sender] = totalETHDeposits[msg.sender] + msg.value;

    //     // Input variables 
        
    //     // address daiAddress = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI mainnet address
    //     address daiAddress = address(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD);  //kovan dai
    //     address USDCAddress = address(0xe22da380ee6B445bb8273C81944ADEB6E8450422); //kovan usdc
    //     // address SUSDAddress = address(0xD868790F57B39C9B2B51b12de046975f986675f9); //kovan susd
    //     // address TUSDAddress = address(0x1c4a937d171752e1313D70fb16Ae2ea02f86303e); //kovan tusd
    //     // address USDTAddress = address(0x13512979ADE267AB5100878E2e0f485B568328a4); //kovan usdt
    //     // address BUSDAddress = address(0x4c6E1EFC12FDfD568186b7BAEc0A43fFfb4bCcCf); //kovan busd
    //     // address BATAddress = address(0x2d12186Fbb9f9a8C28B3FfdD4c42920f8539D738); //kovan Bat
    //     // address KNCAddress = address(0x3F80c39c0b96A0945f9F0E9f55d8A8891c5671A8); //kovan knc
    //     // address LENDAddress = address(0x1BCe8A0757B7315b74bA1C7A731197295ca4747a); //kovan lend
    //     // address LINKAddress = address(0xAD5ce863aE3E4E9394Ab43d4ba0D80f419F61789); //kovan link
    //     // address MANAAddress = address(0x738Dc6380157429e957d223e6333Dc385c85Fec7); //kovan mana
    //     // address MKRAddress = address(0x61e4CAE3DA7FD189e52a4879C7B8067D7C2Cc0FA); //kovan mkr
    //     // address REPAddress = address(0x260071C8D61DAf730758f8BD0d6370353956AE0E); //kovan rep
    //     // address SNXAddress = address(0x7FDb81B0b8a010dd4FFc57C3fecbf145BA8Bd947); //kovan snx
    //     // address WBTCAddress = address(0x3b92f58feD223E2cB1bCe4c286BD97e42f2A12EA); //kovan wbtc
    //     // address ZRXAddress = address(0xD0d76886cF8D952ca26177EB7CfDf83bad08C00C); //kovan zrx

    //     uint16 referralCode = 0; // referralCode 0 is like none
    //     uint256 variableRate = 2; // 1 is stable rate, 2 is variable rate. We will make use of variable rates
    //     uint ltv = 80; // The maximum Loan To Value (LTV) Ratio for the deposited asset/ETH = 0.8
    //     address onBehalfOf = msg.sender; 
        
    //     // address wethAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    //     address wethAddress = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C); //kovan
       

    //     // Deposit the ETH sent with msg.value transfering aWETH to onBehalfOf who accrues the respective deposit power
    //     // function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode)
    //     wethGateway.depositETH{value: msg.value}(addressLendingPool,address(this), referralCode);
    //     //require(IERC20(wethAddress).transfer(msg.sender, msg.value)); // ? risk profile is contract or individual
    
    //     // Use Oracle to DAI price in wei (ETH value)
    //     // function getAssetPrice(address asset) external view returns (uint256);
    //     // check result if it around value from https://www.coingecko.com/en/coins/dai/eth 
    
    //     uint priceUSDC = priceOracle.getAssetPrice(USDCAddress);
    //     daiEthprice = priceUSDC;

    //     // uint priceSUSD = priceOracle.getAssetPrice(SUSDAddress);
    //     // daiEthprice = priceSUSD;

    //     // uint priceTUSD = priceOracle.getAssetPrice(TUSDAddress);
    //     // daiEthprice = priceTUSD;

    //     // Calculate the maximum safe DAI value you can borrow

    //     assert(priceUSDC != 0);
    //     uint safeMaxUSDCBorrow = ltv * msg.value * (10**18) / (priceUSDC * 100); // remember scaling in front end
      

    //     // Borrow the safeMaxDAIBorrow amount from protocol
    //     // function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
    //     lendingPool.borrow(USDCAddress, safeMaxUSDCBorrow, variableRate, referralCode, address(this));


    //     // Send the borrowed DAI to borrower
    //     require(IERC20(USDCAddress).transfer(msg.sender, safeMaxUSDCBorrow));

    //     //require(IERC20(daiAddress).transferFrom(address(this), msg.sender,safeMaxDAIBorrow));

    //     // Update usdcBorrowBalances
    //     totalUSDCBorrows[msg.sender] = totalUSDCBorrows[msg.sender] + safeMaxUSDCBorrow;

    //     emit DepositBorrow1(
    //         msg.value, 
    //         totalETHDeposits[msg.sender],
    //         priceUSDC, 
    //         safeMaxUSDCBorrow, 
    //         totalUSDCBorrows[msg.sender]
    //     );
    // }

    // function borrowSUSDAgainstETH() external payable {

    //     // Update ethDepositBalances
    //     totalETHDeposits[msg.sender] = totalETHDeposits[msg.sender] + msg.value;

    //     // Input variables 
        
    //     // address daiAddress = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI mainnet address
    //     address SUSDAddress = address(0xD868790F57B39C9B2B51b12de046975f986675f9); //kovan susd
    //     // address TUSDAddress = address(0x1c4a937d171752e1313D70fb16Ae2ea02f86303e); //kovan tusd
    //     // address USDTAddress = address(0x13512979ADE267AB5100878E2e0f485B568328a4); //kovan usdt
    //     // address BUSDAddress = address(0x4c6E1EFC12FDfD568186b7BAEc0A43fFfb4bCcCf); //kovan busd
    //     // address BATAddress = address(0x2d12186Fbb9f9a8C28B3FfdD4c42920f8539D738); //kovan Bat
    //     // address KNCAddress = address(0x3F80c39c0b96A0945f9F0E9f55d8A8891c5671A8); //kovan knc
    //     // address LENDAddress = address(0x1BCe8A0757B7315b74bA1C7A731197295ca4747a); //kovan lend
    //     // address LINKAddress = address(0xAD5ce863aE3E4E9394Ab43d4ba0D80f419F61789); //kovan link
    //     // address MANAAddress = address(0x738Dc6380157429e957d223e6333Dc385c85Fec7); //kovan mana
    //     // address MKRAddress = address(0x61e4CAE3DA7FD189e52a4879C7B8067D7C2Cc0FA); //kovan mkr
    //     // address REPAddress = address(0x260071C8D61DAf730758f8BD0d6370353956AE0E); //kovan rep
    //     // address SNXAddress = address(0x7FDb81B0b8a010dd4FFc57C3fecbf145BA8Bd947); //kovan snx
    //     // address WBTCAddress = address(0x3b92f58feD223E2cB1bCe4c286BD97e42f2A12EA); //kovan wbtc
    //     // address ZRXAddress = address(0xD0d76886cF8D952ca26177EB7CfDf83bad08C00C); //kovan zrx

    //     uint16 referralCode = 0; // referralCode 0 is like none
    //     uint256 variableRate = 2; // 1 is stable rate, 2 is variable rate. We will make use of variable rates
    //     uint ltv = 80; // The maximum Loan To Value (LTV) Ratio for the deposited asset/ETH = 0.8
    //     address onBehalfOf = msg.sender; 
        
    //     // address wethAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    //     address wethAddress = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C); //kovan
       

    //     // Deposit the ETH sent with msg.value transfering aWETH to onBehalfOf who accrues the respective deposit power
    //     // function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode)
    //     wethGateway.depositETH{value: msg.value}(addressLendingPool,address(this), referralCode);
    //     //require(IERC20(wethAddress).transfer(msg.sender, msg.value)); // ? risk profile is contract or individual
    
    //     // Use Oracle to DAI price in wei (ETH value)
    //     // function getAssetPrice(address asset) external view returns (uint256);
    //     // check result if it around value from https://www.coingecko.com/en/coins/dai/eth 
    
    //     uint priceSUSD= priceOracle.getAssetPrice(SUSDAddress);
    //     daiEthprice = priceSUSD;


    //     // Calculate the maximum safe DAI value you can borrow

    //     assert(priceSUSD != 0);
    //     uint safeMaxSUSDBorrow = ltv * msg.value * (10**18) / (priceSUSD * 100); // remember scaling in front end
      

    //     // Borrow the safeMaxDAIBorrow amount from protocol
    //     // function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
    //     lendingPool.borrow(SUSDAddress, safeMaxSUSDBorrow, variableRate, referralCode, address(this));


    //     // Send the borrowed DAI to borrower
    //     require(IERC20(SUSDAddress).transfer(msg.sender, safeMaxSUSDBorrow));

    //     //require(IERC20(daiAddress).transferFrom(address(this), msg.sender,safeMaxDAIBorrow));

    //     // Update usdcBorrowBalances
    //     totalSUSDBorrows[msg.sender] = totalSUSDBorrows[msg.sender] + safeMaxSUSDBorrow;

    //     emit DepositBorrow2(
    //         msg.value, 
    //         totalETHDeposits[msg.sender],
    //         priceSUSD, 
    //         safeMaxSUSDBorrow, 
    //         totalSUSDBorrows[msg.sender]
    //     );
    // }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0 <=0.9.0;

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
pragma solidity >=0.6.12<0.9.0;

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
pragma solidity >=0.5.0 <=0.9.0;


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
pragma solidity >=0.6.12<0.9.0;

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