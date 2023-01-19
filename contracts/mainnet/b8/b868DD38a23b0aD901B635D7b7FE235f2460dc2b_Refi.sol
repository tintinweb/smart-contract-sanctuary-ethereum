/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

/*
    .'''''''''''..     ..''''''''''''''''..       ..'''''''''''''''..
    .;;;;;;;;;;;'.   .';;;;;;;;;;;;;;;;;;,.     .,;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;,.    .,;;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.   .;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;;;;'.  .';;;;;;;;;;;;;;;;;;;;;;,. .';;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;,..   .';;;;;;;;;;;;;;;;;;;;;;;,..';;;;;;;;;;;;;;;;;;;;;;,.
    ......     .';;;;;;;;;;;;;,'''''''''''.,;;;;;;;;;;;;;,'''''''''..
              .,;;;;;;;;;;;;;.           .,;;;;;;;;;;;;;.
             .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
            .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
           .,;;;;;;;;;;;;,.           .;;;;;;;;;;;;;,.     .....
          .;;;;;;;;;;;;;'.         ..';;;;;;;;;;;;;'.    .',;;;;,'.
        .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.   .';;;;;;;;;;.
       .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.    .;;;;;;;;;;;,.
      .,;;;;;;;;;;;;;'...........,;;;;;;;;;;;;;;.      .;;;;;;;;;;;,.
     .,;;;;;;;;;;;;,..,;;;;;;;;;;;;;;;;;;;;;;;,.       ..;;;;;;;;;,.
    .,;;;;;;;;;;;;,. .,;;;;;;;;;;;;;;;;;;;;;;,.          .',;;;,,..
   .,;;;;;;;;;;;;,.  .,;;;;;;;;;;;;;;;;;;;;;,.              ....
    ..',;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.
       ..',;;;;'.    .,;;;;;;;;;;;;;;;;;;;'.
          ...'..     .';;;;;;;;;;;;;;,,,'.
                       ...............
*/

// https://github.com/trusttoken/smart-contracts
// Dependency file: contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.6.10;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// Dependency file: contracts/interfaces/ILendingPoolAddressesProvider.sol

// pragma solidity 0.6.10;

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


// Dependency file: contracts/interfaces/ILendingPool.sol

// pragma solidity 0.6.10;

interface ILendingPool {

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;
}


// Dependency file: contracts/interfaces/IFlashLoanReceiver.sol

// pragma solidity 0.6.10;

// import { ILendingPoolAddressesProvider } from 'contracts/interfaces/ILendingPoolAddressesProvider.sol';
// import { ILendingPool } from 'contracts/interfaces/ILendingPool.sol';

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

  function LENDING_POOL() external view returns (ILendingPool);
}


// Dependency file: contracts/FlashLoanReceiverBase.sol

// pragma solidity ^0.6.10;

// import { IFlashLoanReceiver } from 'contracts/interfaces/IFlashLoanReceiver.sol';
// import { ILendingPoolAddressesProvider } from 'contracts/interfaces/ILendingPoolAddressesProvider.sol';
// import { ILendingPool } from 'contracts/interfaces/ILendingPool.sol';

/** 
    !!!
    Never keep funds permanently on your FlashLoanReceiverBase contract as they could be 
    exposed to a 'griefing' attack, where the stored funds are used by an attacker.
    !!!
 */
abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  ILendingPool public immutable override LENDING_POOL;

  constructor(ILendingPoolAddressesProvider provider) public {
    ADDRESSES_PROVIDER = provider;
    LENDING_POOL = ILendingPool(provider.getLendingPool());
  }
}


// Dependency file: contracts/interfaces/ITrueFiPool2.sol

// pragma solidity 0.6.10;

interface ITrueFiPool2 {}


// Dependency file: contracts/interfaces/ILoanFactory2.sol

// pragma solidity 0.6.10;

// import {ITrueFiPool2} from "contracts/interfaces/ITrueFiPool2.sol";

interface ILoanFactory2 {
    function createLoanToken(
        ITrueFiPool2 _pool,
        uint256 _amount,
        uint256 _term,
        uint256 _apy
    ) external;
}


// Dependency file: contracts/interfaces/ILoanToken2.sol

// pragma solidity 0.6.10;

// import {IERC20} from "contracts/interfaces/IERC20.sol";
// import {ITrueFiPool2} from "contracts/interfaces/ITrueFiPool2.sol";

interface ILoanToken2 is IERC20 {
    enum Status {
        Awaiting,
        Funded,
        Withdrawn,
        Settled,
        Defaulted,
        Liquidated
    }

    function borrower() external view returns (address);

    function amount() external view returns (uint256);

    function term() external view returns (uint256);

    function apy() external view returns (uint256);

    function start() external view returns (uint256);

    function lender() external view returns (address);

    function debt() external view returns (uint256);

    function pool() external view returns (ITrueFiPool2);

    function profit() external view returns (uint256);

    function status() external view returns (Status);

    function getParameters()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function fund() external;

