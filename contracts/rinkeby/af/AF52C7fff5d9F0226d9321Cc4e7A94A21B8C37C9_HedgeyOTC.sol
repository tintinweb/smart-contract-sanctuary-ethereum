// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/// @dev this is the one contract call that the OTC needs to interact with the NFT contract
/// @dev the renounce ownership function that is part of the Ownable Libarary, inherited by the NFT contract, is intentionally omitted from this interface
/// @dev the updateBaseURI function is intentionall ommitted from this interface
interface IFuturesNFT {
    function createNFT(address _holder, uint _amount, address _token, uint _unlockDate) external returns (uint);
}


/// @dev this interface is used for handling WETH to be used for token locking and payments
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

/// @dev this interface is a critical addition that is not part of the standard ERC-20 specifications
/// @dev this is required to do the calculation of the total price required, when pricing things in the payment currency
/// @dev only the payment currency is required to have a decimals impelementation on the ERC20 contract, otherwise it will fail
interface Decimals {
    function decimals() external view returns (uint256);
}


/**
 * @title HedgeyOTC is an over the counter contract with time locking abilitiy
 * @notice This contract allows for a seller to generate a unique over the counter deal, which can be private or public
 * @notice The public deals allow anyone to participate and purchase tokens from the seller, whereas a private deal allows only a single whitelisted address to participate 
 * @notice The Seller chooses whether or not the tokens being sold will be locked, as well as the price for the offer
*/
contract HedgeyOTC is ReentrancyGuard {
    using SafeERC20 for IERC20;


    address payable public weth;
    /// @dev d is a strict uint for indexing the OTC deals one at a time
    uint public d = 0;
    /// @dev we use this address to store a single futures contract, which is our NFT ERC721 contract address, which we point to for the minting process
    address public futureContract;

    constructor(address payable _weth, address _fc) {
        weth = _weth;
        futureContract = _fc;
    }

    /**
     * @notice Deal is the struct that defines a single OTC offer, created by a seller
     * @param  Deal struct contains the following parameter definitions:
     * @param 1) seller: This is the creator and seller of the deal, needs to be an address payable if the payment currenct is ETH / WETH
     * @param 2) token: This is the token that the seller deposits into the contract and which they are selling over the counter. The address defines this ERC20
     * @param ... the token ERC20 contract is required to have a public call function decimals() that returns a uint. This is required to price the amount of tokens being purchase
     * @param ... by the buyer - calculating exactly how much to deliver to the seller. 
     * @param 3) paymentCurrency: This is also an ERC20 which the seller will get paid in, during the act of a buyer buying tokens, and paying the seller in the paymentCurrency
     * @param 4) remainingAmount: This initially is the entire deposit the seller is selling, but as people purchase chunks of the deal, the remaining amount is decreased to 0
     * @param 5) minimumPurchase: This is the minimum chunk size that a buyer can purchase, defined by the seller. this prevents security issues of
     * @param ... buyers purchasing 1wei worth of the token which can cause a 0 payment amount, resulting in a conflict. 
     * @param 6) price: The Price is the per token cost which buyers pay to the seller, denominated in the payment currency. This is not the total price of the deal
     * @param ... the total price is calculated by the remainingAmount * price (then adjusting for the decimals of the payment currency)
     * @param 7) maturity: this is the unix block time for up until this deal is valid. After the maturity no purchases can be made.
     * @param 8) unlockDate: this is the unix block time which may be used to time lock tokens that are sold. If the unlock date is 0 or less than current block time
     * @param ... at the time of purchase, the tokens are not locked but rather delivered directly to the buyer from the contract
     * @param 9) open: boolean for security purposes to check if this deal is still open and can be purchsed. When the remainingAmount == 0 or it has been cancelled by the seller open == false and no purcahses can be made
     * @param 10) buyer: this is a whitelist address for the buyer. It can either be the Zero address - which indicates that Anyone can purchase
     * @param ... or it is a single address that only that owner of the address can participate in purchasing the tokens
    */
    struct Deal {
        address seller;
        address token;
        address paymentCurrency;
        uint remainingAmount;
        uint minimumPurchase;
        uint price;
        uint maturity;
        uint unlockDate;
        bool open;
        address buyer;
    }

    /// @dev the Deals are all mapped via the indexer d to deals mapping
    mapping (uint => Deal) public deals;

    receive() external payable {}

    /// @dev internal function that handles transfering payments from buyers to sellers with special WETH handling
    /// @dev this function assumes that if the recipient address is a contract, it cannot handle ETH - so we always deliver WETH
    /// @dev special care needs to be taken when using contract addresses to sell deals - to ensure it can handle WETH properly when received
    function _transferPymt(address _token, address from, address payable to, uint _amt) internal {
        if (_token == weth) {
            
            if (!Address.isContract(to)) {
                to.transfer(_amt);
            } else {
                // we want to deliver WETH from ETH here for better handling at contract
                IWETH(weth).deposit{value: _amt}();
                assert(IWETH(weth).transfer(to, _amt));
            }
        } else {
            SafeERC20.safeTransferFrom(IERC20(_token), from, to, _amt);         
        }
    }

    /// @dev internal funciton that handles withdrawing tokens that are up for sale to buyers
    /// @dev this function is only called if the tokens are not timelocked
    /// @dev this function handles weth specially and delivers ETH to the recipient
    function _withdraw(address _token, address payable to, uint _amt) internal {
        if (_token == weth) {
            IWETH(weth).withdraw(_amt);
            to.transfer(_amt);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), to, _amt);
        }
    }


    /** 
     * @notice This function is what the seller uses to create a new OTC offering
     * @dev this function will pull in tokens from the seller, create a new struct as Deal indexed by the current uint d
     * @dev this function does not allow for taxed / deflationary tokens - as the amount that is pulled into the contract must match with what is being sent  
     * @dev this function requires that the _token has a decimals() public function on its ERC20 contract to be called 
     * @param _token address is the token that the seller is going to create the over the counter offering for
     * @param _paymentCurrency is the address of the opposite ERC20 that the seller wants to get paid in when selling the token (use WETH for ETH)
     * @param _amount is the amount of tokens that you as the seller want to sell
     * @param _min is the minimum amount of tokens that a buyer can purchase from you. this should be less than or equal to the total amount
     * @param _price is the price per token which you would like to get paid, denominated in the payment currency
     * @param _maturity is how long you would like to allow buyers to purchase tokens from this deal, in unix block time. this needs to be beyond current time
     * @param _unlockDate is used if you are requiring that tokens purchased by buyers are locked. If this is set to 0 or anything less than current time 
     * ... any tokens purchased will not be locked but immediately delivered to the buyers. Otherwise the unlockDate will lock the tokens in the associated 
     * ... futures NFT contract - which will hold the tokens in escrow until the unlockDate has passed - whereupon the owner of the NFT can redeem the tokens
     * @param _buyer is a special option to make this a private deal - where only the buyer's address can participate and make the purchase. If this is set to the 
     * ... Zero address - then it is publicly available and anyone can purchase tokens from this deal
    */
    function create(
        address _token,
        address _paymentCurrency,
        uint _amount,
        uint _min,
        uint _price,
        uint _maturity,
        uint _unlockDate,
        address payable _buyer
    ) payable external {
        require(_maturity > block.timestamp, "HEC01: Maturity before block timestamp");
        require(_amount >= _min, "HEC02: Amount less than minium");
        /// @dev this checks to make sure that if someone purchases the minimum amount, it is never equal to 0
        /// @dev where someone could find a small enough minimum to purchase all of the tokens for free.
        require((_min * _price) / (10 ** Decimals(_token).decimals()) > 0, "HEC03: Minimum smaller than 0");
        /// @dev we check the before balance of this address for security - this includes checking the WETH balance
        uint currentBalance = IERC20(_token).balanceOf(address(this));
        /// @dev this function physically pulls the tokens into the contract for escrow
        if (_token == weth) {
            require(msg.value == _amount, "HECA: Incorrect Transfer Value");
            IWETH(weth).deposit{value: _amount}();
            assert(IWETH(weth).transfer(address(this), _amount));
        } else {
            require(IERC20(_token).balanceOf(msg.sender) >= _amount, "HECB: Insufficient Balance");
            SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), _amount);
        }
        /// @dev check the current balance now that the tokens should be in the contract address, including WETH balance to ensure the deposit function worked
        /// @dev we need to ensure that the balance matches the amount input into the parameters - since that amount is recorded on the Deal struct
        uint postBalance = IERC20(_token).balanceOf(address(this));
        assert(postBalance - currentBalance == _amount);
        /// @dev creates the Deal struct with all of the parameters for inputs - and set the bool 'open' to true so that this offer can now be purchased
        deals[d++] = Deal(msg.sender, _token, _paymentCurrency, _amount, _min, _price, _maturity, _unlockDate, true, _buyer);
        emit NewDeal(d - 1, msg.sender, _token, _paymentCurrency, _amount, _min, _price, _maturity, _unlockDate, true, _buyer);
    }


    /** 
     * @notice This function lets a seller cancel their existing deal anytime they would like to
     * @notice there is no requirement that the deal have expired
     * @notice all that is required is that the deal is still open, and that there is still a reamining balance
     * @dev you need to know the index _d of the deal you are trying to close and that is it
     * @dev only the seller can close this deal
    */    
    function close(uint _d) external nonReentrant {
        Deal storage deal = deals[_d];
        require(msg.sender == deal.seller, "HEC04: Only Seller Can Close");
        require(deal.remainingAmount > 0, "HEC05: All tokens have been sold");
        require(deal.open, "HEC06: Deal has been closed");
        /// @dev once we have confirmed it is the seller and there are remaining tokens - physically pull the remaining balances and deliver to the seller
        _withdraw(deal.token, payable(msg.sender), deal.remainingAmount);
        /// @dev we now set the remaining amount to 0 and ensure the open flag is set to false, thus this deal can no longer be interacted with 
        deal.remainingAmount = 0;
        deal.open = false;
        emit DealClosed(_d);
    }

    /**
     * @notice This function is what buyers use to make their OTC purchases
     * @param _d is the index of the deal that a buyer wants to participate in and make a purchase
     * @param _amount is the amount of tokens the buyer is willing to purchase, which must be at least the minimumPurchase and at most the remainingAmount for this deal
     * @notice ensure when using this function that you are aware of the minimums, and price per token to ensure sufficient balances to make a purchase
     * @notice if the deal has an unlockDate that is beyond the current block time - no tokens will be received by the buyer, but rather they will receive
     * @notice an NFT, which represents their ability to redeem and claim the locked tokens after the unlockDate has passed
     * @notice the NFT received is a separate smart contract, which also contains the locked tokens
     * @notice the Seller will receive payment in full immediately when triggering this function, there is no lock on payments
    */
    function buy(uint _d, uint _amount) payable external nonReentrant {
        /// @dev pull the deal details from storage
        Deal storage deal = deals[_d];
        /// @dev we do not let the seller sell to themselves, must be a separate buyer
        require(msg.sender != deal.seller, "HEC07: Buyer cannot be seller");
        /// @dev require that the deal order is still valid by checking the open bool, as well as the maturity of the deal being in the future block time
        require(deal.open && deal.maturity >= block.timestamp, "HEC06: Deal has been closed");
        /// @dev if the deal had a whitelist - then require the msg.sender to be that buyer, otherwise if there was no whitelist, anyone can buy
        require(msg.sender == deal.buyer || deal.buyer == address(0x0), "HEC08: Whitelist or buyer allowance error");
        /// @dev require that the amount being purchased is greater than the deal minimum, or that the amount being purchased is the entire remainder of whats left
        /// @dev AND require that the remaining amount in the deal actually equals or exceeds what the buyer wants to purchase
        require((_amount >= deal.minimumPurchase || _amount == deal.remainingAmount) && deal.remainingAmount >= _amount, "HEC09: Insufficient Purchase Size");
        /// @dev we calculate the purchase amount taking the decimals from the token first
        /// @dev then multiply the amount by the per token price, and now to get back to an amount denominated in the payment currency divide by the factor of token decimals 
        uint decimals = Decimals(deal.token).decimals();
        uint purchase = (_amount * deal.price) / (10 ** decimals);
        /// @dev check to ensure the buyer actually has enough money to make the purchase
        uint balanceCheck = (deal.paymentCurrency == weth) ? msg.value : IERC20(deal.paymentCurrency).balanceOf(msg.sender);
        require(balanceCheck >= purchase, "HECB: Insufficient Balance");
        /// @dev transfer the purchase to the deal seller
        _transferPymt(deal.paymentCurrency, msg.sender, payable(deal.seller), purchase);
        if (deal.unlockDate > block.timestamp) {
            /// @dev if the unlockdate is the in future, then we call our internal function lockTokens to lock those in the NFT contract
            _lockTokens(payable(msg.sender), deal.token, _amount, deal.unlockDate);
        } else {
            /// @dev if the unlockDate is in the past or now - then tokens are already unlocked and delivered directly to the buyer
            _withdraw(deal.token, payable(msg.sender), _amount);
        }
        /// @dev reduce the deal remaining amount by how much was purchased. If the remainder is 0, then we consider this deal closed and set our open bool to false
        deal.remainingAmount -= _amount;
        if (deal.remainingAmount == 0) deal.open = false;
        emit TokensBought(_d, _amount, deal.remainingAmount);
    }

    /// @dev internal function that handles the locking of the tokens in the NFT Futures contract
    /// @dev because this OTC contract is the owner of the NFT contract - it is able to call the function that safely mints an NFT
    /// @param _owner address here becomes the owner of the NFT
    /// @param _token address here is the asset that is locked in the NFT Future
    /// @param _amount is the amount of tokens that will be locked
    /// @param _unlockDate provides the unlock date which is the expiration date for the Future generated
    function _lockTokens(address payable _owner, address _token, uint _amount, uint _unlockDate) internal {
        require(_unlockDate > block.timestamp, "HEC10: Unlocked");
        /// @dev similar to checking the balances for the OTC contract when creating a new deal - we check the current and post balance in the NFT contract
        /// @dev to ensure that 100% of the amount of tokens to be locked are in fact locked in the contract address
        uint currentBalance = IERC20(_token).balanceOf(futureContract);
        /// @dev increase allowance so that the NFT contract can pull the total funds 
        /// @dev this is a safer way to ensure that the entire amount is delivered to the NFT contract
        SafeERC20.safeIncreaseAllowance(IERC20(_token), futureContract, _amount);
        /// @dev this function points to the NFT Futures contract and calls its function to mint an NFT and generate the locked tokens future struct
        IFuturesNFT(futureContract).createNFT(_owner, _amount, _token, _unlockDate);
        /// @dev check to make sure that what is received by the futures contract equals the total amount we have delivered
        /// @dev this prevents functionality with deflationary or tax tokens that have not whitelisted these address 
        uint postBalance = IERC20(_token).balanceOf(futureContract);
        assert(postBalance - currentBalance == _amount);
        emit FutureCreated(_owner, _token, _unlockDate, _amount);

    }

    
    /// @dev events for each function
    event NewDeal(uint _d, address _seller, address _token, address _paymentCurrency, uint _remainingAmount, uint _minimumPurchase, uint _price, uint _maturity, uint _unlockDate, bool open, address _buyer);
    event TokensBought(uint _d, uint _amount, uint _remainingAmount);
    event DealClosed(uint _d);
    event FutureCreated(address _owner, address _token, uint _unlockDate, uint _amount);
    
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}