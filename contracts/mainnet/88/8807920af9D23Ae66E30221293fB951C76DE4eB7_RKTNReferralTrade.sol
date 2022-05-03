/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

pragma solidity =0.8.10 >=0.8.10 >=0.8.0 <0.9.0;


/* pragma solidity ^0.8.0; */

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
 //loser from amacdaddddy
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

////// src/IUniswapV2Factory.sol
/* pragma solidity 0.8.10; */
/* pragma experimental ABIEncoderV2; */

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

////// src/IUniswapV2Pair.sol
/* pragma solidity 0.8.10; */
/* pragma experimental ABIEncoderV2; */

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

////// src/IUniswapV2Router02.sol
/* pragma solidity 0.8.10; */
/* pragma experimental ABIEncoderV2; */

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

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


contract RKTNReferralTrade is  Ownable {
    using SafeMath for uint256;

    //Uniswap pair
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    //AMM Pair
    mapping(address => bool) public automatedMarketMakerPairs;

    //Store Parent Referrer
    mapping(address => address) public referralMapping;

    //referral amount mapping 
    mapping(address => uint256) public referralAmountMapping;

    mapping(address => uint256) public referralEthEarnedMapping;
  

    //Token Address
    address public tokenAddress;

    //Dev Wallet
    address public devWallet;

    //CommunityWallet
    address public communityWallet;

    //enabled
    bool public referralProgramEnabled = true;
    bool public referralSellRewardEnabled = false;
    bool public holderBuyRewardEnabled = false;

    //Sell referral benefit threashhold
    uint256 public referralRewardThreshold = 5;


    //referral fees
    uint256 buyReferrerFee = 3;
    uint256 buyReferrerParentFee = 1;

    //sell Base discount fee
    uint256 sellBaseFee = 8;

    //Holder buy fee
    uint256 buyFeeHolder = 2;

    //event update AMM
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    
    //event update Dev Address
    event devWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    //event update Community Address
    event communityWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );


    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);


    constructor(){
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        tokenAddress = address(0x5CA5a5Efb57dBaF4462eDBD15dA889448b1919ED);

        devWallet = address(0x30469c313972662f7E7Ac1fa49b0e4AD88786F15);

        communityWallet = address(0xE0C7094a6EE7031bA4E43cc510d39c39996ED0dE);

        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        
        _setAutomatedMarketMakerPair(address(0xbe2EC6836A26aA95b2FcB310DBC229B58A23A948), true);


        }

    receive() external payable {}

    //change AMM pair
    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    //set AMM private function
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    //enable or disable referral program buy function
    function updatereferralProgramEnabled(bool enabled) external onlyOwner {
        referralProgramEnabled = enabled;
    }

    //enable or disable referral program sell function
    function updateReferralSellRewardEnabled(bool enabled) external onlyOwner {
        referralSellRewardEnabled = enabled;
    }

    //enable or disable Holder program buy function
    function updateHolderBuyBenefitEnabled(bool enabled) external onlyOwner {
        holderBuyRewardEnabled = enabled;
    }

    //update Dev Address
    function updateDevWallet(address newDevWallet)
        external
        onlyOwner
    {
        emit devWalletUpdated(newDevWallet, devWallet);
        devWallet = newDevWallet;
    }

    //update community Wallet
     function updateCommunityWallet(address newCommunityallet)
        external
        onlyOwner
    {
        emit devWalletUpdated(newCommunityallet, communityWallet);
        communityWallet = newCommunityallet;
    }

    //Buy RKTN referral Function
    function BuyRKTNReferral(address referrer) payable public {
        require(msg.value > 0, "Must send ETH to purchase");
        require(referralProgramEnabled, "referrals disabled");

        address referrerParent = referralMapping[referrer];

        if(referrerParent == address(0)){
            referrerParent = devWallet;
            referralMapping[msg.sender] = referrer;
        }
         
         uint256 amount = msg.value;
         uint256 totalFee = 0;
         uint256 fees = 0;
         uint256 referralAmountEth = 0;
         uint256 referralParentEth = 0;
         bool success;

         uint256 InitialcontractBalance = IERC20(tokenAddress).balanceOf(address(this));

         totalFee = buyReferrerFee + buyReferrerParentFee;

         fees = amount.mul(totalFee).div(100);
         referralAmountEth = (fees * buyReferrerFee) / fees;
         referralParentEth = (fees * buyReferrerParentFee) / fees;

         amount -= fees;

        swapEthForTokens(amount);

        uint256 rktnBalance = IERC20(tokenAddress).balanceOf(address(this)).sub(InitialcontractBalance);

        IERC20(tokenAddress).approve(address(this), rktnBalance);

        IERC20(tokenAddress).transferFrom(address(this), msg.sender, rktnBalance);

        (success, ) = address(referrer).call{value: referralAmountEth}("");

        (success, ) = address(referrerParent).call{value: referralParentEth}("");

        referralEthEarnedMapping[referrer] += referralAmountEth;
        referralEthEarnedMapping[referrerParent] +=referralParentEth;

        if(msg.value >= .05 ether){
           referralAmountMapping[referrer] += 1;
        }
    }


    function SellRKTNreferralBenefits(uint256 amount) payable public {
        require(amount > 0, "You need to sell at least 1 token!!");
        uint256 allowance = IERC20(tokenAddress).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check token allowance");
        require(referralAmountMapping[msg.sender] >= referralRewardThreshold, "You do not have enough referrals to access this function");
        require(referralSellRewardEnabled, "Sell rewards disabled");

        //get iniital contract balances
        uint256 InitialRKTNcontractBalance = IERC20(tokenAddress).balanceOf(address(this));
        uint256 InitialEthContractBalance = address(this).balance;
        bool success;

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        uint256 rktnBalance = IERC20(tokenAddress).balanceOf(address(this)).sub(InitialRKTNcontractBalance);

        swapTokensForEth(rktnBalance);

        uint256 ethBalance = address(this).balance.sub(InitialEthContractBalance);

        if(referralAmountMapping[msg.sender] >= 100){
           payable(msg.sender).transfer(ethBalance);
        }
        else if(referralAmountMapping[msg.sender] >= 30){
                             
          uint256 totalFee = 0;
          uint256 devFee = 0;
          uint256 commFee = 0;
          uint256 devAmmount = 0;
          uint256 commAmount = 0;
          uint256 feeAmountEth = 0;

          totalFee = sellBaseFee.div(2);
          devFee = sellBaseFee.div(2);
          commFee = sellBaseFee.div(2);

          feeAmountEth = ethBalance.mul(totalFee).div(100);
          devAmmount = (feeAmountEth * devFee) / totalFee;
          commAmount = (feeAmountEth * commFee) / totalFee;

          ethBalance -= feeAmountEth;

          (success, ) = address(devWallet).call{value: devAmmount}("");
          (success, ) = address(communityWallet).call{value: commAmount}("");
          
          payable(msg.sender).transfer(ethBalance);
        }
        else{

          uint256 totalFee = 0;
          uint256 devFee = 0;
          uint256 commFee = 0;
          uint256 devAmmount = 0;
          uint256 commAmount = 0;
          uint256 feeAmountEth = 0;

          totalFee = sellBaseFee;
          devFee = sellBaseFee.div(2);
          commFee = sellBaseFee.div(2);

          feeAmountEth = ethBalance.mul(totalFee).div(100);
          devAmmount = (feeAmountEth * devFee) / totalFee;
          commAmount = (feeAmountEth * commFee) / totalFee;

          ethBalance -= feeAmountEth;

          (success, ) = address(devWallet).call{value: devAmmount}("");
          (success, ) = address(communityWallet).call{value: commAmount}("");
          
          payable(msg.sender).transfer(ethBalance);

        }
    }

    function BuyRKTNHolderBenefit() payable public {
        require(msg.value > 0, "Must send ETH to purchase");
        require(holderBuyRewardEnabled, "Holder reward buy function disabled");
        uint256 RKTNBalance = IERC20(tokenAddress).balanceOf(msg.sender);
        require(RKTNBalance > 0, "Must own RKTN to use this buy function");

        uint256 InitialcontractBalance = IERC20(tokenAddress).balanceOf(address(this));

         uint256 amount = msg.value;
         uint256 totalFee = 2;
         uint256 fees = 0;
         bool success;

         fees = amount.mul(totalFee).div(100);

         amount -= fees;

         swapEthForTokens(amount);
         
         uint256 rktnBalance = IERC20(tokenAddress).balanceOf(address(this)).sub(InitialcontractBalance);

         IERC20(tokenAddress).approve(address(this), rktnBalance);

         IERC20(tokenAddress).transferFrom(address(this), msg.sender, rktnBalance);

         (success, ) = address(communityWallet).call{value: fees}("");

    }

    function swapEthForTokens(uint256 ethAmount) private {
        // generate the uniswap pair path of weth -> token
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(tokenAddress);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }


    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = uniswapV2Router.WETH();

        IERC20(tokenAddress).approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

}