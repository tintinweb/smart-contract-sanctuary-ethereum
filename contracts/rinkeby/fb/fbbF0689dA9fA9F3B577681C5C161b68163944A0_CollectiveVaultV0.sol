/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// File: contracts/interfaces/TokenDecimalsInterface.sol



pragma solidity ^0.8.0;

interface Token {
    function decimals() external view returns(uint256);
}

// File: contracts/interfaces/UniswapInterface.sol



pragma solidity ^0.8.0;

interface uniswapInterface{
    function getAmountsOut(uint amountIn, address[] memory path)external view returns (uint[] memory amounts);
}
// File: contracts/interfaces/TellorInterface.sol



pragma solidity ^0.8.0;

interface tellorInterface{
    function getLastNewValueById(uint _requestId) external view returns(uint,bool);
}
// File: contracts/interfaces/Oracleinterface.sol



pragma solidity ^0.8.0;

interface OracleInterface{
    function latestAnswer() external view returns (int256);
}


// File: contracts/libraries/PlanLibrary.sol


pragma solidity ^0.8.0;


library PlanLibrary {
    
    struct PlanDetails {
       uint256 miniStakeAmount;
       uint256 maxStakeAmount;
       uint256 userLimit;
    }
}
// File: contracts/libraries/CoinsLibrary.sol


pragma solidity ^0.8.0;

library CoinsLibrary {
    
    struct CoinDetails { // checking packing
        address coinAddress;
        bool isActive;
    }
    
}

// File: contracts/libraries/SlotLibrary.sol


pragma solidity ^0.8.0;


library SlotLibrary {
   
    struct SlotDetails { // check packing
        bool resolveStatus;
        uint256 startTime;
        uint88 userCounter;
        uint256 poolTotalAmount;
        address [] users;
        address [] winers;
    }
}
// File: contracts/libraries/BettingLibrary.sol


pragma solidity ^0.8.0;

library BettingLibrary {
    
    struct BetDetails { // checking packing
        uint256 betStatus;             // for 0 => pendding, 1 => lost , 2 => winner
        uint256 betAmount;
        uint256 vaultStartTime;
        uint256 betPriceIndex;
        uint256 claimedAmount;
    }
}

// File: contracts/libraries/TransferHelper.sol



pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{ value: value }(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: contracts/upgradeability/CustomOwnable.sol



pragma solidity ^0.8.0;


/**
 * @title CustomOwnable
 * @dev This contract has the owner address providing basic authorization control
 */
contract CustomOwnable is Context  {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    // Owner of the contract
    address private _owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_msgSender() == owner(), "CustomOwnable: FORBIDDEN");
        _;
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function _setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "CustomOwnable: FORBIDDEN");
        emit OwnershipTransferred(owner(), newOwner);
        _setOwner(newOwner);
    }
}
// File: contracts/OracleWrapper.sol


pragma solidity ^0.8.0;

//**Rinkeby//
// tellerContractAddress = 0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5
// UniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

//**Binance//
// tellerContractAddress = 0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5
// UniswapV2Router02 = 0x66aD38f08bD23951Bc846484E5fCEe05aD4077b0






