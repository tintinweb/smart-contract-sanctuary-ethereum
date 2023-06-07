/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: Flattener.sol

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract DigitalDumpsterPreSale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public _contributions;
    mapping(address => uint256) public claimedTokens;
    mapping(address => uint256) public lastClaimed;

    IERC20 public _token = IERC20(0x5A8475AF65b4f83369fF917A061fd9dc5A0A6b2e);
    uint256 private _tokenDecimals = 18;
    address payable public _wallet = payable(0x4989703af08A2Df8e28eA5E615b793034EEC2F5B);
    uint256 public _rate;
    uint256 public _weiRaised;
    uint256 public minPurchase = 0.05 ether;
    uint256 public maxPurchase = 0.5 ether;
    uint256 public softCap = 30 ether;
    uint256 public hardCap = 300 ether;
    uint256 public availableTokensICO = 9800000 * (10**18); // Assuming TRASH has 18 decimals
    uint256 public refundStartDate;
    uint256 public endICO;
    bool public startRefund = false;
     mapping(address => bool) public airdropRecipients;
    address[] public airdropAddresses;
    uint256 public numRecipients;

    event AirdropAdded(address indexed recipient);
    event AirdropDistributed(address indexed recipient, uint256 amount);
    event TokensPurchased(address purchaser, address beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);

       modifier icoActive() {
    require(endICO > 0 && block.timestamp < endICO, "ICO must be active");
    _;
    }

    modifier icoNotActive() {
    require(endICO == 0 || block.timestamp >= endICO, "ICO must not be active");
    _;
    }
    
        constructor (

        address payable wallet,
        address tokenAddress,
        uint256 tokenDecimals
    ) {
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(tokenAddress != address(0), "Pre-Sale: token is the zero address");
        
        _wallet = wallet;
        _token = IERC20(tokenAddress);
        _tokenDecimals = tokenDecimals;
    }

    receive () external payable {
        if (endICO > 0 && block.timestamp < endICO) {
            buyTokens(_msgSender());
        } else {
            endICO = 0;
            revert('Pre-Sale is closed');
        }
    }
    
function startICO(uint endDate) external onlyOwner icoNotActive() {
    require(endDate > block.timestamp, 'endDate should be in the future');

    minPurchase = minPurchase; 
    maxPurchase = maxPurchase; 
    softCap = softCap; 
    hardCap = hardCap; 

    endICO = endDate; 
    refundStartDate = endDate + 2 days;

    _weiRaised = 0;
    startRefund = false;
    refundStartDate = 0;
    availableTokensICO = _token.balanceOf(address(this));
}
    
    function stopICO() external onlyOwner icoActive() {
        endICO = 0;
        if (_weiRaised >= softCap) {
            _forwardFunds();
        } else {
            startRefund = true;
            refundStartDate = block.timestamp;
        }
    }
    
    function buyTokens(address beneficiary) public nonReentrant icoActive payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        availableTokensICO = availableTokensICO.sub(tokens);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(weiAmount >= minPurchase, 'have to send at least: minPurchase');
        require(_contributions[beneficiary].add(weiAmount) <= maxPurchase, 'can\'t buy more than: maxPurchase');
        require((_weiRaised.add(weiAmount)) <= hardCap, 'Hard Cap reached');
        this;
    }

    function claimTokens() public nonReentrant icoNotActive returns (bool) {
    require(claimedTokens[msg.sender] < 100, "Already claimed 100% of allocation");
    require(lastClaimed[msg.sender] + 1 days <= block.timestamp, "Must wait 24 hours between claims");

    uint256 userContribution = _contributions[msg.sender];
    uint256 userShare = userContribution.mul(_rate).div(10 ** _tokenDecimals);
    uint256 tokenBalance = userShare.sub(claimedTokens[msg.sender]);

    require(tokenBalance > 0, "No tokens left to claim");

    uint256 tokensToClaim;
    if (claimedTokens[msg.sender] == 0) {
        tokensToClaim = tokenBalance.mul(50).div(100);
    } else {
        tokensToClaim = tokenBalance.mul(10).div(100);
    }

    claimedTokens[msg.sender] = claimedTokens[msg.sender].add(tokensToClaim);
    lastClaimed[msg.sender] = block.timestamp;

        bool sent = _token.transfer(msg.sender, tokensToClaim);
    require(sent, "Token transfer failed");
    return true;
}



    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate).div(10 ** _tokenDecimals);
    }

