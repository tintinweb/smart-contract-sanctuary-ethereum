// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity ^0.8.17;
interface VaultInterface {
    // Events
    event Minted(address indexed minter, uint256 amount);
    event CTM_Supplied(address indexed depositer, uint256 amount, uint256 timestamp);
    event CtmPurchased(
        address indexed purchaser,
        uint256 usdcAmount,
        uint256 cmtAllotedAmount
    );
    event TokenWithdraw(address indexed user, bytes32 token, uint256 payment);
    function setPaymentToken(address token) external;
    function buyCTM(address _user, uint256 _usdcAmount, uint256 _ctmAmount) external;
    function refund(address _buyer, uint256 _amount, uint256 _ctmAdjustment) external;
    function withdraw(address _user, uint256 _amount, uint256 _usdcAdjustment) external;
    function penalty() external returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/// @dev - Inherited contracts for security and token compliancy
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/VaultInterface.sol";

/** 
    @title Swap smart contract for the BRX exchange
    @author The Cointinuum Development Team
    @notice CTM token to be swapped for USDC
    @notice CTM token supply with specific price to be provided (tranches)
    @notice CTM tranche 0 - 10,000,000 @ $0.45
    @notice CTM tranche 1 - 12,000,000 @ $1.41
    @notice CTM tranche 2 - 16,000,000 @ $4.43
    @dev number of decimals for price variable is 2 (price in cents)
    @dev interface to vault, call buyCTM
*/

interface IERC20Extended is IERC20{
    function decimals() external view returns(uint8);
}

contract Swap is Ownable {
    IERC20Extended public USDCtoken;
    IERC20Extended public CTMtoken;
    VaultInterface public Vault;
    
/**
    @notice Tokens to be supplied in tranches
    @dev Define the tranches
    @dev Define the current state of the tranche
    @dev Tranches are currently set up in test, should put in a config file
*/

event MadeDeposit (address indexed customer, uint256 CTMqty, uint256 USDCqty, uint16 tranche);

enum TrancheState {
    paused,
    active,
    completed,
    deleted
}
    // @notice Struct for defining a tranche
    struct tranche {
        uint256 totalTokens;
        uint256 numberOfTokensAvailable;
    
        // @dev price denominated in USD (2 decimals)
        uint256 lockDuration;
        uint16 price;
        TrancheState state; 
    }

    // @notice Struct for refunds
    struct refundXaction {
        uint256 CTMtokens;
        uint256 USDCtokens;
        uint256 XactionTime;
        uint16 depositID; /// @dev index of depositXaction, for customer to find deposit (ID)
    }

    // @notice Struct for deposits
    struct depositXaction {
        uint256 CTMtokens;
        uint256 USDCtokens;
        uint256 XactionTime;
        uint256 lockDuration;
        uint16 price;
        uint16 tranche;
        bool refunded;
        bool claimed;
    }

    // @notice Mappings for deposits, refunds, checks and balances
    uint256 public maxCTMAllowed;
    uint32 public minPurchase;
    mapping(address => uint256) public totalCTMPurchased; 
    mapping(address => refundXaction[]) public RefundRecord;
    mapping(address => depositXaction[]) public DepositRecord;
    mapping(address => mapping(uint256 => bool)) public refundApprovals; /// @dev How to make this more storage efficient?
    mapping(address => bool) public whitelist;
    mapping(uint16 => uint256) public maxPerTranche;

    uint16 constant penaltyScale = 10000;

    // @notice tracks the total returned CTM
    uint256 public returnedCTM;
    // @notice tracks the total settled USDC
    uint256 public settledUSDC;

    // @notice Array of tranches 
    tranche[] public tranches;

    function unsafe_increment(uint256 x) private pure returns (uint256) {
        unchecked {return x + 1;}
    }

    function unsafe_increment16(uint16 x) private pure returns (uint16) {
        unchecked {return x + 1;}
    }

/// @param trancheNumber - One based numbering of tranches as added
/// @param max - Max number of CTM tokens allowed per user to be purchased in a tranche
    function setMaxPerTranche (uint16 trancheNumber, uint256 max) public onlyOwner {
        require(trancheNumber > 0, "cannot set max per tranche for tranche 0");
        require(tranches.length > (trancheNumber), "cannot set max per tranche for tranche not added");
        maxPerTranche[trancheNumber] = max;
    }

/// @param  total - Maximum CTM for sale in this tranche
/// @param  available - Number of CTM remaining to be sold in this tranche
/// @param  price - Price denominated in USD for the CTM in this tranche
    function addTranche (uint256 total, uint256 available, uint256 lockDuration, uint16 price) public onlyOwner returns (uint256) {
        require (total >= available, "total tokens in tranche must be >= available tokens");
        require (price >= 10, "price of tokens in tranche must be >= $0.10");
        tranches.push(tranche(total, available, lockDuration, price, TrancheState.paused));
        return (tranches.length);
    }

/// @param trancheNumber - Zero based numbering of tranches as added
/// @param newstate - State to set the tranche (paused, active, etc) see TrancheState enum
    function changeTrancheState (uint16 trancheNumber, TrancheState newstate) public onlyOwner {
        require(trancheNumber > 0, "cannot change state of tranche 0");
        require(tranches.length > (trancheNumber),"cannot change state of tranche not added");
        tranches[trancheNumber].state = newstate;
    }

/// @notice setMinPurchase - set the minimum purchase amount in USDC
/// @param _minPurchase - minimum purchase amount in USDC
    function setMinPurchase (uint32 _minPurchase) public onlyOwner {
        minPurchase = _minPurchase;
    }

/// @notice getTrancheTotalTokens - returns totalTokens for specified tranche
/// @param trancheNumber - Zero based numbering of tranches as added
    function getTrancheTotalTokens(uint16 trancheNumber) public view returns (uint256) {
        tranche[] memory _tranches = tranches;
        require(trancheNumber > 0);
        require(_tranches.length > (trancheNumber), "cannot get total tokens, tranche does not exist");
        return (_tranches[trancheNumber].totalTokens);
    }

/// @notice getTrancheAvailableTokens - returns availableTokens for specified tranche
/// @param trancheNumber - Zero based numbering of tranches as added
    function getTrancheAvailableTokens(uint16 trancheNumber) public view returns (uint256) {
        require(trancheNumber > 0);
        require(tranches.length > (trancheNumber), "cannot get available tokens, tranche does not exist");
        return (tranches[trancheNumber].numberOfTokensAvailable);
    }



/// @notice getTranchesParams - Returns all the tranche params
/// @param trancheNumber - Zero based numbering of tranches as added
    function getTrancheParams (uint16 trancheNumber) public view returns (uint256, uint256, uint16, TrancheState) {
        require((tranches.length > trancheNumber),"cannot get tranche params, tranche does not exist");
        return (
            tranches[trancheNumber].totalTokens,
            tranches[trancheNumber].numberOfTokensAvailable,
            tranches[trancheNumber].price,
            tranches[trancheNumber].state
        );
    }

/// @notice getXactionCount - Get number of transaction purchases for account 
/// @param account - Address of account of interest

//    function getXactionCount (address account) public view returns (uint16) {
//        DepositRecord[account].depositXaction.length;
//        return 1;
//    }

/// @notice getDepXactions - Returns array of xactions for account
/// @param account - Address to receive deposit record for
    function getDepXactions (address account) public view returns (depositXaction[] memory) {
        return DepositRecord[account];
    }

/// @notice getRefXactions - Returns array of xactions for account
/// @param account - Address to receive refund record for
    function getRefXactions (address account) public view returns (refundXaction[] memory) {
        return RefundRecord[account];
    }

/// @notice CSwap - sends payment and CTM to vault
/// @param USDCqty (dollar amount of CTM to purchase)
    function CSwap (uint16 trancheNumber, uint256 USDCqty ) public whitelisted(msg.sender) {
        require((tranches.length > trancheNumber),"No tranche with this number");
        require(tranches[trancheNumber].state == TrancheState.active,"Tranche is not active");
        uint256 CTMqty = CSwapQty(trancheNumber, USDCqty);
        if (maxPerTranche[trancheNumber] > 0) {
            require(CTMqty <= maxPerTranche[trancheNumber],"Purchase is greater than max allowed per this tranche");
            if (DepositRecord[msg.sender].length > 0) {
                uint256 totalPurchased = 0;
                for (uint16 i = 0; i < DepositRecord[msg.sender].length; i++) {
                    if (DepositRecord[msg.sender][i].tranche == trancheNumber) {
                        totalPurchased += DepositRecord[msg.sender][i].CTMtokens;
                    }
                }
                require ((totalPurchased + CTMqty) <= maxPerTranche[trancheNumber], "Purchase will cause max allowed CTM to be exceeded");
            }
        }
        require (CTMqty <= tranches[trancheNumber].numberOfTokensAvailable,"Not that many CTM available in this tranche");
        tranches[trancheNumber].numberOfTokensAvailable -= CTMqty;
        require ((totalCTMPurchased[msg.sender] + CTMqty) <= maxCTMAllowed, "Purchase will cause max allowed CTM to be exceeded");
        require (USDCqty >= minPurchase, "Mininum purchase amount not met");

        /// @dev setting purchase info in database
        makeDeposit(CTMqty, USDCqty, trancheNumber);
        emit MadeDeposit(msg.sender, CTMqty, USDCqty, trancheNumber);

        /// @dev Tracks the total CTM purchased per address
        totalCTMPurchased[msg.sender] += CTMqty;

        /// @dev Tracks the settled USDC
        settledUSDC += (USDCqty * Vault.penalty() / penaltyScale);

        Vault.buyCTM(msg.sender, USDCqty, CTMqty);
    }

/// @notice - CSwapQty - compute CTM to allocate for purchaser
/// @param - trancheNumber
/// @param - USDCqty 
// returns qty CTM to purchase
    function CSwapQty (uint16 trancheNumber, uint256 USDCqty ) public view returns (uint256) {
        tranche[] memory _tranches = tranches;
        require(_tranches.length > trancheNumber,"No tranche at that address");
        uint256 price = _tranches[trancheNumber].price;
        uint256 qty = (USDCqty * (10**CTMtoken.decimals())* 100) /((10**USDCtoken.decimals()) * price);
        return (qty);    
    }
/// @notice - Deposit to a tranche
    function makeDeposit (uint CTMq, uint USDCq, uint16 trancheNumber) private {
        tranche[] memory _tranches = tranches;
        depositXaction memory dX= depositXaction(
            CTMq,
            USDCq,
            block.timestamp,
            _tranches[trancheNumber].lockDuration,
            _tranches[trancheNumber].price,
            trancheNumber,
            false,
            false);
        DepositRecord[msg.sender].push(dX);
    }

/// @notice - Allows owner to approve a users refund request for a specified deposit transaction
/// @param _user - Address requesting for refund approval
/// @param xactionIndex - Index of the address's deposit transactions to recieve refund approval
    function approveRefund(address _user, uint16 xactionIndex) external onlyOwner {
        require(xactionIndex < DepositRecord[_user].length, "xactionIndex must be valid in DepositRecord[_user]");
        refundApprovals[_user][xactionIndex] = true;
    }

/// @notice - Allows users to receive penalized refund of USDC from a specified deposit transaction if approved by owner and logs refund transaction
/// @param xactionIndex - index of specific transaction in msg.senders deposit transactions
    function refundPayment(uint16 xactionIndex) public {
        require(refundApprovals[msg.sender][xactionIndex] == true, "Refund is not approved, or does not exist, please contact support");

        /// @dev - Using local memory dX to reduce gas
        depositXaction memory dX;
        dX = DepositRecord[msg.sender][xactionIndex];
        require(!dX.refunded, "Transaction was previously refunded");
        require(!dX.claimed, "Transaction was previously claimed");

        /// @notice - Calculates the penaltyAmount
        uint256 penaltyAmount = dX.USDCtokens * Vault.penalty() / penaltyScale; /// @dev replace '2000' in calc with call to read vault's penalty variable
        /// @dev - Set refund amount, full refund of transaction USDC (less 20%)
        uint256 refundAmount = dX.USDCtokens - penaltyAmount;
        /// @dev - Pass in CTM token amount to be deducted from users balance
        uint256 ctmAdjustment = dX.CTMtokens;

        /// @notice - Flag deposit as refunded
        DepositRecord[msg.sender][xactionIndex].refunded = true;
        /// @notice - Put the tokens back in the tranche
        tranches[dX.tranche].numberOfTokensAvailable += ctmAdjustment;
        /// @notice - Add refund to the refund record
        refundXaction memory rX = refundXaction(ctmAdjustment, refundAmount, block.timestamp, xactionIndex);
        RefundRecord[msg.sender].push(rX);

        /// @notice - Tracks the returned CTM
        returnedCTM += ctmAdjustment;

        /// @notice - Makes the refund to user
        Vault.refund(msg.sender, refundAmount, ctmAdjustment);

        //emit madeRefund(msg.sender, ctmAdjustment, USDCamount);
    }

/// @notice - Allows user to withdraw purchased CTM tokens for a specified deposit transaction if holding period has elapsed
/// @param xactionIndex - index of specific transaction in msg.senders deposit transactions 
    function claimCTM(uint16 xactionIndex) public {
        /// @dev - Uses local memory dXarray to reduce gas
        depositXaction[] memory dXarray;
        dXarray = getDepXactions(msg.sender);
        require(dXarray.length > xactionIndex, "Transaction does not exist");
        /// @dev - Uses local memory dX to reduce gas
        depositXaction memory dX;
        dX = dXarray[xactionIndex];
        delete dXarray;
        require(!dX.refunded, "Transaction was previously refunded");
        require(!dX.claimed, "Transaction was previously claimed");
        require((dX.XactionTime + dX.lockDuration) <= block.timestamp, "Tokens cannot be claimed until end of holding period");
        
        uint256 usdcAdjustment = dX.USDCtokens * (penaltyScale - Vault.penalty()) / penaltyScale;

        /// @notice - Flag deposit as claimed
        DepositRecord[msg.sender][xactionIndex].claimed = true;
        /// @notice - Tracks the settled USDC
        settledUSDC += usdcAdjustment;
        /// @notice - Send tokens to the user (withdrawn)
        Vault.withdraw(msg.sender, dX.CTMtokens, usdcAdjustment);
    }

/// @notice - Allows owner to update vault contract address
/// @param _address - new vault contract address
    function setVaultAddress (address _address) onlyOwner public {
        Vault = VaultInterface(_address);
    }

/// @notice - Allows owner to update USDC contract address
/// @param _address - new USDC contract address
    function setUSDCAddress (address _address) public onlyOwner {
        USDCtoken = IERC20Extended(_address);
    }

/// @notice - Allows owner to update CTM contract address
/// @param _address - new CTM contract address
    function setCTMAddress (address _address) public onlyOwner {
        CTMtoken = IERC20Extended(_address);
    }

/// @notice - Allows owner to update max CTM allowed to be purchased per address
/// @param _amount - new CTM contract address
    function setMaxCTMAllowed (uint256 _amount) public onlyOwner {
        maxCTMAllowed = _amount;
    }

    constructor () {
        /// @dev - Add an empty tranche at index zero, so we can use 1 based indexing
        addTranche (0, 0, 0, 1000);      
        maxCTMAllowed = 1000000 * 10**18; // default to 1 million CTM
        minPurchase = 500 * 10**6; // 500 USDC
    }

/// @notice - AddWhitelist modifications currently restricted to owner 
/// @param accounts array of account addresses to be added to whitelist
    function addWhitelist (address[] memory accounts) external onlyOwner {
        for(uint i=0; i<accounts.length; i = unsafe_increment(i)){
            whitelist[accounts[i]] = true;
        }
    }
/// @notice - RemoveWhitelist modifications currently restricted to owner 
/// @param accounts - array of account addresses to be removed from whitelist
    function removeWhitelist (address[] memory accounts) external onlyOwner {
        for(uint i=0; i<accounts.length; i = unsafe_increment(i)){
            whitelist[accounts[i]] = false;
        }
    }

/// @param account - Account address to be check if whitelisted
    modifier whitelisted(address account) {
        require (whitelist[account] == true, "Account not whitelisted, start KYC process or contact support");
        _;
    }

    address[] public whitelistRequests;

/** 
    @notice - requestWhitelist(address memory accounts) - request to be added to whitelist
    @param accounts - address of account requesting to be added to whitelist
    @dev - Using array to store requests, as it is easier to enumerate and delete items
    @dev - Using uint16 for array index, as it is cheaper than uint256
    @dev - This array should never get too big, as it is only used for KYC requests
    @dev - This function is a good candidate for gas optimization
*/

    function requestWhitelist (address[] memory accounts) external {
    // require (whitelist[account] == false, "Account already whitelisted");
        uint16 i;
        uint16 j;
        bool found = false;
        address[] memory _whitelistRequests = whitelistRequests;
        for (i=0; i<accounts.length; i = unsafe_increment16(i)) {
            for (j=0; j<_whitelistRequests.length; j = unsafe_increment16(j)) {
                if (_whitelistRequests[j] == accounts[i]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                whitelistRequests.push(accounts[i]);
            }
            found = false;
        }
    }

/// @notice - Returns entire array of addresses requesting whitelist
    function returnWhitelistRequests() external view returns (address[] memory) {
        return (whitelistRequests);
    }

/// @notice - AddRequestedWhitelist modifications currently restricted to owner 
/// @param accounts - array of addresses to be added to whitelist
    function addRequestedWhitelist (address[] memory accounts) external onlyOwner {
        deleteWhitelistRequest(accounts);
        for (uint16 i=0; i<accounts.length; i = unsafe_increment16(i)) {
            whitelist[accounts[i]] = true;
        }
    }

/// @dev If the address is in the array, delete it, else do nothing
/// @dev - This function is a good candidate for gas optimization
    function deleteWhitelistRequest (address[] memory accounts) public onlyOwner {
        address[] memory _whitelistRequests = whitelistRequests;
        for(uint16 i=0; i<accounts.length; i = unsafe_increment16(i)) {
            for (uint16 j=0; j<whitelistRequests.length; j = unsafe_increment16(j)) {
                if (_whitelistRequests[j] == accounts[i]) {
                    whitelistRequests[j] = _whitelistRequests[_whitelistRequests.length-1];
                    whitelistRequests.pop();
                    break;
                }
            }
        }
    }

    receive() external payable {}

    fallback() external payable {}

/// @notice withdrawETH() Withdraw all ETH from the contract
    function withdrawETH () public onlyOwner {
        require(address(this).balance > 0, "There is no ETH in the contract");
        payable (msg.sender).transfer(address(this).balance);
    }

/// @notice Allows owner to withdraw tokens mistakenly sent to contract
/// @param _tokenContract - address of token to be withdrawn
    function withdrawToken(address _tokenContract) public onlyOwner{
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 amount = tokenContract.balanceOf(address(this));
        require(amount > 0, "No tokens with that contract address to withdraw");
        require(tokenContract.transfer(msg.sender, amount),"failed withdrawing ERC20 tokens");
    }
}