contract OracleWrapper is CustomOwnable {
    
    bool isInitialized;
    address public UniswapV2Router02;

    struct coinDetails {
        address oracleAddress;
        uint96   oracleType;
    }

    mapping(address => coinDetails) public coin;
   
   function initializeOracle(address _owner, address _UniswapV2Router02) public {
        require(!isInitialized,"OracleWrapperV0 : Already initialized");
        UniswapV2Router02 = _UniswapV2Router02;
        _setOwner(_owner);
        isInitialized = true;
    }
    
    function setOracleAddresses (address _coinAddress, address _oracleAddress, uint96 _oracleType) public onlyOwner {
        require((_oracleType == 1) || (_oracleType == 2), "OracleWrapperV0: Invalid oracleType");
        require(_coinAddress != address(0), "OracleWrapperV0 : Zero address");
        require(_oracleAddress != address(0), "OracleWrapperV0: Zero address");
        
        coin[_coinAddress].oracleAddress = _oracleAddress;
        coin[_coinAddress].oracleType = _oracleType;
    }
  
    function getPrice(address _coinAddress, address pair) external view returns (uint256) {
        require((coin[_coinAddress].oracleType != uint8(0)), "OracleWrapperV0 : Coin not exists");
        
        uint256 price;

        if (coin[_coinAddress].oracleType  == 1) {
            OracleInterface oObj = OracleInterface(coin[_coinAddress].oracleAddress);
            return price = uint256(oObj.latestAnswer());
        } else if (coin[_coinAddress].oracleType == 2 && pair != address(0)) {
            uniswapInterface uObj = uniswapInterface(UniswapV2Router02);
            
            address[] memory path = new address[](2);
            path[0] = _coinAddress;
            path[1] = pair;
            uint[] memory values = uObj.getAmountsOut(10**(Token(_coinAddress).decimals()), path);

            return price = (values[1] / (10 ** 10));
        }
        
        require(price != 0, "OracleWrapperV0: Price can't be zero");
        
        return 0;
        
    }
    
    function updateUniswapV2Router02(address _UniswapV2Router02) external onlyOwner {
        require(_UniswapV2Router02 != address(0), "OracleWrapperV0: Invalid address");
        UniswapV2Router02 = _UniswapV2Router02;
    }
    
    //check if this works
    function removeCoin(address _coinAddress) public onlyOwner {
        require(coin[_coinAddress].oracleType != 0, "OracleWrapperV0: Coin not exists");
        
        delete coin[_coinAddress];
    }

}
// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/interfaces/CollectiveVaultV0Events.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface CollectiveVaultV0Events {
   
    event SaveBetDetails(
        address userAddress,
        uint planType,
        address paymentCoin,
        address betCoin,
        uint slotnumber,
        uint betIndexPrice,
        uint investAmount,
        uint time
    );

    event SaveSlotDetails(
        uint planType,
        address paymentCoin,
        address betCoin,
        uint slotnumber,
        uint poolStartTime
    );
}

// File: contracts/interfaces/IERC20.sol



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    //
    //function symbol() external returns (string memory symbols);

    function decimals() external returns (uint  decimal);
}

// File: contracts/CollectiveVault.sol


pragma solidity ^0.8.4;

//**:--- Binance test ---:**//
// UniswapV2Router02 = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
// BUSD : 0x79f325FdBeB524E2914c8B769f318a9B17B4bC07
// OraclWapper : 0x2a2C28C4c40703c3DB598f3A7F17259789E8c935
// XIV : 0x59e8Cc53a30c0F2F417eB7Fcd56f2D7Ec30dC188

// DAI = 0x05fc9a77E78dBf737882Eeb2c56f6EB3a254B7fe
// MATIC = 0x6F1B27EED069408Bef5b67F6b4614965eaf68e7f
// AAVE = 0x9B6Af2decb785e4367bE65F5EC3C337D467fa021
// BAKE = 0x979281A801cF85cd1a9d723e32418d8fB26dEdF7
// BCH = 0x72Bb9CbD24d0E61Ed9b5C7Fa6b9d6dcf1Eb7FBE7
// LINK = 0xcc3A9b9d1F1B19E7cbE4be8940Bed4A46854e9eD
// BNB = 0x0000000000000000000000000000000000000001
// BTC = 0x0000000000000000000000000000000000000002
// ETH = 0x0000000000000000000000000000000000000003

// BUSD_Oracle = 0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa
// DAI_Oracle = 0xE4eE17114774713d2De0eC0f035d4F7665fc025D
// MATIC_Oracle = 0x957Eb0316f02ba4a9De3D308742eefd44a3c1719
// AAVE_Oracle = 0x298619601ebCd58d0b526963Deb2365B485Edc74
// BAKE_Oracle = 0xbe75E0725922D78769e3abF0bcb560d1E2675d5d
// BCH_Oracle = 0x887f177CBED2cf555a64e7bF125E1825EB69dB82
// LINK_Oracle = 0x1B329402Cb1825C6F30A0d92aB9E2862BE47333f
// BNB_Oracle = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
// BTC_Oracle = 0x5741306c21795FdCBb9b265Ea0255F499DFe515C
// ETH_Oracle = 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7












/**
 *  @title CollectiveVaultV0
 *  @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */

contract CollectiveVaultV0 is
    CollectiveVaultV0Events,
    CustomOwnable,
    ReentrancyGuard
{
    using BettingLibrary for BettingLibrary.BetDetails;
    using SlotLibrary for SlotLibrary.SlotDetails;
    using CoinsLibrary for CoinsLibrary.CoinDetails;
    using PlanLibrary for PlanLibrary.PlanDetails;

    //change this to 86400
    uint256 public VAULT_TIME_DIFFERENCE; // Vault Open Differance Time
    uint256 public VAULT_OPENING_TIME; // Vault start time
    uint256 public SOLO_STAKING_AMOUNT; // Solo stacking amount
    uint256 public SHARED_STAKING_AMOUNT; // Shared stacking amount
    uint256 public USER_VS_USER_STAKING_AMOUNT; // User vs User stacking amount
    uint256 public SOLO_USER_LIMIT;
    uint256 public SHARED_USER_LIMIT;
    uint256 public USER_VS_USER_USER_LIMIT;
    uint256 public LV_FEE_PERCENTAGE; // FEES GO TO LIQUIDITY VAULT
    uint256 public coinCounter;

    bool internal isInitialized;
    uint256 internal STAKING_PERIOD; // Staking period lasts
    uint256 internal CONTRIBUTE_AMOUNT; // All User contribute the same amount in XIV

    OracleWrapper public oracle;
    IERC20 XIV;
    IERC20 usdt;

    //mapping
    mapping(address => mapping(uint256 => uint256)) public coinAddressToId;                 // coinAddress => coinType :: coinId
    mapping(uint256 => mapping(uint256 => CoinsLibrary.CoinDetails)) public coins;          // coinId => coinType :: coinDetails
    mapping(uint256 => PlanLibrary.PlanDetails) public plans;                               // plantype :: planDetails

    mapping(uint256 => mapping(address => mapping(address => mapping(uint256 => SlotLibrary.SlotDetails)))) public slots;                       // betType => paymentCoin => betCoin => slotNumber
    mapping(address => mapping(uint256 => mapping(address => mapping(address => mapping(uint256 => BettingLibrary.BetDetails))))) public bets;  // userAddress => betType => paymentCoin => betCoin => slotNumber
    mapping(address => uint256) public totalClaimAmount;

    function initialize( address _admin, address _oracle, address _XIVAddress, address _usdtAddress ) public {
        require(!isInitialized, "CollectiveVaultV0 :Initailized Once");
        isInitialized = true;
        _setOwner(_admin);
        VAULT_TIME_DIFFERENCE = 30 * 60;
        VAULT_OPENING_TIME = block.timestamp; // to be changed to a reference time
        coinCounter = 1;

        PlanLibrary.PlanDetails storage plan0 = plans[0];           // Solo plan Details saved
        plan0.miniStakeAmount = 9 * 10**18;
        plan0.maxStakeAmount = 11 * 10**18;
        plan0.userLimit = 5;

        PlanLibrary.PlanDetails storage plan1 = plans[1];           // Shared plan Details saved
        plan1.miniStakeAmount = 9 * 10**18;
        plan1.maxStakeAmount = 11 * 10**18;
        plan1.userLimit = 6;

        PlanLibrary.PlanDetails storage plan2 = plans[2];           // User Vs User plan Details saved
        plan2.miniStakeAmount = 9 * 10**18;
        plan2.maxStakeAmount = 11 * 10**18;
        plan2.userLimit = 2;

        LV_FEE_PERCENTAGE = 5; // Todo : Confirm this
        STAKING_PERIOD = 86400;
        oracle = OracleWrapper(_oracle);
        XIV = IERC20(_XIVAddress);
        usdt = IERC20(_usdtAddress);
    }

    function addCoins(address _coin, uint88 _coinType) public onlyOwner {
        require( _coinType == 0 || _coinType == 1, "CollectiveVaultV0 : Coin type is invalid");                                                 // Check coin type for pyment coin = 0 and bet coin = 1;
        require( coins[coinAddressToId[_coin][_coinType]][_coinType].coinAddress == address(0), "CollectiveVaultV0 : Coin already exists");    // Check coin is aready exists or not;

        CoinsLibrary.CoinDetails storage coin = coins[coinCounter][_coinType];
        coin.coinAddress = _coin;
        coin.isActive = true;
        coinAddressToId[_coin][_coinType] = coinCounter;
        coinCounter++;
    }

    function updateCoinStatus( address _coin, uint88 _coinType, bool _coinStatus ) public onlyOwner {
        require( coins[coinAddressToId[_coin][_coinType]][_coinType].coinAddress != address(0), "CollectiveVaultV0 : Coin doesn't exists");    // Check coin is aready exists or not;
        coins[coinAddressToId[_coin][_coinType]][_coinType].isActive = _coinStatus;
    }

    function updateOracle(address _oracle) public onlyOwner {
        require( _oracle != address(0),"CollectiveVaultV0 : oracle can't be zero");
        oracle = OracleWrapper(_oracle);
    }

    function setVaultTimeDifference(uint256 value) public onlyOwner {
        VAULT_TIME_DIFFERENCE = value;
    }

    function getBettingCoinPrice(address coinAddress) public view returns (uint256) {
        uint256 currentPrice;
        if (coinAddress == address(XIV)) {
            currentPrice = oracle.getPrice(coinAddress, address(usdt));
        } else {
            currentPrice = oracle.getPrice(coinAddress, address(0)); // change to this before moving to mainnet
        }
        return currentPrice;
    }

    function getPriceInXIV(address _token) public view returns (uint256 priceInXIV) {
        if (_token == address(XIV)) {
            return priceInXIV = 1;
        }
        return priceInXIV = ((oracle.getPrice(_token, address(usdt)) * (10**18)) / oracle.getPrice(address(XIV), address(usdt))); //handle this
    }

    // Save Bets for planType Solo = 0, shared = 1, userVsUser = 2
    function saveBetDetails( uint256 _planType, address _paymentCoin, address _betCoin, uint256 _betAmount, uint96 _betPriceIndex ) public payable {
        uint256 slotCounter = (block.timestamp - VAULT_OPENING_TIME) / VAULT_TIME_DIFFERENCE;

        require( _planType == 0 || _planType == 1 || _planType == 2, "CollectiveVaultV0 : Plan type is not define");    // Check plan type for Solo = 0, shared = 1, userVsuser = 2;
        require( coins[coinAddressToId[_paymentCoin][0]][0].isActive, "CollectiveVaultV0 : Payment coin not exists");   // Check payment coin is aready exists or not;
        require( coins[coinAddressToId[_betCoin][1]][1].isActive,"CollectiveVaultV0 : Bet coin not exists");            // Check bet coin is aready exists or not;

        PlanLibrary.PlanDetails storage plan = plans[_planType];
        SlotLibrary.SlotDetails storage slot = slots[_planType][_paymentCoin][_betCoin][slotCounter];

        require(slot.userCounter <= plan.userLimit,"CollectiveVaultV0 : User limit exceeded");

        BettingLibrary.BetDetails storage bet = bets[msg.sender][_planType][_paymentCoin][_betCoin][slotCounter];

        uint256 amount;
        uint256 priceInXIV = getPriceInXIV(_paymentCoin);
        uint256 amountInXIV;

        if (_paymentCoin == address(1)) {
            amount = ((100 - LV_FEE_PERCENTAGE) * msg.value) / 100;
            amountInXIV = priceInXIV * msg.value;
            require(amountInXIV >= plan.miniStakeAmount && amountInXIV <= plan.maxStakeAmount,"CollectiveVaultV0 : Contribution is not same amount");

        } else {
            IERC20 pymentToken = IERC20(_paymentCoin);
            amount = ((100 - LV_FEE_PERCENTAGE) * _betAmount) / 100;
            amountInXIV = (priceInXIV * _betAmount) / (10**(pymentToken.decimals()));
            require(amountInXIV >= plan.miniStakeAmount && amountInXIV <= plan.maxStakeAmount,"CollectiveVaultV0 : Contribution is not same amount");
            TransferHelper.safeTransferFrom( _paymentCoin, msg.sender, address(this), _betAmount);
        }

        bet.betAmount = amount;
        bet.vaultStartTime = (((slotCounter) * VAULT_TIME_DIFFERENCE) + VAULT_OPENING_TIME);
        bet.betPriceIndex = _betPriceIndex;

        emit SaveBetDetails(
            msg.sender,
            _planType,
            _paymentCoin,
            _betCoin,
            slotCounter,
            _betPriceIndex,
            _betAmount,
            block.timestamp
        );

        if (slot.userCounter == 0) {
            emit SaveSlotDetails(
                _planType,
                _paymentCoin,
                _betCoin,
                slotCounter,
                (((slotCounter) * VAULT_TIME_DIFFERENCE) + VAULT_OPENING_TIME)
            );
        }

        slot.startTime = (((slotCounter) * VAULT_TIME_DIFFERENCE) + VAULT_OPENING_TIME);
        slot.poolTotalAmount += amount;
        slot.users[slot.userCounter] = msg.sender;
        slot.userCounter++;
    }

    // Resolve Solo bet bya owner
    // function resolveSoloBet (uint256 _betType, address _paymentCoin,address _betCoin, uint256 slotNumber) public onlyOwner {

    //     require(_betType == 0 || _betType == 1 || _betType == 2,"CollectiveVaultV0 : Plan type is not define");                // Check Bet type for Solo = 0, shared = 1, userVsuser = 2;
    //     require(paymentCoins[paymentCoinAddressToId[_paymentCoin]].isActive,"CollectiveVaultV0 : Payment coin not exists");    // check payment coin is exists or not;
    //     require(betCoins[betCoinAddressToId[_betCoin]].isActive, "CollectiveVaultV0 : Bet coin not exists");                    // check bet coin is exists or not;
    //     require(( slots[_paymentCoin][_betCoin][slotNumber][_betType].startTime + STAKING_PERIOD ) >= block.timestamp, "CollectiveVaultV0 : Slot staking period is not complete");

    //     uint256 betCoinCurrentPrice = getBettingCoinPrice(_betCoin);
    //     uint256 min = bets[slots[_paymentCoin][_betCoin][slotNumber][_betType].users[0]][slotNumber].betPriceIndex > betCoinCurrentPrice
    //         ? bets[slots[_paymentCoin][_betCoin][slotNumber][_betType].users[0]][slotNumber].betPriceIndex - betCoinCurrentPrice
    //         : betCoinCurrentPrice - bets[slots[_paymentCoin][_betCoin][slotNumber][_betType].users[0]][slotNumber].betPriceIndex;

    //     for (uint i = 0; i < slots[_paymentCoin][_betCoin][slotNumber][_betType].userCounter; i++){

    //        uint256 diff = bets[slots[_paymentCoin][_betCoin][slotNumber][_betType].users[i]][slotNumber].betPriceIndex > betCoinCurrentPrice
    //         ? bets[slots[_paymentCoin][_betCoin][slotNumber][_betType].users[i]][slotNumber].betPriceIndex - betCoinCurrentPrice
    //         : betCoinCurrentPrice - bets[slots[_paymentCoin][_betCoin][slotNumber][_betType].users[i]][slotNumber].betPriceIndex;

    //             if (min > diff) {
    //                 min = diff;
    //                 slots[_paymentCoin][_betCoin][slotNumber][_betType].winers[0] = slots[_paymentCoin][_betCoin][slotNumber][_betType].users[i];
    //             } else if (min == diff) {
    //                 min = diff;
    //                 slots[_paymentCoin][_betCoin][slotNumber][_betType].winers.push(slots[_paymentCoin][_betCoin][slotNumber][_betType].users[i]);
    //             }
    //     }
    //     slots[_paymentCoin][_betCoin][slotNumber][_betType].resolveStatus = true;
    // }

    // function claimBets(uint256 _betType, address _paymentCoin, address _betCoin, uint256 slotNumber) public {

    //     require(_betType == 0 || _betType == 1 || _betType == 2,"CollectiveVaultV0 : Plan type is invalid");                // Check Bet type for Solo = 0, shared = 1, userVsuser = 2;
    //     require(paymentCoins[paymentCoinAddressToId[_paymentCoin]].isActive,"CollectiveVaultV0 : Payment coin not exists");    // check payment coin is exists or not;
    //     require(betCoins[betCoinAddressToId[_betCoin]].isActive,"CollectiveVaultV0 : Bet coin not exists");
    //     require(slots[_paymentCoin][_betCoin][slotNumber][_betType].resolveStatus,"CollectiveVaultV0 : Bet not resolved");

    //     // claim bet for the solo plan type
    //     if(_betType == 0){
    //         for ( uint32 i = 0; i < slots[_paymentCoin][_betCoin][slotNumber][_betType].winers.length ; i++ ){
    //             require( slots[_paymentCoin][_betCoin][slotNumber][_betType].winers[i] == msg.sender, "CollectiveVaultV0 : Bet lose");
    //             winerAmountClaimed( slotNumber, _paymentCoin, (slots[_paymentCoin][_betCoin][slotNumber][_betType].poolTotalAmount / slots[_paymentCoin][_betCoin][slotNumber][_betType].winers.length) );
    //         }
    //     }
    // }

    // function winerAmountClaimed (uint256 slotCounter, address _paymentCoin, uint256 amount) internal {

    //     if ( _paymentCoin == address(1) ) {
    //         payable(msg.sender).transfer(amount);
    //     } else {
    //         TransferHelper.safeTransfer(_paymentCoin,msg.sender,amount);
    //     }

    //     bets[msg.sender][slotCounter].claimedAmount = amount;
    // }
}