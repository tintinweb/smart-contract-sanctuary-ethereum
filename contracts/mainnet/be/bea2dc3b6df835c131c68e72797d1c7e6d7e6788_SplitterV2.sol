/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// File: UniRouterData.sol


pragma solidity >=0.8.7 <0.9.0;

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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: SpiltterV2.sol


pragma solidity >=0.8.10 < 0.9;






contract SplitterV2 is ReentrancyGuard{

    using SafeMath for uint256;
    using SafeMath for uint16;

    event UserChanged(address indexed newUser, uint256 indexed location);
    event Success(bool success, address user);
    event AdminUpdated(address indexed admin, bool indexed truth);
    event DonationEdited(address indexed nonProfit, bool truth);

    struct Profile{
        address user;
        uint16 split;
        uint16 donationSplit;
        uint16 rebaseSplit;
        uint16 adjustedSplit;
    }

    struct PairedToken{
        address token;
        uint creator;
        uint position;
    }

    mapping(address => PairedToken) public tokenPaired;
    address[] public pairedTokens;
    uint16 rebaseSplit;
    uint256 index;

    mapping(address => bool) admin;

    Profile[] public userData;

    address public immutable primaryToken;
    address public defaultDonation;
    uint16 public donationSplit;
    bool public donationActive;

    uint16 public constant totalPoints = 1000;
    
    IUniswapV2Router02 public immutable uniswapV2Router;

    constructor(){
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        primaryToken = 0x64Df3aAB3b21cC275bB76c4A581Cf8B726478ee0;
        userData.push(Profile(0x1784662D0Af586f42F0E822D5c675a9766DDF7Ed,750,0,0,750));
        admin[0x1784662D0Af586f42F0E822D5c675a9766DDF7Ed] = true;
        userData.push(Profile(0xfDDd11361a8De23106b8699e638155885c6DaF6a, 75,0,0,75));
        userData.push(Profile(0x7e6BC386A3fF7D4fd4BF78D96f7316263855521b, 75,0,0,75));
        admin[0x7e6BC386A3fF7D4fd4BF78D96f7316263855521b]=true;

        addToken(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,475); //WBTC
        addToken(0x6B175474E89094C44Da98b954EedeAC495271d0F,475); //DAI
        addToken(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0,475); //Matic

        rebaseSplit =100;
    }
    /**
     * @dev function to change address of user to another addres
     * @param newUser address to change to
     * @param userLocation location to change
     */
    function changeUser(address newUser, uint256 userLocation)external{
        require(userLocation < userData.length, "Location out of bounds");
        require(msg.sender == userData[userLocation].user, "Not Approved");
        if(admin[msg.sender]){
            admin[userData[userLocation].user] = false;
            admin[newUser] = true;
        }
        userData[userLocation].user = newUser;
    }
    /**
     * @dev used for admin only functions
     */
    modifier isAdmin(){
        require(admin[msg.sender], "Error: No entry");
        _;
    }
    /**
     * @dev function to add and remove admin addresses
     * @param newAdmin address to toggle
     * @param truth true or false for isadmin
     */
    function toggleAdmin(address newAdmin, bool truth)external isAdmin{
        require(msg.sender != newAdmin, "Can not toggle self");
        admin[newAdmin] = truth;
        emit AdminUpdated(newAdmin, truth);
    }
    /**
     * @dev function to add new token for rebase
     * @param token to add to rebase
     * @param userLocation caller user
     */
    function addPairedToken(address token, uint userLocation) external{
        Profile storage user = userData[userLocation];
        require(user.user == msg.sender, "Not User");
        require(20 <= user.adjustedSplit, "User does not have enough to Split");
        require(canAdd(token), "Cannot add token");
        user.adjustedSplit -=20;
        user.rebaseSplit +=20;
        rebaseSplit +=20;
        addToken(token, userLocation);
    }
    /**
     * @dev function to check if a token can be added
     * @param token to check
     */
    function canAdd(address token)public view returns(bool){
        bool truth = token != primaryToken; // not PrimaryToken
        truth = truth && token != address(0); //not null
        truth = truth && tokenPaired[token].token == address(0); //not added
        truth = (truth && token != uniswapV2Router.WETH()); // not weth
        truth = (truth && address(0) != IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, primaryToken)); //LP created
        truth = (truth && address(0) != IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, uniswapV2Router.WETH())); //token has eth LP
        return truth;

    }
    /**
     * @dev function to add token to rebase system
     * @param token to add to the rebase system
     * @param location to of creator
     */
    function addToken(address token, uint location)internal {
        PairedToken storage t = tokenPaired[token];
        t.token = token;
        t.creator = location;
        t.position = pairedTokens.length;
        pairedTokens.push(token);

    }
    /**
     * @dev funciton to remove a token from the rebase system
     * @param token the token to remove
     */
    function removeToken(address token) external {
        PairedToken storage t1 = tokenPaired[token];
        require(t1.token != address(0), "Token Does not exist");
        require(pairedTokens[t1.position] == token, "Not token location");
        Profile storage user = userData[t1.creator];
        require(user.user == msg.sender, "Not approved");
        
        PairedToken storage t2 = tokenPaired[pairedTokens[pairedTokens.length-1]];
        pairedTokens[t1.position] = t2.token;
        t2.position = t1.position;
        pairedTokens.pop();
        t1.token = address(0);

        user.adjustedSplit +=20;
        if(user.rebaseSplit <=20){user.rebaseSplit =0;}
        else{user.rebaseSplit -=20;}
        rebaseSplit -=20;
    }
    /**
     * @dev function to call distribute with default nonProfit address if active
     */
    function distribute()external{
        require(admin[msg.sender] || msg.sender == userData[1].user, "Not Approved");
        _distribute(defaultDonation);
    }

    /**
     * @dev function for users to give points to donation Address
     * @param userLocation the callers array index
     * @param trueAddToDonationFalseRemove bool to determine add or removal of points to nonProfit
     * @param points the amount of points to add or remove
     */
    function toggleDonationSplit(uint userLocation, bool trueAddToDonationFalseRemove, uint16 points)external {
        require(userLocation < userData.length, "User Out of Bounders");
        require(points > 0, "Need an actual number");
        Profile storage user = userData[userLocation];
        require(user.user == msg.sender, "Not User");
        if(trueAddToDonationFalseRemove){
            if(user.adjustedSplit <= points){points = user.adjustedSplit;}
            user.adjustedSplit -= points;
            user.donationSplit += points;
            donationSplit += points;
        }else{
            if(user.donationSplit <= points){points = user.donationSplit;}
            user.donationSplit -= points;
            user.adjustedSplit += points;
            if(donationSplit<=points){donationSplit = 0;}
            else{donationSplit -= points;}
        }
    }
    /**
     * @dev funciton to toggle donation address and activity
     * @param nonProfit address to set as default
     * @param truth is donation active or false
     */
    function toggleActiveDonation(address nonProfit, bool truth)external isAdmin{
        require(nonProfit != address(0) || !truth, "Must be real address");
        defaultDonation = nonProfit;
        donationActive = truth;
        emit DonationEdited(nonProfit, truth);
    }
    /**
     * @dev funciton to distribute eth to addresses and rebase
     * @param donation address of nonProfit
     */
    function _distribute(address donation) internal{
        uint256 denom =totalPoints;
        if(!donationActive && donationSplit >0){
            denom -= donationSplit; //If donations not active then it'll try to balance the %s while removing the donation split
        }
        uint256 baseEth = address(this).balance/denom; 
        bool success;
        uint256 amount;
        for(uint256 i =0; i < userData.length; i++){
            if(userData[i].adjustedSplit > 0){
                amount = baseEth * userData[i].adjustedSplit;
                (success, ) = address(userData[i].user).call{value: amount}("");
                emit Success(success, userData[i].user);
            }
        }
        if(donationSplit > 0 && donationActive){
            amount = baseEth * donationSplit;
            (success, ) = address(donation).call{value: amount}("");
            emit Success(success, donation);  
        }
        rebase();
    }
    /**
     * @dev function to rebase LPs
     */
    function rebase()internal{
        if(index >= pairedTokens.length){//if finished with the indexes move to the eth LP and rebase it
            IWETH(uniswapV2Router.WETH()).deposit{value: address(this).balance}();
            _erc20Rebase(uniswapV2Router.WETH());
            index = index % pairedTokens.length;
        }else{
            address to = IUniswapV2Factory(uniswapV2Router.factory()).getPair(pairedTokens[index], primaryToken);
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = pairedTokens[index];
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(0, path, to, block.timestamp);
            IUniswapV2Pair(to).sync();
            index++;
        }
    }
    /**
     * @dev funciton to rebase or sale erc20 tokens
     * @param token erc20 address to sell or rebase
     */
    function ERC20(address token) external{
        require(admin[msg.sender] || msg.sender == userData[1].user, "Not Approved");
        require(IERC20(token).balanceOf(address(this)) > 1, "No tokens to transfer");
        if(IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, uniswapV2Router.WETH()) != address(0)){
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = uniswapV2Router.WETH();
            IERC20(token).approve(address(uniswapV2Router), type(uint256).max);
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                IERC20(token).balanceOf(address(this)),
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
            if(1 ether < address(this).balance){
                _distribute(defaultDonation);
            }        
        }   
    }

    /**
     * @dev function to rebase into token and primaryToken LP
     * @param token token to rebase with primaryToken
     */
    function _erc20Rebase(address token) internal{
        address to = IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, primaryToken);
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
        IUniswapV2Pair(to).sync();
    }
    /**
     * @dev function to send points to another user.
     * @param callerLocation the senders spot in the array
     * @param points the amount of points to give reciever
     * @param sendToRebase mark as true if points go to rebase split
     */
    function givePointsToAnother(uint callerLocation, uint16 points, uint16 receiverLocation, bool sendToRebase) external{
        require(callerLocation < userData.length, "Caller Out of Bounders");
        Profile storage user = userData[callerLocation];
        require(user.user == msg.sender, "Not User");
        require(user.adjustedSplit >= points, "Not enough Points");
        require(sendToRebase || receiverLocation < userData.length, "reciever out of bounds");
        user.split -= points;
        user.adjustedSplit -= points;
        if(sendToRebase){
            rebaseSplit +=points;
        }else{
            userData[receiverLocation].split += points;
            userData[receiverLocation].adjustedSplit += points;
        }
    }
    /**
     * @dev function to return points/positions of different elements for distribution.
     */
    function viewPoints()external view returns(uint16 marketingPoints, uint16 devPoints, uint16 donationPoints, uint16 rebasePoints, uint16 divideBy){

        marketingPoints = userData[0].adjustedSplit;
        devPoints += userData[1].adjustedSplit;
        devPoints += userData[2].adjustedSplit;
        rebasePoints = rebaseSplit;
        divideBy = totalPoints;
        donationPoints = donationSplit;
        if(!donationActive && donationSplit > 0){
            donationPoints =0;
            divideBy -= donationSplit;
        }
    }
    receive() external payable {}

    function nextToRebase()external view returns(address token){

        if(index < pairedTokens.length){
            token = pairedTokens[index];
        }else{
            token = uniswapV2Router.WETH();
        }
    }
}