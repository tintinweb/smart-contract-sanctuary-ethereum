import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Presale is Ownable, Pausable, ReentrancyGuard {
    /* ======== EVENTS ======== */

    event TokenAddress(address tokenAddress);
    event TokenGenerationEvent(uint256 TGE);
    event AvailableTokens(uint256 availableTokens);
    event PricePerToken(uint256 pricePerToken);
    event TotalClaimed(uint256 totalClaimed);
    event DeployedOnBlock(uint256 deployedOnBlock);
    event TokensSold(uint256 tokensSold);
    event MaxTokensPerWallet(uint256 maxTokensPerWallet);
    event BlockWaitForClaim(uint256 blockWaitForClaim);
    event ClaimedTokens(address user, uint256 amount);
    event BoughtTokens(address user, uint256 amountToPay, uint256 amountToReceive);
    event WithdrawTokens(address user, uint256 amount);
    event PurchaseDisabled(bool purchaseDisabled);
    event ClaimDisabled(bool claimDisabled);
    event MinPurchasePerTransaction(uint256 amount);
    event MaxQuantityPerTransaction(uint256 amount);
    event MaxClaimPerBlockWait(uint256 maxClaimPerBlockWait);
    event Treasury(address treasury);
    event EmergencyUpdateWallet(
        address user,
        uint256 hasClaimedInTotal,
        uint256 tokensBought
    );
    event UpdateReferral(string artist, uint256 amountInWei, bool disabled);
    event UpdatePayment(address token, uint8 tokenDecimal, uint256 pricePerToken, bool disabled);

    /* ======== VARS ======== */

    address public tokenAddress; // The token address the user claims
    address public treasury; // The treasury address

    uint256 public deployedOnBlock; // The block number the contract has been deployed on
    uint256 public TGE; // The first claim in x % for TGE
    uint256 public blockWaitForClaim; // Users have to wait x days before claim opens again
    uint256 public maxClaimPerBlockWait; // After TGE users can claim only a max of x %
    uint256 public totalClaimed = 0; // Total tokens that has been claimed
    uint256 public maxPurchasePerTx = 1000000; // The max tokens per tx
    uint256 public maxTokensPerWallet = 1000000 ether; // the max tokens per wallet
    uint256 public availableTokens; // Max tokens to sell
    uint256 public tokensSold = 0; // The amount of tokens already sold

    bool public purchaseDisabled = false; // enable and disable purchase
    bool public claimDisabled = false; // enable and disable claim

    /* ======== STRUCTS ======== */

    struct Presaler {
        uint256 tokensBought; // How many tokens the user has bought
        uint256 hasClaimedInTotal; // How many tokens the user has claimed already
    }

    struct Referral {
        string name; // The name of the artist
        uint256 amount; // The amount of tokens that has been bought with the referral link
        bool disabled; // Enable or disable the referall link
    }

    struct Payment {
        address token; // The address of the token
        uint8 tokenDecimal; // The token decimal
        uint256 pricePerToken; // the price for 1 token
        bool disabled; // Is the token disabled or enabled
    }

    /* ======== MAPPINGS ======== */

    mapping(address => Presaler) public presaler;
    mapping(address => Payment) public payment;
    mapping(string => Referral) public referral;

    /* ======== CONSTRUCTOR ======== */

    constructor(
        uint256 _TGE,
        uint256 _blockWaitForClaim,
        uint256 _maxClaimPerBlockWait,
        uint256 _availableTokens
    ) {
        setTokenGenerationEventAward(_TGE);
        setBlockWaitForClaim(_blockWaitForClaim);
        setMaxClaimPerBlockWait(_maxClaimPerBlockWait);
        setAvailableTokens(_availableTokens);
    }

    /* ======== MODIFIERS ======== */

    /**
     * @dev Throws if called by any account other than the treasury.
     */
    modifier onlyTreasury() {
        require(treasury == _msgSender(), "caller is not the treasury");
        _;
    }

    /**
     * @dev Throws if purchaseDisabled is disabled
     */
    modifier whenPurchaseNotDisabled() {
        require(!purchaseDisabled, "Purchase has been disabled");
        _;
    }

    /**
     * @dev Throws if purchaseDisabled is disabled
     */
    modifier whenClaimNotDisabled() {
        require(!claimDisabled, "Claim has been disabled");
        _;
    }

    /* ======== OWNER ONLY ======== */

    /**
     * @dev sets the new token address for users to claim.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
        emit TokenAddress(_tokenAddress);
    }

    /**
     * @dev sets the new token address for users to claim.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setPurchaseDisabled(bool _purchaseDisabled) public onlyOwner {
        purchaseDisabled = _purchaseDisabled;
        emit PurchaseDisabled(_purchaseDisabled);
    }

    /**
     * @dev sets the new token address for users to claim.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setClaimDisabled(bool _claimDisabled) public onlyOwner {
        claimDisabled = _claimDisabled;
        emit ClaimDisabled(_claimDisabled);
    }

    /**
     * @dev sets the new percentage of max claim the user can do after `blockWaitForClaim` has passed
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setMaxClaimPerBlockWait(uint256 _maxClaimPerBlockWait)
        public
        onlyOwner
    {
        maxClaimPerBlockWait = _maxClaimPerBlockWait;
        emit MaxClaimPerBlockWait(_maxClaimPerBlockWait);
    }

    /**
     * @dev sets the new TGE claim percentage
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setTokenGenerationEventAward(uint256 _TGE) public onlyOwner {
        TGE = _TGE;
        emit TokenGenerationEvent(_TGE);
    }

    /**
     * @dev the amount of blocks the users needs to wait before the new claim can happen.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setBlockWaitForClaim(uint256 _blockWaitForClaim) public onlyOwner {
        blockWaitForClaim = _blockWaitForClaim;
        emit BlockWaitForClaim(_blockWaitForClaim);
    }

    /**
     * @dev The max tokens per transaction that can be bought
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setMaxPurchasePerTx(uint256 _maxPurchasePerTx) public onlyOwner {
        maxPurchasePerTx = _maxPurchasePerTx;
        emit MaxQuantityPerTransaction(_maxPurchasePerTx);
    }

    /**
     * @dev Sets the new treasury address
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
        emit Treasury(_treasury);
    }

    /**
     * @dev The max amount of tokens a wallet can hold
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setMaxTokensPerWallet(uint256 _maxTokensPerWallet)
        public
        onlyOwner
    {
        maxTokensPerWallet = _maxTokensPerWallet;
        emit MaxTokensPerWallet(_maxTokensPerWallet);
    }

    /**
     * @dev Sets the deployed block number.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setDeployedOnBlock(uint256 _deployedOnBlock) public onlyOwner {
        deployedOnBlock = _deployedOnBlock;
        emit DeployedOnBlock(_deployedOnBlock);
    }

    /**
     * @dev Sets the available tokens for sell in the pre-sale
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setAvailableTokens(uint256 _availableTokens) public onlyOwner {
        availableTokens = _availableTokens;
        emit AvailableTokens(_availableTokens);
    }

    /**
     * @dev Add a referral link
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setReferral(
        string memory _artist,
        uint256 _amountInWei,
        bool _disabled
    ) public onlyOwner {
        referral[_artist] = Referral({
            name: _artist,
            amount: _amountInWei,
            disabled: _disabled
        });
        emit UpdateReferral(_artist, _amountInWei, _disabled);
    }

      /**
     * @dev Add a new payment
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setPayment(
        address _token,
        uint8 _tokenDecimal,
        uint256 _pricePerToken,
        bool _disabled
    ) public onlyOwner {
        payment[_token] = Payment({
            token: _token,
            tokenDecimal: _tokenDecimal,
            pricePerToken: _pricePerToken,
            disabled: _disabled
        });
        emit UpdatePayment(_token, _tokenDecimal, _pricePerToken, _disabled);
    }

    /**
     * @dev in case there is a bug where the presaler has wrong stats, we can set it to the correct numbers. Emergency ONLY
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setEmergencyPresalerClaimStats(
        address _user,
        uint256 _hasClaimedInTotal,
        uint256 _tokensBought
    ) public onlyOwner {
        presaler[_user] = Presaler({
            hasClaimedInTotal: _hasClaimedInTotal,
            tokensBought: _tokensBought
        });
        emit EmergencyUpdateWallet(_user, _hasClaimedInTotal, _tokensBought);
    }

    /**
     * @dev in case there is a bug where the total claimed is not right anymore, we can set it back to the correct number. Emergency ONLY
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setEmergencyTotalClaimed(uint256 _totalClaimed) public onlyOwner {
        totalClaimed = _totalClaimed;
        emit TotalClaimed(_totalClaimed);
    }

    /**
     * @dev in case there is a bug where the tokens sold is not right anymore, we can set it back to the correct number. Emergency ONLY
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
    function setEmergencyTokensSold(uint256 _tokensSold) public onlyOwner {
        tokensSold = _tokensSold;
        emit TokensSold(_tokensSold);
    }

    /**
     * @dev See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     * - The contract must not be paused.
     */
    function pause() public onlyOwner whenNotPaused {
        super._pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     * - The contract must be paused.
     */
    function unpause() public onlyOwner whenPaused {
        super._unpause();
    }

    /**
     * @dev Withdraw the tokens in the contract if there is leftovers
     *
     * Requirements:
     *
     * - Only the owner can call this function
     * - The contract must be paused.
     * - See {ReentrancyGuard-nonReentrant}
     */
    function withdrawTokens() public whenPaused nonReentrant onlyOwner {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) > 0,
            "Their is no tokens to withdraw"
        );
        IERC20(tokenAddress).approve(
            address(this),
            IERC20(tokenAddress).balanceOf(address(this))
        );
        IERC20(tokenAddress).transfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );

        emit WithdrawTokens(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    /**
     * @dev Withdraw the ETH from the contract
     *
     * Requirements:
     *
     * - Only the owner can call this function
     * - See {ReentrancyGuard-nonReentrant}
     */
    function withdrawEth() external onlyTreasury nonReentrant {
        payable(address(treasury)).transfer(address(this).balance);
    }

    /* ======== PUBLIC ======== */

    /**
     * @dev Returns the token amount based on the rewardTokenCount and the rate
     */
    function getTokenAmount(uint256 _amount, Payment memory paymentCurrency) public pure returns (uint256, uint256) {
        uint256 amountToPay = _amount * paymentCurrency.pricePerToken;
        uint256 amountToReceive = _amount * (10 ** 18);
        return (amountToPay, amountToReceive);
    }

    /**
     * @dev Returns the claimable amount for a wallet
     */
    function getClaimable(address _buyer)
        public
        view
        returns (uint256, uint256)
    {
        Presaler memory user = presaler[_buyer];
        uint256 hasClaimedInTotal = 0;
        uint256 totalClaim = user.tokensBought;

        // calculate TGE
        hasClaimedInTotal += (totalClaim * TGE) / 100;
        
        // calculate claim amount over periods
        uint256 periodsToClaim = (block.number - deployedOnBlock) / blockWaitForClaim;
        hasClaimedInTotal += (totalClaim * (maxClaimPerBlockWait * periodsToClaim)) / 100;

        if (hasClaimedInTotal > totalClaim) {
            hasClaimedInTotal = totalClaim;
        }

        // substract amount already claimed
        uint256 claimableAmount = hasClaimedInTotal - user.hasClaimedInTotal;
        return (claimableAmount, hasClaimedInTotal);
    }

    /**
     * @dev Buy presale tokens
     *
     * Requirements:
     *
     * - Paused must be `false`
     * - `purchaseDisabled` must be `false`
     */
    function buyTokens(address _tokenAddress, uint256 _amount)
        public
        payable
        whenNotPaused
        whenPurchaseNotDisabled
    {
        require((availableTokens - _amount) >= 0, "Reached max tokens");

        Payment memory paymentCurrency = payment[_tokenAddress];

        require(address(0) != paymentCurrency.token, "Payment address does not exists");
        require(!paymentCurrency.disabled, "Payment is disabled");
        require(_amount > 0, "Amount must be higher than 0");

        (uint256 amountToPay, uint256 amountToReceive) = getTokenAmount(_amount, paymentCurrency);
        require(amountToPay > 0, "Amount to pay must be higher than 0");
        require(amountToReceive > 0, "Amount to receive must be higher than 0");

        require(_amount <= maxPurchasePerTx, "Must purchase below or equal to `maxPurchasePerTx`");
        require(IERC20(paymentCurrency.token).balanceOf(_msgSender()) >= amountToPay, "Not enough balance");

        Presaler memory user = presaler[_msgSender()];
        uint256 totalTokensBought = user.tokensBought + amountToReceive;
        require(totalTokensBought <= maxTokensPerWallet, "Reached max tokens per wallet");

        presaler[_msgSender()].tokensBought = totalTokensBought;

        tokensSold = tokensSold + _amount;
        availableTokens = availableTokens - _amount;

        IERC20(paymentCurrency.token).transferFrom(_msgSender(), treasury, amountToPay);
        emit BoughtTokens(_msgSender(), amountToPay, amountToReceive);
    }

    /**
     * @dev Buy presale tokens with a valid referral code
     *
     * Requirements:
     *
     * - Paused must be `false`
     * - `purchaseDisabled` must be `false`
     */
    function buyTokensWithReferral(string memory _artist, address _tokenAddress, uint256 _amount)
        public
        payable
        whenNotPaused
        whenPurchaseNotDisabled
    {
        Referral memory ref = referral[_artist];
        require(bytes(ref.name).length > 0, "Referral link is invalid");
        require(!ref.disabled, "Referral link is disabled");

        buyTokens(_tokenAddress, _amount);

        Payment memory paymentCurrency = payment[_tokenAddress];
        (,uint256 amountToReceive) = getTokenAmount(_amount, paymentCurrency);
        referral[_artist].amount += amountToReceive;
    }

    /**
     * @dev Claim tokens periodically
     *
     * Requirements:
     *
     * - Paused must be `false`
     * - See {ReentrancyGuard-nonReentrant}
     */
    function claim() public whenNotPaused whenClaimNotDisabled nonReentrant {
        Presaler memory user = presaler[_msgSender()];
        require(deployedOnBlock > 0, "deployedOnBlock must be higher than 0");
        require(user.tokensBought > 0, "No tokens bought to claim");
        require(user.hasClaimedInTotal < user.tokensBought, "Already claimed total");
        require(IERC20(tokenAddress).balanceOf(address(this)) > 0, "No tokens left");

        (uint256 claimableAmount, uint256 hasClaimedInTotal) = getClaimable( _msgSender() );

        require(claimableAmount > 0, "Nothing to claim");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= claimableAmount, "No tokens left");

        presaler[_msgSender()].hasClaimedInTotal = hasClaimedInTotal;
        totalClaimed += claimableAmount;

        // send amount to claim
        IERC20(tokenAddress).approve(address(this), claimableAmount);
        IERC20(tokenAddress).transferFrom(address(this), _msgSender(), claimableAmount);
        emit ClaimedTokens(_msgSender(), claimableAmount);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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