    function withdraw(address _beneficiary) external;

    function settle() external;

    function enterDefault() external;

    function liquidate() external;

    function redeem(uint256 _amount) external;

    function repay(address _sender, uint256 _amount) external;

    function repayInFull(address _sender) external;

    function reclaim() external;

    function allowTransfer(address account, bool _status) external;

    function repaid() external view returns (uint256);

    function isRepaid() external view returns (bool);

    function balance() external view returns (uint256);

    function value(uint256 _balance) external view returns (uint256);

    function token() external view returns (IERC20);

    function version() external pure returns (uint8);
}


// Dependency file: contracts/interfaces/ITrueLender2.sol

// pragma solidity 0.6.10;

// import {ILoanToken2} from "contracts/interfaces/ILoanToken2.sol";

interface ITrueLender2 {
    function reclaim(ILoanToken2 loanToken, bytes calldata data) external;

    function fund(ILoanToken2 loanToken) external;
}


// Dependency file: contracts/interfaces/ITrueRatingAgencyV2.sol

// pragma solidity 0.6.10;

interface ITrueRatingAgencyV2 {
    function allow(address who, bool status) external;

    function submit(address id) external;

    function yes(address id) external;
}


// Root file: contracts/Refi.sol

pragma solidity 0.6.10;

// import {IERC20} from "contracts/interfaces/IERC20.sol";
// import {FlashLoanReceiverBase} from "contracts/FlashLoanReceiverBase.sol";
// import {ILendingPool} from "contracts/interfaces/ILendingPool.sol";
// import {ILendingPoolAddressesProvider} from "contracts/interfaces/ILendingPoolAddressesProvider.sol";
// import {ILoanFactory2} from "contracts/interfaces/ILoanFactory2.sol";
// import {ILoanToken2} from "contracts/interfaces/ILoanToken2.sol";
// import {ITrueFiPool2} from "contracts/interfaces/ITrueFiPool2.sol";
// import {ITrueLender2} from "contracts/interfaces/ITrueLender2.sol";
// import {ITrueRatingAgencyV2} from "contracts/interfaces/ITrueRatingAgencyV2.sol";

/** 
    !!!
    Never keep funds permanently on your FlashLoanReceiverBase contract as they could be 
    exposed to a 'griefing' attack, where the stored funds are used by an attacker.
    !!!
 */
contract Refi is FlashLoanReceiverBase {
    address public constant OWNER = 0xf0aE09d3ABdF3641e2eB4cD45cf56873296a02CB;

    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ILoanToken2 public constant OLD_LOAN =
        ILoanToken2(0x232E0A81c41C0B0999e7b671cb5046BeB808C49F);
    ITrueFiPool2 public constant TF_USDC_POOL =
        ITrueFiPool2(0xA991356d261fbaF194463aF6DF8f0464F8f1c742);
    ILoanFactory2 public constant LOAN_FACTORY =
        ILoanFactory2(0x69d844fB5928d0e7Bc530cC6325A88e53d6685BC);
    ITrueLender2 public constant LENDER =
        ITrueLender2(0xa606dd423dF7dFb65Efe14ab66f5fDEBf62FF583);
    ITrueRatingAgencyV2 public constant RATING_AGENCY =
        ITrueRatingAgencyV2(0x05461334340568075bE35438b221A3a0D261Fb6b);

    ILoanToken2 public newLoan;

    address[] public assets;
    uint256[] public amounts;
    uint256[] public modes;

    constructor()
        public
        FlashLoanReceiverBase(
            ILendingPoolAddressesProvider(
                0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
            )
        )
    {
        assets.push(address(USDC));
        amounts.push(OLD_LOAN.debt());
        modes.push(0);
    }

    function createLoan(uint256 newLoanDuration) external {
        require(msg.sender == OWNER);
        LOAN_FACTORY.createLoanToken(
            TF_USDC_POOL,
            OLD_LOAN.debt(),
            newLoanDuration,
            0
        );
    }

    function submitForRating(ILoanToken2 _newLoan) external {
        require(msg.sender == OWNER);
        newLoan = _newLoan;
        RATING_AGENCY.submit(address(_newLoan));
    }

    function refinance() external {
        require(msg.sender == OWNER);
        LENDING_POOL.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(0),
            "",
            0x0
        );
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata,
        uint256[] calldata _amounts,
        uint256[] calldata _premiums,
        address,
        bytes calldata
    ) external override returns (bool) {
        USDC.approve(address(OLD_LOAN), OLD_LOAN.debt());
        OLD_LOAN.repayInFull(address(this));
        LENDER.reclaim(OLD_LOAN, "");
        LENDER.fund(newLoan);
        newLoan.withdraw(address(this));
        USDC.approve(address(LENDING_POOL), _amounts[0] + _premiums[0]);
        return true;
    }

    function withdraw() external {
        require(msg.sender == OWNER);
        USDC.transfer(OWNER, USDC.balanceOf(address(this)));
    }
}