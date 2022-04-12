// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IERC20.sol";
import "./interface/IPancakeRouter.sol";
import "./interface/ITokenVesting.sol";


contract LockedTokenSaleV2 is Ownable {

    ITokenVesting public tokenVesting;
    IPancakeRouter01 public router;
    AggregatorInterface public ref;
    address public token;

    uint constant lock_period1 = 121;
    uint constant lock_period2 = 242;

    uint constant lock_period1_without_referrer = 182;
    uint constant lock_period2_without_referrer = 365;

    uint constant plan1_price_limit = 1.25 * 1e18; // ie18 1.25
    uint constant plan2_price_limit = 1 * 1e18; // ie18 1

    uint[] lockedTokenPrice;

    uint public referral_ratio = 30; //30 %

    uint public eth_collected;
    uint public eth_referral;

    struct AccountantInfo {
        address accountant;
        address withdrawal_address;
    }

    AccountantInfo[] accountantInfo;
    mapping(address => address) withdrawalAddress;

    uint min_withdrawal_amount;

    address[] referrers;
    mapping(uint => bool) referrer_status;
    mapping(address => uint) referrer_to_ids;

    event Buy_Locked_Tokens(address indexed account, uint plan, uint amount, uint referral_id);
    event Set_Accountant(AccountantInfo[] info);
    event Set_Min_Withdrawal_Amount(uint amount);
    event Set_Referral_Ratio(uint ratio);
    event Add_Referrers(address[] referrers);
    event Delete_Referrers(uint[] referrer_ids);

    modifier onlyAccountant() {
        address withdraw_address = withdrawalAddress[msg.sender];
        require(withdraw_address != address(0x0), "Only Accountant can perform this operation");
        _;
    }

    constructor(address _router, address _tokenVesting, address _ref, address _token) {
        router = IPancakeRouter01(_router); // 0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
        tokenVesting = ITokenVesting(_tokenVesting); // 0x63570e161Cb15Bb1A0a392c768D77096Bb6fF88C 0xDB83E3dDB0Fa0cA26e7D8730EE2EbBCB3438527E
        ref = AggregatorInterface(_ref); // 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526 bscTestnet
        token = _token; //0x5Ca372019D65f49cBe7cfaad0bAA451DF613ab96
        lockedTokenPrice.push(0);
        lockedTokenPrice.push(plan1_price_limit); // plan1
        lockedTokenPrice.push(plan2_price_limit); // plan2
        IERC20(_token).approve(_tokenVesting, 1e25);
        _add_referrer(address(this));
    }

    function balanceOfToken() public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getUnlockedTokenPrice() public view returns (uint) {
        address pair = IPancakeFactory(router.factory()).getPair(token, router.WETH());
        (uint112 reserve0, uint112 reserve1, ) = IPancakePair(pair).getReserves();
        uint pancake_price;
        if( IPancakePair(pair).token0() == token ){
            pancake_price = reserve1 * (10 ** IERC20(token).decimals()) / reserve0;
        }
        else {
            pancake_price = reserve0 * (10 ** IERC20(token).decimals()) / reserve1;
        }
        return pancake_price;
    }

    function setLockedTokenPrice(uint plan, uint price) public onlyOwner{
        if(plan == 1)
            require(plan1_price_limit <= price, "Price should not below the limit");
        if(plan == 2)
            require(plan2_price_limit <= price, "Price should not below the limit");
        lockedTokenPrice[plan] = price;
    }

    function getLockedTokenPrice(uint plan) public view returns (uint){
        return lockedTokenPrice[plan] * 1e8 / ref.latestAnswer();
    }

    function buyLockedTokens(uint plan, uint amount, uint referral_id) public payable{

        require(amount >= 100, "You should buy at least 100 locked token");
        bool is_valid_referrer = referral_id > 0 && referrer_status[referral_id] == true;
        address referrer = referrers[referral_id];

        uint price = getLockedTokenPrice(plan);
        
        uint amount_eth = amount * price;
        uint referral_value = amount_eth * referral_ratio / 100;

        require(amount_eth <= msg.value, 'Insufficient msg.value');
        if(is_valid_referrer && referrer != msg.sender) {
            payable(referrer).transfer(referral_value);
            eth_referral += referral_value;
        }
        
        require(amount <= IERC20(token).balanceOf(address(this)), "Insufficient token in the contract");
        uint256 lockdays;
        if(plan == 1)
        {    
            if(is_valid_referrer)
                lockdays = lock_period1;
            else
                lockdays = lock_period1_without_referrer;
        } else {
            if(is_valid_referrer)
                lockdays = lock_period2;
            else
                lockdays = lock_period2_without_referrer;
        }
        uint256 endEmission = block.timestamp + 1 days * lockdays;
        _lock_wjxn(msg.sender, amount, endEmission);

        if(amount_eth < msg.value) {
            payable(msg.sender).transfer(msg.value - amount_eth);
        }

        eth_collected += amount_eth;
    }

    function _lock_wjxn(address owner, uint amount, uint endEmission) internal {
        ITokenVesting.LockParams[] memory lockParams = new ITokenVesting.LockParams[](1);
        ITokenVesting.LockParams memory lockParam;
        lockParam.owner = payable(owner);
        lockParam.amount = amount;
        lockParam.startEmission = 0;
        lockParam.endEmission = endEmission;
        lockParam.condition = address(0);
        lockParams[0] = lockParam;
        tokenVesting.lock(token, lockParams);
    }

    function setReferralRatio(uint ratio) external onlyOwner {
        require(ratio >= 10 && ratio <= 50, "Referral ratio should be 10% ~ 50%");
        referral_ratio = ratio;
        emit Set_Referral_Ratio(ratio);
    }

    function setMinWithdrawalAmount(uint amount) external onlyOwner {
        min_withdrawal_amount = amount;
        emit Set_Min_Withdrawal_Amount(amount);
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyAccountant {
        require(amount >= min_withdrawal_amount, "Below minimum withdrawal amount");
        payable(withdrawalAddress[msg.sender]).transfer(amount);
    }

    function setAccountant(AccountantInfo[] calldata _accountantInfo) external onlyOwner {
        uint length = accountantInfo.length;
        for(uint i; i < length; i++) {
            withdrawalAddress[accountantInfo[i].accountant] = address(0x0);
        }
        delete accountantInfo;
        length = _accountantInfo.length;
        for(uint i; i < length; i++) {
            accountantInfo.push(_accountantInfo[i]);
            withdrawalAddress[_accountantInfo[i].accountant] = _accountantInfo[i].withdrawal_address;
        }
        emit Set_Accountant(_accountantInfo);
    }

    function add_referrers(address[] memory _referrers) external onlyOwner {
        uint i = 0;
        for(; i < _referrers.length; i += 1) {
            _add_referrer(_referrers[i]);
        }
        emit Add_Referrers(_referrers);
    }

    function delete_referrers(uint[] memory _referrer_ids) external onlyOwner {
        uint i = 0;
        for(; i < _referrer_ids.length; i += 1) {
            referrer_status[_referrer_ids[i]] = false;
        }
        emit Delete_Referrers(_referrer_ids);
    }

    function get_referrer_status(uint id) external view returns(bool) {
        require(id < referrers.length, "Invalid referrer id");
        return referrer_status[id];
    }

    function get_referrer(uint id) external view returns(address) {
        require(id < referrers.length, "Invalid referrer id");
        return referrers[id];
    }

    function get_referrers() external view returns(address[] memory) {
        return referrers;
    }

    function get_referrer_id(address referrer) external view returns(uint) {
        return referrer_to_ids[referrer];
    }

    function _add_referrer(address referrer) internal {
        uint referrer_id = referrer_to_ids[referrer];
        if( referrer_id == 0) {
            referrer_id = referrers.length;
            referrers.push(referrer);
            referrer_to_ids[referrer] = referrer_id;
        }
        referrer_status[referrer_id] = true;
    }
}

interface AggregatorInterface{
    function latestAnswer() external view returns (uint256);
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

pragma solidity 0.8.11;

/**
 * @dev Interface of the BEP standard.
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getOwner() external view returns (address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}


interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface ITokenVesting {

   struct LockParams {
        address payable owner; // the user who can withdraw tokens once the lock expires.
        uint256 amount; // amount of tokens to lock
        uint256 startEmission; // 0 if lock type 1, else a unix timestamp
        uint256 endEmission; // the unlock date as a unix timestamp (in seconds)
        address condition; // address(0) = no condition, otherwise the condition must implement IUnlockCondition
    }
  /**
   * @notice Creates one or multiple locks for the specified token
   * @param _token the erc20 token address
   * @param _lock_params an array of locks with format: [LockParams[owner, amount, startEmission, endEmission, condition]]
   * owner: user or contract who can withdraw the tokens
   * amount: must be >= 100 units
   * startEmission = 0 : LockType 1
   * startEmission != 0 : LockType 2 (linear scaling lock)
   * use address(0) for no premature unlocking condition
   * Fails if startEmission is not less than EndEmission
   * Fails is amount < 100
   */
  function lock (address _token, LockParams[] calldata _lock_params) external;
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