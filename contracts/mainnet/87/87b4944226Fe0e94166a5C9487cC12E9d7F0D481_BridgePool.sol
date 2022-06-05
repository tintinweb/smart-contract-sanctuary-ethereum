// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/Icontroller.sol";
import "./interface/IERC20deployer.sol";



contract BridgePool is Context , ReentrancyGuard {
  
    struct  pool{
        address wrappedAsset;
        uint256 deposited;
        uint256 debt;
        uint256 overFlow;
        uint256 debtThreshold;
        bool isSet;
        
    }
    IController public controller;
    address public bridge;
    address public pendingBridge;
    uint256 public bridgeUpdateInnitiatedAt;
    mapping(address => pool) public pools;
    address[] public poolAddresses;
    uint256 public poolCount;
    uint256 public bridgeUpdateDelay = 2 days;
    
    event PoolToppedUp(address indexed poolAddress,uint256 amount);
    event AssetSentOut(address indexed  poolAddress, address indexed  reciever ,uint256 amount);
    event AssetWithdrawn(address indexed poolAddress , address indexed receiver,uint256  amount);
    event AssetDeposited(address indexed poolAddress , uint256  amount);
    event PoolCreated(address indexed poolAddress, address indexed wrappedAsset); 
    event NewBridgeInnitiated(address indexed curentBridge ,address indexed pendingBridge);
    event NewBridgeActivated(address indexed prevBridge , address indexed newBridge);
    event PoolDebtThresholdUpdated(
        address indexed poolAddress,
        uint256 oldDebtThreshold,
        uint256 newDebtThreshold
    );
    bool initialized;
     modifier onlyBridge() {
         require(bridge == _msgSender(), "Only Bridge Callable");
        _; 
     }
     modifier poolInitialized() {
         require(initialized, "pool not initialized");
        _; 
     }
    
    
    constructor(IController _controller ) {
        require(address(_controller) != address(0), "Zero address Err");
        controller = _controller;
    }
    
    function initializePool(address _bridge) public {
        isOwner();
        require(_bridge != address(0) && !initialized , "Er");
        bridge = _bridge;
        initialized = true;

    }

    function innitiateBridgeUpdate(address newBridge) public poolInitialized{
        isOwner();
        require(pendingBridge == address(0) , "pending Bridge already innitiated");
        pendingBridge = newBridge;
        emit NewBridgeInnitiated(bridge , pendingBridge);
        bridgeUpdateInnitiatedAt = block.timestamp;
    }
    function suspendBridgeUpdate() public poolInitialized{
        isOwner();
        require(pendingBridge != address(0) , "new bridge not innitiated");
        pendingBridge = address(0);
    }
    function activateNewBridge() public  poolInitialized{
        isOwner();
        require(pendingBridge != address(0) , "new bridge not innitiated");
        require(block.timestamp - bridgeUpdateInnitiatedAt > bridgeUpdateDelay , "update delay active");
        emit NewBridgeActivated(bridge , pendingBridge);
        bridge = pendingBridge;
        pendingBridge = address(0);
    }


    function updatePoolDebtThreshold(address poolAddress , uint256 debtThreshold) public poolInitialized{
        isOwner();
        require(pools[poolAddress].isSet , "invalid Pool");
        require(debtThreshold > 0 , "cant be zero");
        emit PoolDebtThresholdUpdated(poolAddress ,pools[poolAddress].debtThreshold , debtThreshold);
        pools[poolAddress].debtThreshold = debtThreshold;
     
    }
     

    function createPool(
        address poolAddress,
        uint256 debtThreshold
    ) 
        public
        onlyBridge
        poolInitialized
    {
        require(!pools[poolAddress].isSet , "pool already Created");
        require(debtThreshold > 0 , "cant be zero");
        WrappedToken wrappedAsset;
        if(poolAddress == address(0)){
             wrappedAsset =    new WrappedToken("brEtherium" , "brEth");
        }else{
            IERC20Metadata token = IERC20Metadata(poolAddress);
            wrappedAsset =    new WrappedToken(string(abi.encodePacked( "br", token.name())) , string(abi.encodePacked("br" , token.symbol())));
        }
        
        pools[poolAddress] = pool(address(wrappedAsset), 0 , 0 , 0, debtThreshold , true);
        poolAddresses.push(poolAddress);
        poolCount++;
        emit PoolCreated(poolAddress , address(wrappedAsset));       
    }
    

    function deposit(address poolAddress, uint256 amount) public payable nonReentrant poolInitialized{
        require(pools[poolAddress].isSet , "invalid Pool");
         (bool success , uint256 amountRecieved) = processedPayment(poolAddress , amount);
         require(success && amountRecieved > 0, "I_F");
         pools[poolAddress].deposited += amountRecieved;
         IwrappedToken(pools[poolAddress].wrappedAsset).mint(msg.sender , amountRecieved);
         emit AssetDeposited(poolAddress , amountRecieved);
        
    }

    function withdraw(address poolAddress , uint256 amount) public nonReentrant poolInitialized{ 

         require(pools[poolAddress].isSet , "invalid Pool");  
         IERC20 token = IERC20(poolAddress);
         IERC20 wrappedToken = IERC20(pools[poolAddress].wrappedAsset);
      
         require(pools[poolAddress].deposited  >= amount && token.balanceOf(address(this)) >= amount , "Insufficent Pool Balance");
         require(wrappedToken.allowance(_msgSender(), address(this)) >= amount , "I_F");
         uint256 balanceBefore = IERC20(pools[poolAddress].wrappedAsset).balanceOf(address(this));
         wrappedToken.transferFrom(_msgSender() , address(this) , amount);
         uint256 balanceAfter = wrappedToken.balanceOf(address(this));
         require(balanceAfter - balanceBefore > 0 , "I_F");
         uint256 amountRecieved = balanceAfter - balanceBefore;
         IwrappedToken(pools[poolAddress].wrappedAsset).burn(amountRecieved);
         payoutUser(payable(_msgSender()) , poolAddress , amountRecieved);
         pools[poolAddress].deposited -= amountRecieved;
         emit AssetWithdrawn(poolAddress , _msgSender() , amountRecieved);

    }


    function sendOut(address poolAddress , address receiver , uint256 amount) public onlyBridge poolInitialized{
        require(receiver != address(0) , "Z_A_E");
       require(pools[poolAddress].isSet , "invalid Pool");
        IERC20 token = IERC20(poolAddress);
        require( pools[poolAddress].overFlow + pools[poolAddress].deposited >= amount && token.balanceOf(address(this)) >= amount , "Insufficent Pool Balance");
        if (pools[poolAddress].overFlow > 0) {
            if (pools[poolAddress].overFlow >= amount){
                pools[poolAddress].overFlow -= amount;
            } else {
                uint256 _debt = amount - pools[poolAddress].overFlow;
                 pools[poolAddress].debt +=  _debt;
                 pools[poolAddress].overFlow = 0;
            }
        } else {
           pools[poolAddress].debt +=  amount;
        }
        require(pools[poolAddress].debt < pools[poolAddress].debtThreshold , "Dept Threshold Exceeded");
        payoutUser(payable(receiver) , poolAddress , amount);
        emit AssetSentOut(poolAddress , receiver , amount);

    }


    function topUp(address poolAddress, uint256 amount) public onlyBridge poolInitialized{
        
        (bool success , uint256 amountRecieved) = processedPayment(poolAddress , amount);
        require(pools[poolAddress].isSet  && success, "invalid Pool");
        if (pools[poolAddress].debt > 0) {
            if (pools[poolAddress].debt >= amountRecieved){
                pools[poolAddress].debt -= amountRecieved;
            } else {
                uint256 _overFlow = amountRecieved - pools[poolAddress].debt;
                 pools[poolAddress].overFlow +=  _overFlow;
                 pools[poolAddress].debt = 0;
            }
        } else {
           pools[poolAddress].overFlow +=  amountRecieved;
        }
        
        emit PoolToppedUp( poolAddress, amountRecieved);

    }
     function processedPayment(address assetAddress , uint256 amount) internal   returns (bool , uint256) {
        if (assetAddress == address(0)) {
            if(msg.value >= amount ){
                uint256 value = msg.value;
                return (true , value);
            } else {
                return (false , 0);
            }
            
        } else {
            IERC20 token = IERC20(assetAddress);
            if (token.allowance(_msgSender(), address(this)) >= amount) {
                uint256 balanceBefore = token.balanceOf(address(this));
                require(token.transferFrom(_msgSender() , address(this) , amount), "I_F");
                uint256 balanceAfter = token.balanceOf(address(this));
               return (true , balanceAfter - balanceBefore);
            } else {
                return (false , 0);
            }
        }
    }

    function payoutUser(address payable recipient , address _paymentMethod , uint256 amount) private {
       require(recipient  != address(0) , "Z_A_E");
        if (_paymentMethod == address(0)) {
          recipient.transfer(amount);
        } else {
             IERC20 currentPaymentMethod = IERC20(_paymentMethod);
             require(currentPaymentMethod.transfer(recipient , amount) ,"I_F");
        }
    }


    function validPool(address poolAddress) public view returns (bool) {
        return pools[poolAddress].isSet;
    }
    function isOwner() internal view returns (bool) {
        require(controller.owner() == _msgSender()  , "U_A");
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IController {

    function isAdmin(address account) external view returns (bool);


    function isRegistrar(address account) external view returns (bool);


    function isOracle(address account) external view returns (bool);


    function isValidator(address account) external view returns (bool);


    function owner() external view returns (address);

    
    function validatorsCount() external view returns (uint256);

    function settings() external view returns (address);


    function deployer() external view returns (address);


    function feeController() external view returns (address);

    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


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



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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


interface IwrappedToken {
    
     function burn(uint256 amount) external ;
     function mint(address account , uint256 amount) external ;
}
contract WrappedToken is ERC20 ,Ownable {
    constructor (string memory _name ,  string memory _symbol)  ERC20(_name , _symbol){
        
    } 
    function burn(uint256 amount) public   onlyOwner {
        _burn(_msgSender(), amount);
    }
    function mint(address account, uint256 amount) public  onlyOwner{
     _mint( account,  amount) ;   
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