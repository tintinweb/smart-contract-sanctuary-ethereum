/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/RaisinCore.sol


//Copyright (C) 2022 Raisin Labs

pragma solidity 0.8.17;




contract RaisinCore is Ownable {
   using SafeMath for uint256;

   //custom errors
   error zeroGoal(uint);
   error tokenNotWhitelisted(IERC20);
   error notYourRaisin(uint);
   error raisinExpired();
   error raisinActive();
   error goalNotReached();
   error goalReached();

    /* /////////////////////////////////////////////////////////////////
    /                                                                   /
    /                                                                   \
    /                            Events                                 /
    /                                                                   \
    /                                                                   /
    ///////////////////////////////////////////////////////////////////*/
    event FundStarted (uint indexed amount, uint index, IERC20 indexed token, address indexed raiser, address recipient, uint64 expires);
    event TokenDonated (address indexed adr, IERC20 token, uint indexed amount, uint index);
    event TokenAdded (IERC20 indexed token);
    event FundEnded (uint indexed index);

    /* /////////////////////////////////////////////////////////////////
    /                                                                   /
    /                                                                   \
    /                          Mappings                                 /
    /                                                                   \
    /                                                                   /
    ///////////////////////////////////////////////////////////////////*/

    mapping (address => mapping(uint => uint)) public donorBal;
    mapping (IERC20 => bool) public tokenWhitelist;
    mapping (address => uint) private partnership;

    /* /////////////////////////////////////////////////////////////////
    /                                                                   /
    /                                                                   \
    /                           State Variables                         /
    /                                                                   \
    /                                                                   /
    ///////////////////////////////////////////////////////////////////*/
    //withdraw address
    address private vault;
    uint public fee;
    //expiry time for all projects
    uint64 public expiry;
    address public governance;

    /* /////////////////////////////////////////////////////////////////
    /                                                                   /
    /                                                                   \
    /                            Structs                                /
    /                                                                   \
    /                                                                   /
    ///////////////////////////////////////////////////////////////////*/
    struct Raisin  {
        //raise goal amount in native token 
        uint _amount;
        uint _fundBal;
        //balance of fund
        //token to raise in 
        IERC20 _token; 
        //address of wallet raising funds
        address _raiser;
        address _recipient;
        //timestamp expiry 
        uint64 _expires;        
    }
    /* /////////////////////////////////////////////////////////////////
    /                                                                   /
    /                                                                   \
    /                            Array + Constructor                    /
    /                                                                   \
    /                                                                   /
    ///////////////////////////////////////////////////////////////////*/

    Raisin [] public raisins; 


    constructor (address treasury, address governanceMultisig) {
        expiry = 180 days;
        vault = treasury;
        fee = 200; 
        governance = governanceMultisig;
    }


    /* /////////////////////////////////////////////////////////////////
    /                                                                   /
    /                                                                   \
    /                         Fund Functions                            /
    /                                                                   \
    /                                                                   /
    ///////////////////////////////////////////////////////////////////*/

   //starts fund for user
   //@param amount: amount of tokens being raised
   //@param token: token raised in
   
    function initFund (uint amount, IERC20 token, address recipient) external {
        if (amount == 0){revert zeroGoal(amount);}
        if(tokenWhitelist[token] != true){revert tokenNotWhitelisted(token);}
        uint64 expires = getExpiry();
        raisins.push(Raisin(amount, 0, token, msg.sender, recipient, expires));
        emit FundStarted(amount, raisins.length - 1, token, msg.sender, recipient, expires);
    }

    function endFund (uint index) external {
        if (msg.sender != raisins[index]._raiser || msg.sender != governance){revert notYourRaisin(index);}
        raisins[index]._expires = uint64(block.timestamp);
        if(raisins[index]._fundBal == 0){emit FundEnded(index);}
    }

    function donateToken (
        IERC20 token,
        uint index,
        uint amount
    ) external payable {
        if (uint64(block.timestamp) >= raisins[index]._expires){revert raisinExpired();} 
        if (token != raisins[index]._token){revert tokenNotWhitelisted(token);} 
        uint donation = amount - calculateFee(amount, msg.sender);
        donorBal[msg.sender][index] += donation;
        raisins[index]._fundBal += donation; 
        erc20Transfer(token, msg.sender, vault, (amount - donation)); 
        erc20Transfer(token, msg.sender, address(this), donation); 
        emit TokenDonated (msg.sender, token, donation, index);

    }

    /* /////////////////////////////////////////////////////////////////
    /                                                                   /
    /                                                                   \
    /                        Withdraw/Refund Tokens                     /
    /                                                                   \
    /                                                                   /
    ///////////////////////////////////////////////////////////////////*/

    function fundWithdraw (IERC20 token, uint index) external payable{
        if(raisins[index]._fundBal < raisins[index]._amount){revert goalNotReached();}
        if (uint64(block.timestamp) < raisins[index]._expires){revert raisinActive();}
        uint bal = raisins[index]._fundBal;
        raisins[index]._fundBal = 0;
        approveTokenForContract(token, bal);
        erc20Transfer(token, address(this), raisins[index]._recipient, bal);
        emit FundEnded(index);
    }

    function refund (IERC20 token, uint index) external payable{
        if (uint64(block.timestamp) < raisins[index]._expires){revert raisinActive();} 
        if (raisins[index]._fundBal >= raisins[index]._amount){revert goalReached();}
        uint bal = donorBal[msg.sender][index];
        donorBal[msg.sender][index] -= bal;
        raisins[index]._fundBal -= bal;
        approveTokenForContract(token, bal);
        erc20Transfer(token, address(this), msg.sender, bal);
        if (bal == 0){emit FundEnded(index);}
    }

    /* /////////////////////////////////////////////////////////////////
    /                                                                   /
    /                                                                   \
    /                        External Interactions                      /
    /                                                                   \
    /                                                                   /
    ///////////////////////////////////////////////////////////////////*/

    function approveTokenForContract (
        IERC20 token,
        uint amount
    ) private {
        bool sent = token.approve(address(this), amount);
        require(sent, "approval failed");
    }

    function erc20Transfer (
        IERC20 token,
        address sender,
        address recipient,
        uint amount
        ) private {
        bool sent = token.transferFrom(sender, recipient, amount); 
        require(sent, "Token transfer failed"); 
    }

    /* /////////////////////////////////////////////////////////////////
    /                                                                   /
    /                                                                   \
    /                               Admin                               /
    /                                                                   \
    /                                                                   /
    ///////////////////////////////////////////////////////////////////*/

    function manageDiscount (address partnerWallet, uint newFee) external onlyOwner {
        partnership[partnerWallet] = newFee;
    }
    function getExpiry() private view returns (uint64) {
        return uint64(block.timestamp) + expiry;
    }
    function calculateFee(uint amount, address raiser) private view returns (uint _fee){
        uint pf = partnership[raiser];
        return pf != 0 ? _fee = amount.mul(pf).div(10000) : _fee = amount.mul(fee).div(10000);
    }
    //we need to store a flat amount of time here UNIX format padded to 32 bytes
    function changeGlobalExpiry(uint newExpiry) external onlyOwner returns (uint64){
        expiry = uint64(newExpiry); 
        return expiry;
    }
    function changeFee(uint newFee) external onlyOwner {
        require (newFee != 0 && newFee != fee);
        fee = newFee; 
    }
    function whitelistToken (IERC20 token) external onlyOwner {
        tokenWhitelist[token] = true; 
        emit TokenAdded(token); 
    }

    function removeWhitelist(IERC20 token) external onlyOwner {
        tokenWhitelist[token] = false; 
    }

    function changeVault(address newAddress) external onlyOwner {
        require(newAddress != address(0));
        vault = newAddress;
    }

    function changeGovernanceWallet(address newGovWallet) external onlyOwner {
        require (newGovWallet != address(0));
        governance = newGovWallet;
    }
}