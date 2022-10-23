/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

//SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: CS_flat.sol

/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// File: https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol




// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

contract DOXACrowdsale is OwnableUpgradeable{

    uint256 public tokenRate;
    uint256 public usdttokenRate;
    uint256 public daitokenRate;
    IERC20Upgradeable public token;   
    uint public startDate;
    uint public endDate;
    uint public contractBalance ;
    address public signer;
    mapping(address=>mapping(uint=>bool)) public usedNonce;

  
    address public admin;

    AggregatorV3Interface internal priceFeedETHUSD;
    AggregatorV3Interface internal priceFeedETHDAI;
    IERC20Upgradeable public USDT = IERC20Upgradeable(address(0xd732da5931D98F4D6e7065787db06AE17f060e7f));
    IERC20Upgradeable public DAI = IERC20Upgradeable(address(0xa2E882cC71d886e39bEfF65dB3697F1e8cC50864));

    /* Structure to store Investor Details*/
    struct InvestorDetails{ 
        uint totalBalance;
        uint lastVestedTime;
        uint reminingUnitsToVest;
        uint tokensPerUnit;
        uint vestingBalance;
        uint totalPaid;
        bool isETH;
        bool purchased;
    }
    
    event Buy(address buyer, uint ethPaid, uint tokenBought,uint tokenType);
    event TokenWithdraw(address account,uint value);
    event ETHUpdate(address indexed account);

    mapping(address => InvestorDetails) public Investors;

  
    
    modifier icoShouldBeStarted {
        require(block.timestamp >= startDate, 'ICO is not started yet!');
        _;
    }

    modifier icoShouldnotBeEnded {
        require(block.timestamp <= endDate, 'ICO is ended');
        _;
    }
   
    receive() external payable {
      buy();
    }
   
   

    uint public previousEthAmt;
    
    uint public vestingTime ; //14 Days
    uint public timeDuration ;
    uint minimumETH ;
    uint maximumETH;
   

    function buy() public payable icoShouldBeStarted icoShouldnotBeEnded {
        require(msg.value >= minimumETH, "Value is less than the minium ETH");
        require(msg.value <= maximumETH, "Value is greater than maximum ETH");
        processPayment(msg.sender, msg.value,3);
    }

     function payUsingTokens(uint8 tokenType, uint amount) public {
        if(tokenType == 0) {
            require(USDT.balanceOf(msg.sender) >= amount, "Insufficient balance");
            USDT.transferFrom(msg.sender, address(this), amount);
            // _tokens=tokenRateDai *__tokens;
            uint ethAmount = amount;
            processPayment(msg.sender, ethAmount,tokenType);
        }

        if(tokenType == 1) {
            require(DAI.balanceOf(msg.sender) >= amount, "Insufficient balance");
            DAI.transferFrom(msg.sender, address(this), amount);
            uint ethAmount = amount;
            previousEthAmt = ethAmount;
            processPayment(msg.sender, ethAmount,tokenType);
        }
    }

    function setSigner(address _signer) external onlyOwner{
        signer=_signer;
    }

    function processPayment(address account, uint amount ,uint values) private {
        /* Each wallet is limited to do only one purchase */
        //require(Investors[msg.sender].purchased == false, 'Restricted to 1 purchase per wallet');
        /* Buy value should be within the range */
        uint tokensToBuy;
        if(values == 0){
        tokensToBuy=amount*usdttokenRate;  
        }else if(values == 1){
         tokensToBuy =amount*daitokenRate;      
        }else{
         tokensToBuy =amount*(10**18/tokenRate);//1 000 000 000 000/  
        }
        if(!Investors[account].purchased) {
            
            /* The number of tokens should be less than the balance of ICO contract*/
            require(tokensToBuy <= contractBalance, "Tokens sold out! Try giving minium ETH value");
            
            /* Set all the initial investor details */
            InvestorDetails memory investor;
    
            investor.isETH = true;
            investor.totalPaid = amount;
            investor.totalBalance = tokensToBuy; //Number of tokens investor bought
            investor.tokensPerUnit = (investor.totalBalance)/(10); // Number of Token to release for each vesting period
            investor.reminingUnitsToVest =  10; // Remining number of units to vest
            investor.lastVestedTime = block.timestamp; // Last vested time
            investor.vestingBalance = tokensToBuy;
            contractBalance -= tokensToBuy;
            investor.purchased = true;
            Investors[account] = investor; // Map the investor address to it's corresponding details
            emit Buy(account, amount, tokensToBuy,values);
        } else {
            //require(Investors[msg.sender].isETH, "Try purchase using ETH!");
            require((Investors[account].totalPaid)/(amount) <= maximumETH, "Already bought for maximum ETH"); 
            // uint tokensToBuy = amount*(10**18/tokenRate);
            require(tokensToBuy <= contractBalance, "Tokens sold out! Try giving minium ETH value");
            Investors[account].totalPaid += amount;
            uint reminingUnitsToVest = Investors[account].reminingUnitsToVest;
            uint tokensPerUnit = tokensToBuy/(reminingUnitsToVest);
            Investors[account].tokensPerUnit += tokensPerUnit;   
            Investors[account].totalBalance += tokensToBuy;
            contractBalance -= tokensToBuy;
            Investors[account].vestingBalance += tokensToBuy;
            emit Buy(account, amount, tokensToBuy,values);
        }
    }
    
    function withdrawTokens() public {
        /* Time difference to calculate the interval between now and last vested time. */
        uint timeDifference = block.timestamp -(Investors[msg.sender].lastVestedTime);
        
        /* Number of units that can be vested between the time interval */
        uint numberOfUnitsCanBeVested = timeDifference/(timeDuration);
        
        /* Remining units to vest should be greater than 0 */
        require(Investors[msg.sender].reminingUnitsToVest > 0, 'All units vested!');
        
        /* Number of units can be vested should be more than 0 */
        require(numberOfUnitsCanBeVested > 0, 'Please wait till next vesting period!');

        if(numberOfUnitsCanBeVested >= Investors[msg.sender].reminingUnitsToVest) {
            numberOfUnitsCanBeVested = Investors[msg.sender].reminingUnitsToVest;
        }
        
        /*
            1. Calculate number of tokens to transfer
            2. Update the investor details
            3. Transfer the tokens to the wallet
        */
        
        uint tokenToTransfer = numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
        uint reminingUnits = Investors[msg.sender].reminingUnitsToVest;
        uint balance = Investors[msg.sender].vestingBalance;
        Investors[msg.sender].reminingUnitsToVest -= numberOfUnitsCanBeVested;
        Investors[msg.sender].vestingBalance -= numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
        Investors[msg.sender].lastVestedTime = block.timestamp;
        if(numberOfUnitsCanBeVested == reminingUnits) { 
            token.transfer(msg.sender, balance);
            emit TokenWithdraw(msg.sender, balance);
        } else {
            token.transfer(msg.sender, tokenToTransfer);
            emit TokenWithdraw(msg.sender, tokenToTransfer);
        }
        
    }
    
    /* Withdraw the contract's ETH balance to owner wallet*/
    function extractETH() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getInvestorDetails(address _addr) public view returns(InvestorDetails memory){
        return Investors[_addr];
    }
    
    function getContractETHBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function getContractTokenBalance() public view returns(uint) {
        return contractBalance;
    }
    
    /* Set the price of each token */
    function setTokneRate(uint rate) public onlyOwner {
        tokenRate = rate;
    }
    function setUsdtTokneRate(uint _usdttokenrate) public onlyOwner {
        usdttokenRate = _usdttokenrate;
    }
    function setDaiTokneRate(uint _daitokenrate) public onlyOwner {
        daitokenRate = _daitokenrate;
    }
    
    /* Set the maximum ETH to buy tokens*/
    function setMaximumETH(uint value) public  onlyOwner {
        maximumETH = value;
    }
    
    /* 
        Transfer the remining token to different wallet. 
        Once the ICO is completed and if there is any remining tokens it can be transfered other wallets.
    */
    function transferToken(address _addr, uint value) public onlyOwner {
        require(value <= contractBalance, 'Insufficient balance to withdraw');
        contractBalance -= value;
        token.transfer(_addr, value);
    }
    
    /* Set the ICO start date */
    function setICOStartDate(uint value) public onlyOwner {
        startDate = value;
    }

    function vestingTimeDifference(uint _time) public onlyOwner {
        vestingTime = _time;
    }

    /* Utility function for testing. The token address used in this ICO contract can be changed. */
    function setTokenAddress(address _addr) public onlyOwner {
        token = IERC20Upgradeable(_addr);
    }

    function changeEndDate(uint _value) public onlyOwner {
        endDate = _value;
    }

    function addContractBalance(uint _value) public onlyOwner {
        token.transferFrom(msg.sender,address(this),_value);
        contractBalance += _value;
    }

    function updateETHChainData(address account, InvestorDetails memory investor) public {
        require(msg.sender == admin, "Permission denied");
       // require(investor.isETH == false, "Not a ETH data!");
        Investors[account] = investor;
        emit ETHUpdate(account);
    }

    function getLatestPriceETHUSD() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeedETHUSD.latestRoundData();
        return price;
    }

    function getLatestPriceETHDAI() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeedETHDAI.latestRoundData();
        return price;
    }

    function changeUSDTAddress(IERC20Upgradeable _addr) public onlyOwner {
        USDT = IERC20Upgradeable(_addr);
    }

    function changeDAIAddress(IERC20Upgradeable _addr) public onlyOwner {
        DAI = IERC20Upgradeable(_addr);
    }

    function extractAlt(uint8 tokenType, address _addr) public onlyOwner {
        if(tokenType == 0) {
            USDT.transfer(_addr, USDT.balanceOf(address(this)));
        }
        if(tokenType == 1) {
            DAI.transfer(_addr, USDT.balanceOf(address(this)));
        }
    }
     function initialize(uint256 _tokenRate, address _tokenAddress, address _admin, uint _startDate, uint _endDate)  external initializer{
        require(
        _tokenRate != 0 &&
        _tokenAddress != address(0) &&
        _admin != address(0) &&
        _startDate != 0 &&
        _endDate != 0);

        tokenRate = _tokenRate;
        token = IERC20Upgradeable(_tokenAddress);
        startDate = _startDate;
        endDate = _endDate;
        admin = _admin;
         signer=msg.sender; 
         __Ownable_init();
        priceFeedETHUSD = AggregatorV3Interface(0xd732da5931D98F4D6e7065787db06AE17f060e7f);
        priceFeedETHDAI = AggregatorV3Interface(0xa2E882cC71d886e39bEfF65dB3697F1e8cC50864);
    }

   
    function setValues( uint256 _vestingTime, uint256 _timeDuration,uint256 _contractBalance,uint256 _minimumETH, uint256 _maximumETH) external onlyOwner{
        vestingTime=_vestingTime*1 minutes;   // 14 days
        timeDuration=_timeDuration * 1 minutes; // 5  minutes
        minimumETH=_minimumETH; // 1000000000000000 
        maximumETH=_maximumETH; //  1000000000000000000 
        contractBalance=_contractBalance;  
    }

}