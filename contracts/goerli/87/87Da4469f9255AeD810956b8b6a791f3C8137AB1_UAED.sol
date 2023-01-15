// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "@openzeppelin/contracts/access/Ownable2Step.sol" ;
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IFlashLoanReceiver {
    function executeOperation(uint premium) external returns (bool);
}

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );
}

// asset :   [BTC, WBTC, ETH, DAI, USDC, USDT, UAED, BUSD]
// assetId:  [  0,    1,   2,   3,    4,    5,    6,    7]

contract UAED is ERC20 {

    string private _name = "FALCOIN";
    string private _symbol = "UAED";
    address public owner;
    address public owner2; 
    address ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;  
    uint interestRatePerHour = 913;              // 8 decimals
    uint public fiatBackedTotalSupply ;

    mapping (uint8 => bool)public isPausedAsCollateral ;

    address[] public tokenAddress;      // collateral contract address
    address[] public priceFeed;
    uint8[] public collateralFactor;    // 2 decimals
    uint8[] public tokenDecimals;
    uint8[] public priceFeedDecimals;
    address public uaedRequestor;

    constructor(address _uaedRequestor, address uaedPF, address _wbtc, address _dai, address _usdc, address _usdt, address _busd) ERC20(_name, _symbol) {
        owner = msg.sender;
        owner2 = msg.sender;
        uaedRequestor = _uaedRequestor;

        // collateral contract address
        tokenAddress = [
            ZERO_ADDRESS,             // BTC
            _wbtc,                    // WBTC   Goerli
            ZERO_ADDRESS,             // ETH
            _dai,                     // DAI    Goerli
            _usdc,                    // USDC   Goerli
            _usdt,                    // USDT   Goerli
            address(this),            // UAED
            _busd                     // BUSD   Goerli
        ];

        tokenDecimals = [
            0,  // BTC     (decimals => 8 )   not used
            8,  // WBTC    (decimals => 8 )
            18, // ETH     (decimals => 18)
            18, // DAI     (decimals => 18)
            6,  // USDC    (decimals => 6 )
            6,  // USDT    (decimals => 6 )
            6,  // UAED    (decimals => 6 )
            18  // BUSD    (decimals => 18)
        ];

        // max of collateralFactor is 100, and uint8 supports 2^8=256 so is sufficiant
        collateralFactor = [                                            // 2 decimals
            0,                    // BTC      0
            90,                   // WBTC     1
            90,                   // ETH      2
            95,                   // DAI      3
            95,                   // USDC     4
            95,                   // USDT     5
            0,                    // UAED     6
            95                    // BUSD     7
        ];   

        // collateral priceFeed on Goerli Mainnet
        // address checked in etherscan.io
        priceFeed = [
            0xA39434A63A52E749F02807ae27335515BA4b07F7, // BTC /USD    (decimals => 8 )  Goerli
            0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7, // WBTC/BTC    (decimals => 8 )  Goerli  USDC/USD
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e, // ETH /USD    (decimals => 8 )  Goerli
            0x0d79df66BE487753B02D015Fb622DED7f0E9798d, // DAI /USD    (decimals => 8 )  Goerli
            0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7, // USDC/USD    (decimals => 8 )  Goerli  USDC/USD
            0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7, // USDT/USD    (decimals => 8 )  Goerli  USDC/USD
            uaedPF,                                     // UAED/USD    (decimals => 8 )  
            0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7  // BUSD/USD    (decimals => 8 )  Goerli  USDC/USD
        ];

        priceFeedDecimals = [
            8,                      // BTC /USD
            8,                      // WBTC/BTC
            8,                      // ETH /USD
            8,                      // DAI /USD
            8,                      // USDC/USD
            8,                      // USDT/USD
            8,                      // UAED/USD
            8                       // BUSD/USD            
        ];
    }

    fallback() external payable {
        if (msg.value > 0) {
            require(!pledgor[msg.sender][2].isPledgedBefore, "Repetitious asset");
            _mintByCollateral(msg.sender, msg.value, 2, collateralFactor[2] / 2 ); // default collateralFactor is 75%
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    modifier onlyUAEDrequestor() {
        require(msg.sender == uaedRequestor, "onlyUAEDrequestor");
        _;
    } 

    modifier notPausedAsCollateral(uint8 _assetId){
        require(!isPausedAsCollateral[_assetId], "pausedAsset");
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function changeOwner2(address _owner2) external onlyOwner {
        owner2 = _owner2;
    }

    //////////////////////////////////////////// getting assets' price ////////////////////////////////////////////

    function getPriceInUSD(uint8 _assetId) public returns (uint256) {
        require(_assetId < priceFeed.length, "incorrect assetId");
        (
            /*uint80 roundID*/,
            int256 _price, 
            /*uint startedAt*/,
            /*uint timestamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(priceFeed[_assetId]).latestRoundData();

        if (_assetId == 1) {
            return uint256(_price) * getPriceInUSD(0)/ 1e8; //    WBTC/USD = WBTC/BTC * BTC/USD
        } else {
            return uint256(_price);
        }
    } 

    
    //////////////// change financial parameters and manage requests ////////////////////////////
    
    function changeCollateralFactor(uint8 _assetId, uint8 _collateralFactor) external onlyUAEDrequestor {
        collateralFactor[_assetId] = _collateralFactor;
    }

    //------------------
    function changePriceFeed(address _priceFeed, uint8 _assetId, uint8 _priceFeedDecimals) external onlyUAEDrequestor {
        priceFeed[_assetId] = _priceFeed;
        priceFeedDecimals[_assetId] = _priceFeedDecimals;
    }

    //------------------
    function addAssetAsCollateral(address _tokenAddress, address _priceFeed, uint8 _tokenDecimals, uint8 _collateralFactor, uint8 _priceFeedDecimals) external onlyUAEDrequestor returns(uint8 assetN){
        tokenAddress.push(_tokenAddress);
        priceFeed.push(_priceFeed);
        tokenDecimals.push(_tokenDecimals);
        priceFeedDecimals.push(_priceFeedDecimals);
        collateralFactor.push(_collateralFactor);

        assetN = uint8(tokenAddress.length);
        assert(priceFeed.length == assetN && tokenDecimals.length == assetN && priceFeedDecimals.length == assetN && collateralFactor.length == assetN);
    }

    //------------------
    function toggleCollateralPause(uint8 _assetId) external onlyUAEDrequestor {
        isPausedAsCollateral[_assetId] = !isPausedAsCollateral[_assetId];
    }

    //------------------
    function changeInterestRate(uint _interestRate) external onlyUAEDrequestor {
        interestRatePerHour = _interestRate;
    }
    

    ///////////////////////////////////////// get collateral and mint UAED //////////////////////////////////////////
    /*
        algorithm to calculate the amount of UAED that should be minted by depositing collaterals
        
        UAED minted :
        assetNumber * assetPrice/USD * USD/AED * userPercentage ;

        equation that sould be true (otherwise user should be liquidated ):
        assetNumber * (assetPrice/USD * USD/AED)' * collateralFactor >= assetNumber * assetPrice/USD * USD/AED * userPercentage
        Notice : in equation above , ' charachter means the price in second state 
    */

    event mintedByCollateral(
        address indexed user,
        uint8 indexed assetId,
        uint collateralAmount,
        uint userCollateralPercentage,
        uint indexed amountMinted,
        uint timeStamp
    );

    struct Security {
        bool isPledgedBefore;                // resistance against override!
        uint pledgedAmount;                  // amount of asset that user deposited as collateral
        uint UAEDminted;                     // number of UAED minted for user
        uint pledgedTime;                    // time that user deposited collateral and minted UAED
    }

    function getSecurity(address _user, uint8 _assetId) public view returns (bool isPledgedBefore, uint pledgedAmount, uint mintedUAED, uint pledgedTime){
        Security storage security = pledgor[_user][_assetId];
        
        isPledgedBefore = security.isPledgedBefore;
        pledgedAmount = security.pledgedAmount;
        mintedUAED = security.UAEDminted;
        pledgedTime = security.pledgedTime;
    }

    mapping(address => mapping(uint8 => Security)) public pledgor; // pledgor[user][assetId] = Security

    function mintByETHcollateral(uint8 _percentage) public payable {
        require(msg.value > 0, "worng amount");
        require(_percentage < collateralFactor[2], "wrong percentage");
        require(!pledgor[msg.sender][2].isPledgedBefore, "Repetitious asset");

        _mintByCollateral(msg.sender, msg.value, 2, _percentage);
    }

    // user should approve to this contract before executing this function .
    // only for ECRC20 tokens
    function mintByCollateral(uint256 _amount, uint8 _assetId, uint8 _percentage) public {
        // _percentage has 2 decimals
        require(_amount > 0, "worng amount");
        require(_assetId != 0 && _assetId != 2 && _assetId != 6 && _assetId < tokenAddress.length, "wrong assetId");
        require(_percentage < collateralFactor[_assetId], "wrong percentage");
        require(!pledgor[msg.sender][_assetId].isPledgedBefore, "Repetitious asset");

        require(IERC20(tokenAddress[_assetId]).transferFrom(msg.sender, address(this), _amount ), "transfer collateral failed , check allowance!");
        _mintByCollateral(msg.sender, _amount, _assetId, _percentage);
    }

    function _mintByCollateral(address _user, uint256 _amount, uint8 _assetId, uint8 _percentage) private notPausedAsCollateral(_assetId) {
        uint256 mintAmountNumerator = _amount * getPriceInUSD(_assetId) * _percentage * 10**(tokenDecimals[6] + priceFeedDecimals[6]); // 6 is UAED assetId
        uint256 mintAmountDenominator = getPriceInUSD(6) * 10**(tokenDecimals[_assetId] + priceFeedDecimals[_assetId] + 2);  // +2 : _percentage decimals
        uint256 mintAmount = mintAmountNumerator / mintAmountDenominator;

        pledgor[_user][_assetId] = Security({
            isPledgedBefore: true,                  // resistance against override!
            pledgedAmount: _amount,                 // amount of asset that user deposited as collateral
            UAEDminted: mintAmount,                 // number of UAED minted for user
            pledgedTime: block.timestamp            // liquidation price in AED
        });

        _mint(_user, mintAmount);        
        emit mintedByCollateral( _user, _assetId, _amount, _percentage, mintAmount, block.timestamp);
    }


    /////////////////////////// helper functions for liquidation and debt payback ////////////////////////////
    // interest = (block.timestamp - mintedTime)/3600  *  (interestRatePerHour/10**8)   *   mintedAmount

    function getDebtState(address _user, uint8 _assetId) public returns (uint, uint, int){
        Security storage security = pledgor[_user][_assetId];

        require(_assetId < collateralFactor.length && collateralFactor[_assetId] != 0, "wrong assetId");
        require(security.isPledgedBefore, "unpledged user");
        uint mintedAmount = security.UAEDminted;
        uint mintedTime = security.pledgedTime;
        uint securityPledgedAmount = security.pledgedAmount;

        uint interest = ((block.timestamp - mintedTime) * interestRatePerHour * mintedAmount) / (3600 * 10**8);
        uint debtAmount = interest + mintedAmount;                            // debtAmount in UAED
        

        // indexed collateral value
        // N => Numerator & D => Denominator
        uint collateralValueN = securityPledgedAmount * getPriceInUSD(_assetId) * 10**(tokenDecimals[6] + priceFeedDecimals[6]);
        uint collateralValueD = getPriceInUSD(6) * 10**(tokenDecimals[_assetId] + priceFeedDecimals[_assetId]);         // +2 : collateralFactor decimals
        uint collateralValue = collateralValueN / collateralValueD;                                             // ICollateralValue in UAED
        uint IcollateralValue = collateralValue * collateralFactor[_assetId] / 1e2;

        // debtAmount / collateralValue = debtAmountInCollateral / securityPledgedAmount
        int surplusCollateral = int(securityPledgedAmount) - int(debtAmount * securityPledgedAmount / collateralValue);

        return (debtAmount, IcollateralValue, surplusCollateral);
    } 

    function sendCollateral(address _receiver, uint8 _assetId, uint _amount) private {
        if (_assetId == 2) {
            (bool sent, ) = payable(_receiver).call{ value: _amount }("");
            require(sent, "Failed to send Ether");
        } else {
            IERC20(tokenAddress[_assetId]).transfer(_receiver, _amount);
        }
    }  

    //////////////////////////////////// liquidate underbalanced user /////////////////////////////////////

    // A borrowing account becomes insolvent when the Borrow Ballance exceeds the amount allowed by the collateral factor.

    event userLiquidated(address indexed user, uint8 indexed assetId, uint debtAmount, uint timeStamp);

    function liquidate(address _user, uint8 _assetId) public {
        Security storage security = pledgor[_user][_assetId];

        (uint _debtAmount, uint _IcollateralValue, int _surplusCollateral) = getDebtState(_user, _assetId);
        require(_debtAmount > _IcollateralValue, "uninsolvent user");

        _burn(msg.sender, security.UAEDminted);
        _transfer(msg.sender, owner2, _debtAmount - security.UAEDminted);

        uint _pledgedAmount = security.pledgedAmount ;
        delete pledgor[_user][_assetId];

        if(_surplusCollateral > 0){
            uint ownerPortion = 25 * uint(_surplusCollateral) / 1e2 ;
            sendCollateral(owner2, _assetId, ownerPortion);
            sendCollateral(msg.sender, _assetId, _pledgedAmount - ownerPortion);
        }else{
            sendCollateral(msg.sender, _assetId, _pledgedAmount);
        }

        emit userLiquidated(_user, _assetId, _debtAmount, block.timestamp);
    }

    ////////////////////////////////////////////// pay debt ///////////////////////////////////////////////

    event debtPaid(address indexed user, uint8 indexed assetId, uint debtAmount, uint timeStamp);

    function payDebt(uint8 _assetId) public {
        require(pledgor[msg.sender][_assetId].isPledgedBefore, "No collateral provided");

        _payDebt(_assetId);
    }

    function _payDebt(uint8 _assetId) private {
        Security storage security = pledgor[msg.sender][_assetId];

        (uint _debtAmount, , ) = getDebtState(msg.sender, _assetId);

        _burn(msg.sender, security.UAEDminted);
        _transfer(msg.sender, owner2, _debtAmount - security.UAEDminted);

        uint _pledgedAmount = security.pledgedAmount ;
        delete pledgor[msg.sender][_assetId];

        sendCollateral(msg.sender, _assetId, _pledgedAmount);

        emit debtPaid(msg.sender, _assetId, _debtAmount, block.timestamp);
    }

    ////////////////////////////////////////////// mint & burn ///////////////////////////////////////////////

    function mint(address _user, uint256 _amount) public onlyOwner{
        _mint(_user, _amount);
        fiatBackedTotalSupply += _amount;
    }

    function burn(address _user, uint256 _amount) public onlyOwner{
        require(allowance(msg.sender, address(this)) >= _amount, "insufficiant allowance");
        _burn(_user, _amount);
        fiatBackedTotalSupply -= _amount;
    }

    ////////////////////////////////////////////// flashMint and flashLoan  ///////////////////////////////////////////////

    function flashMint(uint _amount) external {
        uint amountFee = calcFlashMintFee(_amount);
        _mint(msg.sender, _amount);
        require(IFlashLoanReceiver(msg.sender).executeOperation(amountFee),"flashMint failed");
        _transfer(msg.sender, owner2, amountFee);    
        _burn(msg.sender, _amount);
    }

    function calcFlashMintFee(uint _amount) public pure returns(uint){
        return 1e6;
    } 

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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