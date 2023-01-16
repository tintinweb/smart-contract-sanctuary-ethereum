/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// File: contracts/Exchange.sol


pragma solidity ^0.8.0;




interface IERC20MintableBurnable is IERC20 {
    function mint(address account, uint amount) external;
    function burn(address account, uint amount) external;
}

contract Exchange {
    
    using Counters for Counters.Counter;
    Counters.Counter private _txId;

    AggregatorV3Interface internal btcPriceFeed;
    AggregatorV3Interface internal ethPriceFeed;

    uint public minCollatRatio = 120;
    uint public maxCollatRatio = 500;
    uint public refinanceFee = 12; // Fee percentage for refinance
    
    IERC20 private constant btcToken = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // wBTC address of Ethereum mainnet
    IERC20MintableBurnable public token; // address of stablecoin to be lended

    address private _owner;
    address coldWallet;

    uint[] private _interestRates = [25, 99, 199, 299, 399, 449]; // List of interest rates for each collateral range. Multiplied by 100

    struct Borrow {
        uint amountToken;
        uint amountCollat;
        uint percentageCollat;
        uint lastPaidTimestamp;
        uint accInterest;
        address borrower;
        bool btcCollat; // True = borrowed for btc. False = borrowed for eth
    }

    mapping(uint => Borrow) private _borrows;
    mapping(address => uint[]) private _btcTxIds; // total amount of btc currently deposited by an address
    mapping(address => uint[]) private _ethTxIds; // total amount of eth currently deposited by an address
    
    event TokensBorrowedForBtc(address indexed borrower, uint id, uint256 amount, uint256 borrowTime);
    event TokensBorrowedForEth(address indexed borrower, uint id, uint256 amount, uint256 borrowTime);
    event InterestPaid(uint id, address payee, uint amount, uint ts);

    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @param _token address of stablecoin being lended
    /// @param _coldWallet address of cold wallet
    constructor(
        address _token, 
        address _coldWallet
    ) {
        btcPriceFeed = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c); // Mainnet BTC / USD price feed
        ethPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // Mainnet ETH / USD price feed

        token = IERC20MintableBurnable(_token);

        _owner = msg.sender;
        coldWallet = _coldWallet;

    }

    function getBtcRate() public view returns (uint) {
        ( ,int price, , , ) = btcPriceFeed.latestRoundData();
        return uint(price) / 1e8; 
    }

    function getEthRate() public view returns (uint) {
        ( ,int price, , , ) = ethPriceFeed.latestRoundData();
        return uint(price) / 1e8; 
    }
    
    /// @notice Total amount of borrows taken from the contract
    function totalBorrows() external view returns (uint) {
        return _txId.current();

    }

    /// @notice Borrow tokens in exchange for btc
    /// @param amountBtc amount of btc the user wants to spend
    /// @param amountAmerG amount of stablecoin user wants to get in return
    /// NOTE: The collateral ratio must be within minCollatRatio and maxCollatRatio
    function borrowTokensForBtc(uint256 amountBtc, uint256 amountAmerG) external {
        require(amountBtc > 0 && amountAmerG > 0, "Exchange: amount cannot be zero");

        uint collateral = (amountBtc * getBtcRate() * 100) / amountAmerG;
        require(collateral >= minCollatRatio && collateral <= maxCollatRatio, "Exchange: collateral out of range");

        _txId.increment();
        uint256 currentId = _txId.current();

        _borrows[currentId] = Borrow(
            amountAmerG, 
            amountBtc, 
            collateral, 
            block.timestamp, 
            0,
            msg.sender, 
            true
        );

        _btcTxIds[msg.sender].push(currentId);

        btcToken.transferFrom(msg.sender, address(this), amountBtc);

        token.mint(msg.sender, amountAmerG);

        emit TokensBorrowedForBtc(msg.sender, currentId, amountAmerG, block.timestamp);
    }

    /// @notice Borrow tokens in exchange for eth
    /// @param amountAmerG amount of stablecoin user wants to get in return
    /// NOTE: The collateral ratio must be within minCollatRatio and maxCollatRatio
    function borrowTokensForEth(uint256 amountAmerG) external payable {
        require(msg.value > 0 && amountAmerG > 0, "Exchange: amount cannot be zero");

        uint collateral = (msg.value * getEthRate() * 100) / amountAmerG;
        require(collateral >= minCollatRatio && collateral <= maxCollatRatio, "Exchange: collateral out of range");

        _txId.increment();
        uint256 currentId = _txId.current();

        _borrows[currentId] = Borrow(
            amountAmerG, 
            msg.value, 
            collateral, 
            block.timestamp, 
            0,
            msg.sender, 
            false
        );

        _ethTxIds[msg.sender].push(currentId);

        token.mint(msg.sender, amountAmerG);

        emit TokensBorrowedForEth(msg.sender, currentId, amountAmerG, block.timestamp);
    }

    // Interest percentage scaled by 10
    function _getInterestPercentage(uint collateral) internal view returns (uint256) {
        if(collateral >= 401 && collateral <= 500)
            return _interestRates[0];
        else if(collateral >= 301 && collateral < 401)
            return _interestRates[1];
        else if(collateral >= 251 && collateral < 301)
            return _interestRates[2];
        else if(collateral >= 201 && collateral < 251)
            return _interestRates[3];
        else if(collateral >= 171 && collateral < 201)
            return _interestRates[4];
        else if(collateral >= 120 && collateral < 171)
            return _interestRates[5];
        else
            revert("Exchange: Invalid collateral");
    }

    /// @notice Pay accumulated interest for 'txId'
    function payInterest(uint txId) external {
        uint totalInterest = getTotalInterest(txId);
        require(totalInterest > 0, "Exchange: no interest"); 

        _borrows[txId].lastPaidTimestamp = block.timestamp;
        _borrows[txId].accInterest = 0;
        
        token.transferFrom(msg.sender, coldWallet, totalInterest);

        emit InterestPaid(txId, msg.sender, totalInterest, block.timestamp);
    }

    /// Optional functions to reimburse 
    /// @notice Reimburse a portion of borrowed stablecoins
    /// @param txId id of transaction
    /// @param amount amount of stablecoin to be reimbursed
    function reimburse(uint txId, uint amount) external { 
        Borrow storage b = _borrows[txId];
        require(msg.sender == b.borrower, "Exchange: you are not the borrower");
        require(amount > 0 && amount <= b.amountToken, "Exchange: incorrect amount");

        b.accInterest = getTotalInterest(txId);

        b.lastPaidTimestamp = block.timestamp;
        b.amountToken -= amount;

        // Not deleting tx even when amount becomes zero

        token.burn(msg.sender, amount);
    }

    /// @notice Refinance for 'txId' if applicable
    /// NOTE: must have approval to transfer fee
    function refinance(uint txId, uint collateralPercentage) external {
        Borrow storage b = _borrows[txId];
        require(msg.sender == b.borrower, "Exchange: you are not the borrower");
        require(collateralPercentage >= minCollatRatio && collateralPercentage <= maxCollatRatio, "Exchange: invalid collateral");
        uint currentRate = b.btcCollat ? getBtcRate() : getEthRate();
        
        uint total = (currentRate * b.amountCollat * 100) / collateralPercentage;
        uint fee = (b.amountToken * refinanceFee) / 100;
        uint claimable = total - b.amountToken - fee;

        require(claimable > 0, "Exchange: refinance not applicable");

        b.accInterest = getTotalInterest(txId);
        b.lastPaidTimestamp = block.timestamp;
        b.amountToken += claimable;
        b.percentageCollat = collateralPercentage;

        token.transferFrom(msg.sender, coldWallet, fee);
        token.mint(msg.sender, claimable);
    }
    
    function getBtcTxIds(address borrower) external view returns (uint[] memory) {
        return _btcTxIds[borrower];
    }

    function getEthTxIds(address borrower) external view returns (uint[] memory) {
        return _ethTxIds[borrower];
    }

    function getInterestRates() external view returns (uint[] memory)  { 
        return _interestRates;
    }

    /// @notice Returns current accumulated interest 
    function getTotalInterest(uint txId) public view returns (uint256) {
        uint perAnnum = (_borrows[txId].amountToken * _getInterestPercentage(_borrows[txId].percentageCollat)) / 10000;
        uint currentInterest = (perAnnum * (block.timestamp - _borrows[txId].lastPaidTimestamp)) / 365 days;
        return currentInterest + _borrows[txId].accInterest;
    }

    function getBorrowInfo(uint txId) external view returns (Borrow memory) {
        return _borrows[txId]; 
    }
    
    /* --- ONLY OWNER --- */

    /// @notice Collect interest in cold wallet for 'txId' if unpaid for over a month
    /// @param collateralAmount amount of btc/eth to collect.
    /// Will be collected using the asset that was used for borrow. 
    function collectInterest(uint txId, uint collateralAmount) external onlyOwner {
        require(block.timestamp - _borrows[txId].lastPaidTimestamp >= 30 days, "Exchange: borrower has paid interest within a month");
        
        uint cInterest = getTotalInterest(txId);
        uint amountStable = collateralAmount * (_borrows[txId].btcCollat ? getBtcRate() : getEthRate());
        require(cInterest >= amountStable, "Exchange: amount exceeds unpaid interest");
        
        _borrows[txId].lastPaidTimestamp = block.timestamp;
        _borrows[txId].accInterest = cInterest - amountStable;
        _borrows[txId].amountCollat -= collateralAmount;

        if(_borrows[txId].btcCollat) 
            btcToken.transfer(coldWallet, collateralAmount);
        else 
            payable(coldWallet).transfer(collateralAmount);
    }

    // List containing new interest rates for each of the 6 collateral ranges sequentially.
    // Each interest rate should be multiplied by 100. (For example: 75 for 0.75 %)
    function setInterestRates(uint[] calldata newInterestRates) external onlyOwner {
        require(newInterestRates.length == 6, "Exchange: invalid length");
        _interestRates = newInterestRates;
    }

    /// @notice Change cold wallet address
    function setColdWallet(address newColdWallet) external onlyOwner {
        coldWallet = newColdWallet;
    }

    function setRefinanceFee(uint newRefiFee) external onlyOwner {
        refinanceFee = newRefiFee;
    }
    
    function setPriceFeeds(address btcFeed, address ethFeed) external onlyOwner {
        btcPriceFeed = AggregatorV3Interface(btcFeed); 
        ethPriceFeed = AggregatorV3Interface(ethFeed);
    }
    
    /// @notice Transfers eth from this contract to the Cold Wallet
    function withdrawEth(uint amount) external onlyOwner {
        payable(coldWallet).transfer(amount);
    }

    /// @notice Transfers btc from this contract to the Cold Wallet
    function withdrawBtc(uint amount) external onlyOwner {
        btcToken.transfer(coldWallet, amount);
    }

    function withdrawTokens(uint amount) external onlyOwner {
        token.transfer(coldWallet, amount);
    }

    /// @notice Return collateral used for 'txId'
    function returnCollateral(uint txId) external onlyOwner {
        uint currentBalance = _borrows[txId].amountCollat;
        require(currentBalance > 0, "Exchange: nothing to return");
        
        _borrows[txId].amountCollat = 0;

        if(_borrows[txId].btcCollat) 
            btcToken.transfer(_borrows[txId].borrower, currentBalance);
        else 
            payable(_borrows[txId].borrower).transfer(currentBalance);
    }

    // OpenZeppelin Ownable

    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

}