function _forwardFunds() internal {
    _wallet.transfer(_weiRaised);
    uint256 totalTokens = _token.balanceOf(address(this));
    uint256 tokensToOwner = totalTokens.mul(63).div(100);
    _token.transfer(_wallet, tokensToOwner);
}


    function withdraw() external onlyOwner icoNotActive {
        require(startRefund == false || (refundStartDate + 3 days) < block.timestamp);
        require(address(this).balance > 0, 'Contract has no balance');
        _wallet.transfer(address(this).balance);    
    }

    function checkContribution(address addr) public view returns(uint256) {
        return _contributions[addr];
    }

    function setRate(uint256 newRate) external onlyOwner icoNotActive {
        _rate = newRate;
    }

    function setAvailableTokens(uint256 amount) public onlyOwner icoNotActive {
        availableTokensICO = amount;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function setWalletReceiver(address payable newWallet) external onlyOwner {
        _wallet = newWallet;
    }

    function setHardCap(uint256 value) external onlyOwner {
        hardCap = value;
    }

    function setSoftCap(uint256 value) external onlyOwner {
        softCap = value;
    }

    function setMaxPurchase(uint256 value) external onlyOwner {
        maxPurchase = value;
    }

    function setMinPurchase(uint256 value) external onlyOwner {
        minPurchase = value;
    }

   function takeTokens(IERC20 tokenAddress) public onlyOwner icoNotActive returns (bool) {
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
            bool sent = tokenBEP.transfer(_wallet, tokenAmt);
    require(sent, "Token transfer failed");
    return true;
    }

    function refundMe() public icoNotActive {
        require(startRefund == true, 'no refund available');
        uint256 amount = _contributions[msg.sender];
        if (address(this).balance >= amount) {
            _contributions[msg.sender] = 0;
            if (amount > 0) {
                address payable recipient = payable(msg.sender);
                recipient.transfer(amount);
                emit Refund(msg.sender, amount);
            }
        }
    }

        function addAirdropRecipients(address[] memory recipients) public onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            if (!airdropRecipients[recipients[i]]) {
                airdropRecipients[recipients[i]] = true;
                airdropAddresses.push(recipients[i]);
                numRecipients++;
                emit AirdropAdded(recipients[i]);
            }
        }
    }

    function distributeAirdrop() public onlyOwner {
    require(numRecipients > 0, "No recipients for airdrop");
    uint256 totalAirdrop = _token.balanceOf(address(this)).mul(2).div(100);
    require(_token.balanceOf(address(this)) >= totalAirdrop, "Insufficient tokens for airdrop");

    uint256 amountPerRecipient = totalAirdrop.div(numRecipients);

    for (uint256 i = 0; i < airdropAddresses.length; i++) {
        if (airdropRecipients[airdropAddresses[i]]) {
            _token.transfer(airdropAddresses[i], amountPerRecipient);
            emit AirdropDistributed(airdropAddresses[i], amountPerRecipient);
            airdropRecipients[airdropAddresses[i]] = false;
        }
    }

    delete airdropAddresses;
    numRecipients = 0;
}


    function withdrawTRASH() external onlyOwner icoNotActive {
    uint256 tokenBalance = _token.balanceOf(address(this));
    require(tokenBalance > 0, 'Contract has no TRASH balance');
    _token.transfer(_wallet, tokenBalance);
}
    function withdrawETH() external onlyOwner {
    require(address(this).balance > 0, 'Contract has no ETH balance');
    _wallet.transfer(address(this).balance);
    }
}