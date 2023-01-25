// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ISHNFT.sol";
import "./interfaces/ISHProduct.sol";
import "./interfaces/ISHFactory.sol";
import "./libraries/DataTypes.sol";
import "./SHProduct.sol";

/**
 * @notice Factory contract to create new products
 */
contract SHFactory is ISHFactory, OwnableUpgradeable {

    /// @notice Array of products' addresses
    address[] public products;
    /// @notice Mapping from product name to product address 
    mapping(string => address) public getProduct;
    /// @notice Boolean check if an address is a product
    mapping(address => bool) public isProduct;

    /// @notice Event emitted when new product is created
    event ProductCreated(
        address indexed product,
        string name, 
        string underlying,
        uint256 maxCapacity
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @notice Function to create new product(vault)
     * @param _name is the product name
     * @param _underlying is the underlying asset label
     * @param _currency principal asset, USDC address
     * @param _manager manager of the product
     * @param _qredoWallet is the wallet address of Qredo
     * @param _maxCapacity is the maximum USDC amount that this product can accept
     * @param _issuanceCycle is the struct variable with issuance date, 
        maturiy date, coupon, strike1 and strke2
     */
    function createProduct(
        string memory _name,
        string memory _underlying,
        IERC20Upgradeable _currency,
        address _manager,
        address _shNFT,
        address _qredoWallet,
        uint256 _maxCapacity,
        DataTypes.IssuanceCycle memory _issuanceCycle        
    ) external onlyOwner {
        require(getProduct[_name] == address(0) || ISHProduct(getProduct[_name]).paused() == true, 
            "Product already exists");

        require((_maxCapacity % 1000) == 0, "Max capacity must be whole-number thousands");

        // create new product contract
        SHProduct product = new SHProduct();
        product.initialize(
            _name, 
            _underlying, 
            _currency,
            _manager,
            _shNFT, 
            _qredoWallet, 
            _maxCapacity, 
            _issuanceCycle
        );
        address productAddr = address(product);

        getProduct[_name] = productAddr;
        isProduct[productAddr] = true;
        products.push(productAddr);
        // add NFT minter role
        ISHNFT(_shNFT).addMinter(productAddr);
        
        emit ProductCreated(productAddr, _name, _underlying, _maxCapacity);
    }

    /**
     * @notice returns the number of products
     */
    function numOfProducts() external view returns (uint256) {
        return products.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/ISHProduct.sol";
import "./interfaces/ISHNFT.sol";
import "./interfaces/clearpool/IPoolMaster.sol";
import "./interfaces/compound/ICErc20.sol";
import "./libraries/DataTypes.sol";
import "./libraries/Array.sol";

contract SHProduct is ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Array for address[];

    struct UserInfo {
        uint256 coupon;
        uint256 optionPayout;
    }

    /// @notice Enum representing product status
    enum Status {
        Pending,
        Accepted,
        Locked,
        Issued,
        Mature
    }

    string public name;
    string public underlying;

    address public manager;
    address public shNFT;
    address public qredoWallet;

    uint256 public maxCapacity;
    uint256 public currentCapacity;
    uint256 public optionProfit;
    
    uint256 public currentTokenId;
    uint256 public prevTokenId;

    Status public status;
    DataTypes.IssuanceCycle public issuanceCycle;
    
    mapping(address => UserInfo) public userInfo;

    IERC20Upgradeable public currency;
    bool public isDistributed;

    /// @notice restricting access to the gelato automation functions
    mapping(address => bool) public whitelisted;
    address public dedicatedMsgSender;
    
    event Deposit(
        address indexed _from,
        uint256 _amount,
        uint256 _currentTokenId,
        uint256 _supply
    );

    event WithdrawPrincipal(
        address indexed _to,
        uint256 _amount,
        uint256 _prevTokenId,
        uint256 _prevSupply,
        uint256 _currentTokenId,
        uint256 _currentSupply
    );

    event WithdrawCoupon(
        address indexed _to,
        uint256 _amount
    );

    event WithdrawOption(
        address indexed _to,
        uint256 _amount
    );

    event RedeemOptionPayout(
        address indexed _from,
        uint256 _amount
    );

    event DistributeWithClear(
        address indexed _qredoDeribit,
        uint256 _optionRate,
        address[] _clearpools,
        uint256[] _yieldRates
    );

    event DistributeWithComp(
        address indexed _qredoDeribit,
        uint256 _optionRate,
        address indexed _cErc20Pool,
        uint256 _yieldRate
    );

    event RedeemYieldFromClear(
        address[] _clearpools
    );
    
    event RedeemYieldFromComp(
        address _cErc20Pool
    );

    /// @notice Event emitted when new issuance cycle is set
    event IssuanceCycleSet(
        uint256 coupon,
        uint256 strikePrice1,
        uint256 strikePrice2,
        uint256 strikePrice3,
        uint256 strikePrice4,
        string uri
    );

    event FundAccept(
        uint256 _optionProfit,
        uint256 _prevTokenId,
        uint256 _currentTokenId,
        uint256 _numOfNftHolders,
        uint256 _timestamp
    );

    event FundLock(
        uint256 _timestamp
    );

    event Issuance(
        uint256 _numOfNftHolders,
        uint256 _timestamp
    );

    event Mature(
        uint256 _timestamp
    );
    
    event WeeklyCoupon(
        uint256 _coupon,
        uint256 _numOfNftHolders,
        uint256 _timestamp
    );

    function initialize(
        string memory _name,
        string memory _underlying,
        IERC20Upgradeable _currency,
        address _manager,
        address _shNFT,
        address _qredoWallet,
        uint256 _maxCapacity,
        DataTypes.IssuanceCycle memory _issuanceCycle
    ) public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();

        name = _name;
        underlying = _underlying;

        manager = _manager;
        qredoWallet = _qredoWallet;
        maxCapacity = _maxCapacity;

        currency = _currency;
        shNFT = _shNFT;
        issuanceCycle = _issuanceCycle;

        _setIssuanceCycle(_issuanceCycle);
    }
    
    modifier onlyWhitelisted() {
        require(
            whitelisted[msg.sender] || msg.sender == dedicatedMsgSender,
            "Only whitelisted"
        );
        _;
    }

    /// @notice Modifier for functions restricted to manager
    modifier onlyManager() {
        require(msg.sender == manager, "Not a manager");
        _;
    }

    modifier onlyAccepted() {
        require(status == Status.Accepted, "Not accepted status");
        _;
    }

    modifier onlyIssued() {
        require(status == Status.Issued, "Not issued status");
        _;
    }

    modifier onlyMature() {
        require(status == Status.Mature, "Not mature status");
        _;
    }

    /**
     * @notice Sets dedicated msg.sender to restrict access to the functions that Gelato will call
     */
    function setDedicatedMsgSender(address _sender) external onlyManager {
        dedicatedMsgSender = _sender;
    }

    /**
     * @notice Whitelists the additional callers for the functions that Gelato will call
     */
    function whitelist(address _account) external onlyManager {
        whitelisted[_account] = true;
    }

    function fundAccept() external whenNotPaused onlyWhitelisted {
        // First, distribute option profit to the token holders.
        uint256 totalSupply = ISHNFT(shNFT).totalSupply(currentTokenId);
        address[] memory totalHolders = ISHNFT(shNFT).accountsByToken(currentTokenId);
        if (optionProfit > 0) {
            for (uint256 i = 0; i < totalHolders.length; i++) {
                uint256 tokenSupply = ISHNFT(shNFT).balanceOf(totalHolders[i], currentTokenId);
                userInfo[totalHolders[i]].optionPayout += tokenSupply * optionProfit / totalSupply;
            }
        }
        // Then update status
        status = Status.Accepted;
        prevTokenId = currentTokenId;

        ISHNFT(shNFT).tokenIdIncrement();
        currentTokenId = ISHNFT(shNFT).currentTokenID();

        emit FundAccept(
            optionProfit, 
            prevTokenId, 
            currentTokenId, 
            totalHolders.length, 
            block.timestamp
        );
    }

    function fundLock() external whenNotPaused onlyWhitelisted {
        status = Status.Locked;

        emit FundLock(block.timestamp);
    }

    function issuance() external whenNotPaused onlyWhitelisted {
        require(status == Status.Locked, "Fund is not locked");
        status = Status.Issued;
        // issuanceCycle.issuanceDate = block.timestamp;
        // burn the token of the last cycle
        address[] memory totalHolders = ISHNFT(shNFT).accountsByToken(currentTokenId);
        for (uint256 i = 0; i < totalHolders.length; i++) {
            uint256 prevSupply = ISHNFT(shNFT).balanceOf(totalHolders[i], prevTokenId);
            if (prevSupply > 0) {
                ISHNFT(shNFT).burn(totalHolders[i], prevTokenId, prevSupply);
                ISHNFT(shNFT).mint(totalHolders[i], currentTokenId, prevSupply, issuanceCycle.uri);
            }
        }

        emit Issuance(totalHolders.length, block.timestamp);
    }

    function mature() external whenNotPaused onlyIssued onlyWhitelisted {
        status = Status.Mature;
        // issuanceCycle.maturityDate = block.timestamp;
        emit Mature(block.timestamp);
    }

    /**
     * @dev Update users' coupon balance every week
     */
    function weeklyCoupon() external whenNotPaused onlyIssued onlyWhitelisted {
        address[] memory totalHolders = ISHNFT(shNFT).accountsByToken(currentTokenId);
        for (uint256 i = 0; i < totalHolders.length; i++) {
            uint256 tokenSupply = ISHNFT(shNFT).balanceOf(totalHolders[i], currentTokenId);
            if (tokenSupply > 0) {
                userInfo[totalHolders[i]].coupon += _convertTokenToCurrency(tokenSupply) * issuanceCycle.coupon / 10000;
            }
        }

        emit WeeklyCoupon(issuanceCycle.coupon, totalHolders.length, block.timestamp);
    }

    /**
     * @dev Set new issuance cycle, called by only manager
     */
    function setIssuanceCycle(
        DataTypes.IssuanceCycle memory _issuanceCycle
    ) external onlyManager {
        require(status != Status.Issued, "Already issued status");
        _setIssuanceCycle(_issuanceCycle);
    }
    
    function _setIssuanceCycle(
        DataTypes.IssuanceCycle memory _issuanceCycle
    ) internal {
        issuanceCycle = _issuanceCycle;

        emit IssuanceCycleSet(
            _issuanceCycle.coupon, 
            _issuanceCycle.strikePrice1, 
            _issuanceCycle.strikePrice2,
            _issuanceCycle.strikePrice3,
            _issuanceCycle.strikePrice4,
            _issuanceCycle.uri
        );
    }

    /**
     * @dev Deposits the USDC into the structured product and mint ERC1155 NFT
     * @param _amount is the amount of USDC to deposit
     * @param _type True: include profit, False: without profit
     */
    function deposit(uint256 _amount, bool _type) external whenNotPaused nonReentrant onlyAccepted {
        require(_amount > 0, "Amount must be greater than zero");
        
        uint256 amountToDeposit = _amount;
        if (_type == true) {
            amountToDeposit += userInfo[msg.sender].coupon + userInfo[msg.sender].optionPayout;
        }

        uint256 decimals = _currencyDecimals();
        require((amountToDeposit % (1000 * 10 ** decimals)) == 0, "Amount must be whole-number thousands");
        require((maxCapacity * 10 ** decimals) >= (currentCapacity + amountToDeposit), "Product is full");

        uint256 supply = amountToDeposit / (1000 * 10 ** decimals);

        currency.safeTransferFrom(msg.sender, address(this), _amount);
        ISHNFT(shNFT).mint(msg.sender, currentTokenId, supply, issuanceCycle.uri);

        currentCapacity += amountToDeposit;
        if (_type == true) {
            userInfo[msg.sender].coupon = 0;
            userInfo[msg.sender].optionPayout = 0;
        }

        emit Deposit(msg.sender, _amount, currentTokenId, supply);
    }

    /**
     * @dev Withdraws the principal from the structured product
     */
    function withdrawPrincipal() external nonReentrant onlyAccepted {
        uint256 prevSupply = ISHNFT(shNFT).balanceOf(msg.sender, prevTokenId);
        uint256 currentSupply = ISHNFT(shNFT).balanceOf(msg.sender, currentTokenId);
        uint256 totalSupply = prevSupply + currentSupply;

        require(totalSupply > 0, "No principal");
        uint256 principal = _convertTokenToCurrency(totalSupply);
        require(totalBalance() >= principal, "Insufficient balance");
        
        currency.safeTransfer(msg.sender, principal);
        ISHNFT(shNFT).burn(msg.sender, prevTokenId, prevSupply);
        ISHNFT(shNFT).burn(msg.sender, currentTokenId, currentSupply);

        currentCapacity -= principal;

        emit WithdrawPrincipal(
            msg.sender, 
            principal, 
            prevTokenId, 
            prevSupply, 
            currentTokenId, 
            currentSupply
        );
    }

    /**
     * @notice Withdraws user's coupon payout
     */
    function withdrawCoupon() external nonReentrant {
        require(userInfo[msg.sender].coupon > 0, "No coupon payout");
        require(totalBalance() >= userInfo[msg.sender].coupon, "Insufficient balance");
        
        currency.safeTransfer(msg.sender, userInfo[msg.sender].coupon);
        userInfo[msg.sender].coupon = 0;

        emit WithdrawCoupon(msg.sender, userInfo[msg.sender].coupon);
    }

    /**
     * @notice Withdraws user's option payout
     */
    function withdrawOption() external nonReentrant {
        require(userInfo[msg.sender].optionPayout > 0, "No option payout");
        require(totalBalance() >= userInfo[msg.sender].optionPayout, "Insufficient balance");
        
        currency.safeTransfer(msg.sender, userInfo[msg.sender].optionPayout);
        userInfo[msg.sender].optionPayout = 0;

        emit WithdrawOption(msg.sender, userInfo[msg.sender].optionPayout);
    }

    function distributeWithComp(
        uint256 _yieldRate,
        address _cErc20Pool
    ) external onlyManager onlyIssued {
        require(!isDistributed, "Already distributed");
        require(_yieldRate <= 100, "Yield rate should be equal or less than 100");
        uint256 optionRate = 100 - _yieldRate;

        uint256 optionAmount;
        if (optionRate > 0) {
            optionAmount = currentCapacity * optionRate / 100;
            currency.transfer(qredoWallet, optionAmount);
        }

        // Lend into the compound cUSDC pool
        uint256 yieldAmount = currentCapacity * _yieldRate / 100;
        currency.approve(_cErc20Pool, yieldAmount);
        ICErc20(_cErc20Pool).mint(yieldAmount);
        isDistributed = true;
        
        emit DistributeWithComp(qredoWallet, optionRate, _cErc20Pool, _yieldRate);
    }

    function redeemYieldFromComp(
        address _cErc20Pool
    ) external onlyManager onlyMature {
        require(isDistributed, "Not distributed");
        uint256 cTokenAmount = ICErc20(_cErc20Pool).balanceOf(address(this));
        // Retrieve your asset based on a cToken amount
        ICErc20(_cErc20Pool).redeem(cTokenAmount);
        isDistributed = false;

        emit RedeemYieldFromComp(_cErc20Pool);
    }

    /**
     * @notice After the fund is locked, distribute USDC into the Qredo wallet and
     * the lending pools to generate passive income
     */
    function distributeWithClear(
        uint256[] calldata _yieldRates, 
        address[] calldata _clearpools
    ) external onlyManager onlyIssued {
        require(!isDistributed, "Already distributed");
        require(_yieldRates.length == _clearpools.length, "Should have the same length");
        uint256 totalYieldRate = 0;
        for (uint256 i = 0; i < _yieldRates.length; i++) {
            totalYieldRate += _yieldRates[i];
        }
        require(totalYieldRate <= 100, "Total yield rate should be equal or less than 100");
        
        uint256 optionRate = 100 - totalYieldRate;
        // Transfer option amount to the Qredo wallet
        if (optionRate > 0) {
            uint256 optionAmount = currentCapacity * optionRate / 100;
            currency.transfer(qredoWallet, optionAmount);
        }

        // Lend into the clearpool
        for (uint256 i = 0; i < _clearpools.length; i++) {
            if (_yieldRates[i] > 0) {
                uint256 yieldAmount = currentCapacity * _yieldRates[i] / 100;
                currency.approve(_clearpools[i], yieldAmount);
                IPoolMaster(_clearpools[i]).provide(yieldAmount);
            }
        }
        isDistributed = true;
        emit DistributeWithClear(qredoWallet, optionRate, _clearpools, _yieldRates);
    }

    function redeemYieldFromClear(
        address[] calldata _clearpools
    ) external onlyManager onlyMature {
        require(isDistributed, "Not distributed");
        require(_clearpools.length > 0, "No yield source");
        for (uint256 i = 0; i < _clearpools.length; i++) {
            uint256 cpTokenBal = IPoolMaster(_clearpools[i]).balanceOf(address(this));
            IPoolMaster(_clearpools[i]).redeem(cpTokenBal);
        }
        isDistributed = false;
        
        emit RedeemYieldFromClear(_clearpools);
    }


    /**
     * @dev Transfers option profit from a qredo wallet, called by an owner
     */
    function redeemOptionPayout(uint256 _optionProfit) external onlyMature {
        require(msg.sender == qredoWallet, "Not a qredo wallet");
        currency.safeTransferFrom(msg.sender, address(this), _optionProfit);
        optionProfit = _optionProfit;

        emit RedeemOptionPayout(msg.sender, _optionProfit);
    }

    /**
     * @notice Returns the user's principal balance
     * Before auto-rolling or fund lock, users can have both tokens so total supply is the sum of 
     * previous supply and current supply
     */
    function principalBalance(address _user) public view returns (uint256) {
        uint256 prevSupply = ISHNFT(shNFT).balanceOf(_user, prevTokenId);
        uint256 tokenSupply = ISHNFT(shNFT).balanceOf(_user, currentTokenId);
        return _convertTokenToCurrency(prevSupply + tokenSupply);
    }

    /**
     * @notice Returns the user's coupon payout
     */
    function couponBalance(address _user) external view returns (uint256) {
        return userInfo[_user].coupon;
    }

    /**
     * @notice Returns the user's option payout
     */
    function optionBalance(address _user) external view returns (uint256) {
        return userInfo[_user].optionPayout;
    }

    /**
     * @notice Returns the product's total USDC balance
     */
    function totalBalance() public view returns (uint256) {
        return currency.balanceOf(address(this));
    }

    /**
     * @notice Returns the decimal of underlying asset (USDC)
     */
    function _currencyDecimals() internal view returns (uint256) {
        return IERC20MetadataUpgradeable(address(currency)).decimals();
    }

    /**
     * @notice Calculates the currency amount based on token supply
     */
    function _convertTokenToCurrency(uint256 _tokenSupply) internal view returns (uint256) {
        return _tokenSupply * 1000 * (10 ** _currencyDecimals());
    }

    /**
     * @dev Pause the product
     */
    function pause() external onlyManager {
        _pause();
    }

    /**
     * @dev Unpause the product
     */
    function unpause() external onlyManager {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISHProduct {
    function maxCapacity() external view returns (uint256);

    function shNFT() external view returns (address);

    function deposit(uint256 _amount) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../libraries/DataTypes.sol";

interface ISHFactory {
    function createProduct(
        string memory _name,
        string memory _underlying,
        IERC20Upgradeable _currency,
        address _manager,
        address _shNFT,
        address _qredo_deribit,
        uint256 _maxCapacity,
        DataTypes.IssuanceCycle memory _issuanceCycle        
    ) external;
    
    function numOfProducts() external view returns (uint256);

    function isProduct(address _product) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library DataTypes {
    /// @notice Struct representing issuance cycle
    struct IssuanceCycle {
        uint256 coupon;
        uint256 strikePrice1;
        uint256 strikePrice2;
        uint256 strikePrice3;
        uint256 strikePrice4;
        string uri;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISHNFT {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address _account, uint256 _id) external view returns (uint256);

    function mint(address _to, uint256 _id, uint256 _amount, string calldata _uri) external;

    function burn(address _from, uint256 _id, uint256 _amount) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function currentTokenID() external view returns (uint256);

    function tokenIdIncrement() external;

    function totalSupply(uint256 _id) external view returns (uint256);

    function addMinter(address _account) external;

    function setTokenURI(uint256 _id, string calldata _uri) external;

    function accountsByToken(uint256 _id) external view returns (address[] memory);

    function tokensByAccount(address _account) external view returns (uint256[] memory);

    function totalHolders(uint256 _id) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.9;

library Array {
    function remove(address[] storage arr, uint256 index) internal {
        // Move the last element into the place to delete
        require(arr.length > 0, "Can't remove from empty array");
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoolMaster {
    
    enum State {
        Active,
        Warning,
        ProvisionalDefault,
        Default,
        Closed
    }
    
    /// @notice Function is used to provide liquidity for Pool in exchange for cpTokens
    /// @dev Approval for desired amount of currency token should be given in prior
    /// @param currencyAmount Amount of currency token that user want to provide
    function provide(uint256 currencyAmount) external;

    /// @notice Function is used to provide liquidity in exchange for cpTokens to the given address
    /// @dev Approval for desired amount of currency token should be given in prior
    /// @param currencyAmount Amount of currency token that user want to provide
    /// @param receiver Receiver of cpTokens
    function provideFor(uint256 currencyAmount, address receiver) external;

    /// @notice Function is used to redeem previously provided liquidity with interest, burning cpTokens
    /// @param tokens Amount of cpTokens to burn (MaxUint256 to burn maximal possible)
    function redeem(uint256 tokens) external;

    /// @notice Function is used to redeem previously provided liquidity with interest, burning cpTokens
    /// @param currencyAmount Amount of currency to redeem (MaxUint256 to redeem maximal possible)
    function redeemCurrency(uint256 currencyAmount) external;

    function manager() external view returns (address);

    function currency() external view returns (address);

    function borrows() external view returns (uint256);

    function reserves() external view returns (uint256);

    function getBorrowRate() external view returns (uint256);

    function getSupplyRate() external view returns (uint256);

    function poolSize() external view returns (uint256);

    function cash() external view returns (uint256);

    function interest() external view returns (uint256);

    function principal() external view returns (uint256);

    function state() external view returns (State);

    function withdrawReward(address account) external returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function balanceOf(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}