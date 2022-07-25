/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


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

contract BridgeEth is Ownable, ReentrancyGuard {
    uint256 public nonce;
    uint256 minimumUSD = 10 * 10 ** 18;
    uint256 public feeReleaseThreshold = 0.1 ether;
    mapping(IERC20 => TokenConfig) private _tokenConfig;
    mapping(IERC20 => mapping(address => uint256)) private _balances;
    mapping(uint256 => bool) private _processedNonces;
    IERC20 private _sokuToken;
    IERC20 private _sutekuToken;
    IERC20 private _hobiToken;
    bool public paused = false;
    address payable private _unlocker_bot;
    address private _pauser_bot;
    uint256 constant private DAILY_TRANSFER_INTERVAL_ONE_DAY = 86400;
    uint256 private _dailyTransferNextTimestamp = block.timestamp + DAILY_TRANSFER_INTERVAL_ONE_DAY;
    address private _newProposedOwner;
    uint256 private _newOwnerConfirmationTimestamp = block.timestamp;

    enum ErrorType {UnexpectedRequest, NoBalanceRequest, MigrateBridge}

    event BridgeTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 date,
        uint256 nonce
    );

    event BridgeTokensUnlocked(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 date
    );

    event FeesReleasedToOwner(
        uint256 amount,
        uint256 date
    );

    struct TokenConfig{
        uint256 maximumTransferAmount;
        uint256 collectedFees;
        uint256 unlockTokenPercentageFee;
        uint256 dailyLockTotal;
        uint256 dailyWithdrawTotal;
        uint256 dailyTransferLimit;
        bool exists;
    }

    event UnexpectedRequest(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 date,
        ErrorType indexed error
    );

    /** @dev Creates a cross-blockchain bridge.
      * @param soku -- BEP20 token to bridge.
      * @param suteku -- BEP20 token to bridge.
      * @param hobi -- BEP20 token to bridge.
      * @param unlockerBot -- address of account that mints/burns.
      * @param pauserBot -- address of account that pauses bridge in emergencies.
      */
    constructor(address soku, address suteku, address hobi, address payable unlockerBot, address pauserBot) {
        require(soku!=address(0) && suteku!=address(0) && hobi!=address(0) && unlockerBot != address(0) && pauserBot!= address(0) );
        _unlocker_bot = unlockerBot;
        _pauser_bot = pauserBot;
        _sokuToken = IERC20(soku);
        _sutekuToken = IERC20(suteku);
        _hobiToken = IERC20(hobi);
        configTokens();
    }

    function configTokens() internal{

        _tokenConfig[_sokuToken] = TokenConfig({
            maximumTransferAmount :1000000000000000000000000000,
            collectedFees:0,
            unlockTokenPercentageFee:0,
            dailyLockTotal:0,
            dailyWithdrawTotal:0,
            dailyTransferLimit:1000000000000000000000000000,
            exists:true
        });

        _tokenConfig[_sutekuToken] = TokenConfig({
            maximumTransferAmount:1000000000000000000000000000,
            collectedFees:0,
            unlockTokenPercentageFee:0,
            dailyLockTotal:0,
            dailyWithdrawTotal:0,
            dailyTransferLimit:1000000000000000000000000000,
            exists:true
        });

        _tokenConfig[_hobiToken] = TokenConfig({
            maximumTransferAmount :1000000000000000000000000000,
            collectedFees:0,
            unlockTokenPercentageFee:0,
            dailyLockTotal:0,
            dailyWithdrawTotal:0,
            dailyTransferLimit:1000000000000000000000000000,
            exists:true
        });
    }  

    modifier Pausable() {
        require( !paused, "Bridge: Paused.");
        _;
    }

    modifier OnlyUnlocker() {
        require(msg.sender == _unlocker_bot, "Bridge: You can't call this function.");
        _;
    }

    modifier OnlyPauserAndOwner() {
        require((msg.sender == _pauser_bot || msg.sender == owner()), "Bridge: You can't call this function.");
        _;
    }

    function resetTransferCounter(IERC20 token) internal {
        _dailyTransferNextTimestamp = block.timestamp + DAILY_TRANSFER_INTERVAL_ONE_DAY;
        TokenConfig storage config = _tokenConfig[token];
        config.dailyLockTotal = 0;
        config.dailyWithdrawTotal = 0;
    }

    /** @dev Locks tokens to bridge. External bot initiates unlock on other blockchain.
      * @param amount -- Amount of BabyDoge to lock.
      */
    function lock(IERC20 token, uint256 amount) external Pausable {
        address sender = msg.sender;
        require(_tokenConfig[token].exists == true, "Bridge: access denied.");
        require(token.balanceOf(sender) >= amount, "Bridge: Account has insufficient balance.");
        TokenConfig storage config = _tokenConfig[token];
        require(amount <= config.maximumTransferAmount, "Bridge: Please reduce the amount of tokens.");

        if (block.timestamp >= _dailyTransferNextTimestamp) {
            resetTransferCounter(token);
        }

        config.dailyLockTotal = config.dailyLockTotal + amount;

        if(config.dailyLockTotal > config.dailyTransferLimit) {
            revert("Bridge: Daily transfer limit reached.");
        }

        require(token.transferFrom(sender, address(this), amount), "Bridge: Transfer failed.");

        emit BridgeTransfer(
            address(token),
            sender,
            address(this),
            amount,
            block.timestamp,
            nonce
        );
        
        nonce++;
    }

    function release(IERC20 token, address to, uint256 amount, uint256 otherChainNonce) 
    external OnlyUnlocker() Pausable {
        require(!_processedNonces[otherChainNonce], "Bridge: Transaction processed.");
        require(to!= address(0), "Bridge: access denied.");
        TokenConfig storage config = _tokenConfig[token];
        require(amount <= config.maximumTransferAmount, "Bridge: Transfer blocked.");
        _processedNonces[otherChainNonce] = true;

        _balances[token][to] = _balances[token][to] + amount; 
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    } 

    function getConversionRate(uint256 ethAmount) public view returns (uint256 ethAmountInUsd){ //wei unit
        uint256 ethPrice = getPrice();
        return (ethPrice*ethAmount) / 1000000000000000000; // otherwise 18 + 18 = 36 decimal - need to remove 18 decimal
    }

    function getFee() view public returns (uint256 result) {
        uint256 ethPrice = getPrice();
        return (((minimumUSD*100000000000000000000) / ethPrice))/100; 
    }
    
    function withdraw(IERC20 token) external payable Pausable {
        require(getConversionRate(msg.value) >= getFee(), "You need to spend more ETH"); // otherwise reverts
        address claimer = msg.sender;
        uint256 claimerBalance = _balances[token][claimer];
        require(claimerBalance > 0, "Bridge: No balance.");
    
        TokenConfig storage config = _tokenConfig[token];

        if (block.timestamp >= _dailyTransferNextTimestamp) {
            resetTransferCounter(token);
        }

        config.dailyWithdrawTotal = config.dailyWithdrawTotal + claimerBalance;

        if(config.dailyWithdrawTotal > config.dailyTransferLimit) {
            revert("Bridge: Daily transfer limit reached.");
        }

        if(claimerBalance > token.balanceOf(address(this))) {
            revert('Bridge: No funds in the bridge.');
        }

        if (claimerBalance >= config.dailyTransferLimit) {
            pauseBridge(msg.sender, address(this), claimerBalance);
            revert('Bridge: Paused.');
        }

        if (address(this).balance >= feeReleaseThreshold) {
            uint256 amountReleased = address(this).balance;
            (bool success, ) = _unlocker_bot.call{value : amountReleased}("Releasing fee to unlocker");
            require(success, "Transfer failed.");
            emit FeesReleasedToOwner(amountReleased, block.timestamp);
        }

        _balances[token][claimer] = _balances[token][claimer] - claimerBalance;

        if (config.unlockTokenPercentageFee > 0) {
            uint256 amountFee = (claimerBalance * config.unlockTokenPercentageFee) / 100;
            claimerBalance = claimerBalance - amountFee;
            config.collectedFees = config.collectedFees + amountFee;
        }
        
        require(token.transfer(claimer, claimerBalance), "Bridge: Transfer failed");
        
        emit BridgeTokensUnlocked(address(token), address(this), msg.sender, claimerBalance, block.timestamp);
    } 
 
    function getBalance(IERC20 token) public view returns (uint256 balance) {
        return _balances[token][msg.sender];
    }

    function getTokenConfig(IERC20 token) public view returns (TokenConfig memory) {
        return _tokenConfig[token];
    }

    function setTokenConfig(
        IERC20 token, 
        uint256 maximumTransferAmount, 
        uint256 unlockTokenPercentageFee,
        uint256 dailyTransferLimit) external onlyOwner() {
            TokenConfig storage config = _tokenConfig[token];   
            config.maximumTransferAmount = maximumTransferAmount;
            config.unlockTokenPercentageFee = unlockTokenPercentageFee;
            config.dailyTransferLimit = dailyTransferLimit;
    }

    function resetDailyTotals(IERC20 token) external onlyOwner() {
        resetTransferCounter(token);
    }

    function setMinimumUsdFee(uint256 usd) external onlyOwner() {
        require(usd > 0, "Can't be zero");
        minimumUSD = usd * 10 ** 18;
    }

    function setTokenPercentageFee(IERC20 token, uint256 tokenFee) external onlyOwner() {
        require(tokenFee < 25, "Bridge: Gotta be smaller then 25") ;
        TokenConfig storage config = _tokenConfig[token];   
        require(config.exists, "Bridge: Token not found");
        config.unlockTokenPercentageFee = tokenFee;
    }

    function setFeeReleaseThreshold(uint256 amount) external onlyOwner() {
        require(amount > 0, "Bridge: Can't be zero");
        feeReleaseThreshold = amount;
    }

    function withdrawEth() external onlyOwner() {
        uint256 amountReleased = address(this).balance;
        (bool success, ) = owner().call{value : amountReleased}("Releasing eth to owner");
        require(success, "Transfer failed");
    }

    function withdrawERC20(IERC20 token) external onlyOwner() nonReentrant {
        require(address(token) != address(0), "Bridge: Can't be zero");
        require(token.balanceOf(address(this)) >= 0, "Bridge: Account has insufficient balance.");
        require(token.transfer(owner(), token.balanceOf(address(this))), "Bridge: Transfer failed.");
    }

    function withdrawCollectedFees(IERC20 token) external onlyOwner() nonReentrant {
        TokenConfig storage config = _tokenConfig[token];   
        require(config.exists, "Bridge: Token not found");
        require(token.balanceOf(address(this)) >= config.collectedFees, "Bridge: Account has insufficient balance.");
        require(token.transfer(owner(), config.collectedFees), "Bridge: Transfer failed.");
        config.collectedFees = 0;
    }

    function setUnlocker(address _unlocker) external onlyOwner {
        require(_unlocker != _unlocker_bot, "This address is already set as unlocker.");
        _unlocker_bot = payable(_unlocker);
    }

    function setPauser(address _pauser) external onlyOwner {
        require(_pauser != _pauser_bot, "This address is already set as pauser.");
        _pauser_bot = _pauser;
    }

    function setPausedState(bool state) external onlyOwner() {
        paused = state;
    }

    function pauseBridge(address from, address to, uint256 amount) internal {
        paused = true;

        emit UnexpectedRequest(
            from,
            to,
            amount,
            block.timestamp,
            ErrorType.UnexpectedRequest
        );
    }

}