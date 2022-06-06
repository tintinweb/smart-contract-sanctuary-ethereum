/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

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

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol


pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol


pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

// File: IBCO.sol

//SPDX-License-Identifier: MIT
/*
 */
pragma solidity ^0.8.2;







/**
 * @dev Implement Initial Bonding Curve Offering for DakShow Token - TESTNET
 */

contract DakShowIBCO is Ownable, KeeperCompatibleInterface {
    AggregatorV3Interface internal priceFeedETH;
    AggregatorV3Interface internal priceFeedUSDT;
    AggregatorV3Interface internal priceFeedBNB;
    AggregatorV3Interface internal priceFeedTRX;
    AggregatorV3Interface internal priceFeedBUSD;
    AggregatorV3Interface internal priceFeedUSDC;
    AggregatorV3Interface internal priceFeedBTC;
    AggregatorV3Interface internal priceFeedETC;

    event Claim(address indexed account, uint256 userShare, uint256 DAKAmount);
    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);

    IERC20 public immutable DakShow;
    address internal CoolWallet;
    IERC20 internal USDT;
    IERC20 internal TRX;
    IERC20 internal BUSD;
    IERC20 internal BNB;
    IERC20 internal USDC;
    IERC20 internal BTC;
    IERC20 internal ETH;
    IERC20 internal ETC;

    uint256 public constant DECIMALS = 10**18; // DakShow Token has the same decimals as BNB (18)
    uint256 public START = 1653919586;
    bool public END = false;
    uint256 public AFTEREND;
    uint256 public totalUSDT = 0;
    uint256 public totalTRX = 0;
    uint256 public totalBUSD = 0;
    uint256 public totalBNB = 0;
    uint256 public totalUSDC = 0;
    uint256 public totalBTC = 0;
    uint256 public totalETH = 0;
    uint256 public totalETC = 0;
    uint256 public totalDakIBCO = 0;
    uint256 public totalProvided = 0;
    address[] public userIBCO;

    uint16 public totalClaim = 0;

    mapping(address => uint256) public provided;
    mapping(address => uint256) private totalDAKWithDraw;

    constructor(
        address _coolWallet,
        IERC20 DAK,
        IERC20 _usdt,
        IERC20 _trx,
        IERC20 _busd,
        IERC20 _bnb,
        IERC20 _usdc,
        IERC20 _btc,
        IERC20 _eth,
        IERC20 _etc
    ) {
        CoolWallet = _coolWallet;
        DakShow = DAK;
        USDT = _usdt;
        TRX = _trx;
        BUSD = _busd;
        BNB = _bnb;
        USDC = _usdc;
        BTC = _btc;
        ETH = _eth;
        ETC = _etc;
        // Kovan testnet
        priceFeedETH = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        priceFeedUSDT = AggregatorV3Interface(
            0x2ca5A90D34cA333661083F89D831f757A9A50148
        );
        priceFeedBNB = AggregatorV3Interface(
            0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16
        );
        priceFeedTRX = AggregatorV3Interface(
            0x9477f0E5bfABaf253eacEE3beE3ccF08b46cc79c
        );
        priceFeedUSDC = AggregatorV3Interface(
            0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60
        );
        priceFeedBTC = AggregatorV3Interface(
            0x6135b13325bfC4B00278B4abC5e20bbce2D6580e
        );

        // priceFeedBUSD = AggregatorV3Interface(	0xcBb98864Ef56E9042e7d2efef76141f15731B82f);

        // Mainnet Binace không có ETC / USD 
        // priceFeedETC = AggregatorV3Interface(0xb29f616a0d54FF292e997922fFf46012a63E2FAe);
    }

    /**
     * @dev Kiểm tra xem thời gian hiện tại có 
   
     */
    modifier checkTimeClaimToken() {
        if (
            block.timestamp < AFTEREND ||
            totalClaim >= 12|| !END
        ) {
            revert();
        }
        _;
    }

    modifier checkTimeDeposit() {
        if (block.timestamp  < START  || END) {
            revert();
        }
        _;
    }
    
 
    function claimToken() public checkTimeClaimToken {
        // require(block.timestamp > AFTEREND, "Only claimable after 30 minutes since the Offering duration ended");
        for (uint256 i = 0; i < userIBCO.length; i++) {
            uint256 DAKAmount = totalDAKWithDraw[userIBCO[i]]/ 12;

            require(provided[userIBCO[i]] > 0, "Empty balance");
            require(
                DakShow.allowance(owner(), address(this)) >=
                    DAKAmount,
                "Not enough tokens to transfer"
            );
            uint256 userShare = provided[userIBCO[i]];

            DakShow.transferFrom(owner(), userIBCO[i], DAKAmount);

            emit Claim(userIBCO[i], userShare, DAKAmount);
        }
        AFTEREND += 3 minutes;
        totalClaim++;
    }

    // ---------- AUTOMATIC FUNCTION ----------

    function checkUpkeep(
        bytes calldata /*checkData*/
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = block.timestamp > AFTEREND;
        return (upkeepNeeded, bytes(""));
    }

    function performUpkeep(
        bytes calldata /* performData*/
    ) external override {
      
        claimToken();
    }

    function getLatestPriceETH() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeedETH.latestRoundData();
        return price;
    }

    function getLatestPriceUSDT() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeedUSDT.latestRoundData();
        return price;
    }

    function getLatestPriceBNB() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeedBNB.latestRoundData();
        return price;
    }

    function getLatestPriceTRX() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeedTRX.latestRoundData();
        return price;
    }

    // function getLatestPriceBUSD() public view returns (int) {
    //     (
    //         /*uint80 roundID*/,
    //         int price,
    //         /*uint startedAt*/,
    //         /*uint timeStamp*/,
    //         /*uint80 answeredInRound*/
    //     ) = priceFeedBUSD.latestRoundData();
    //     return price;
    // }

    function getLatestPriceUSDC() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeedUSDC.latestRoundData();
        return price;
    }

    //  function getLatestPriceETC() public view returns (int) {
    //     (
    //         /*uint80 roundID*/,
    //         int price,
    //         /*uint startedAt*/,
    //         /*uint timeStamp*/,
    //         /*uint80 answeredInRound*/
    //     ) = priceFeedETC.latestRoundData();
    //     return price;
    // }

    function getLatestPriceBTC() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeedBTC.latestRoundData();
        return price;
    }

    function depositUSDT(uint256 amount) external checkTimeDeposit {
        int256 price = getLatestPriceUSDT();
        uint256 userShare = (amount * uint256(price)) / 10**8;

        require(
            DakShow.allowance(owner(), address(this)) >=
               _getEstReceivedToken(userShare) + totalDakIBCO,
            "Insufficient DakShow token in contract"
        );
        require(
            USDT.allowance(msg.sender, address(this)) >= amount,
            "Caller must approve first"
        );

        // grab the tokens from msg.sender.
         if(provided[msg.sender] == 0){
            userIBCO.push(msg.sender);
        }

        USDT.transferFrom(msg.sender, CoolWallet, amount);

        provided[msg.sender] +=userShare;

        totalUSDT += amount;

        totalDAKWithDraw[msg.sender] += _getEstReceivedToken(userShare);

        totalDakIBCO += totalDAKWithDraw[msg.sender];

        totalProvided += userShare;

        emit Deposit(msg.sender, amount);
    }

    function depositTRX(uint256 amount) external checkTimeDeposit {
        int256 price = getLatestPriceTRX();

        uint256 userShare = (amount * uint256(price)) / 10**8;

        require(
            DakShow.allowance(owner(), address(this)) >=
                _getEstReceivedToken(userShare) + totalDakIBCO,
            "Insufficient DakShow token in contract"
        );

        require(
            TRX.allowance(msg.sender, address(this)) >= amount,
            "Caller must approve first"
        );

        // grab the tokens from msg.sender.
        if(provided[msg.sender] == 0){
            userIBCO.push(msg.sender);
        }

        TRX.transferFrom(msg.sender, CoolWallet, amount);

        provided[msg.sender] +=userShare;

        totalTRX += amount;

        totalDAKWithDraw[msg.sender] += _getEstReceivedToken(userShare);

        totalDakIBCO += totalDAKWithDraw[msg.sender];

        totalProvided += userShare;

        emit Deposit(msg.sender, amount);
    }

    // function depositBUSD(uint256 amount) external checkTimeDeposit {
    //     int256 price = getLatestPriceBUSD();

    //     uint256 userShare = (amount * uint256(price)) / 10**8;

    //     require(
    //         DakShow.allowance(owner(), address(this)) >=
    //             _getEstReceivedToken(userShare),
    //         "Insufficient DakShow token in contract"
    //     );
    //     require(
    //         ETH.allowance(msg.sender, address(this)) >= amount,
    //         "Caller must approve first"
    //     );

    //     // grab the tokens from msg.sender.
    //     BUSD.transferFrom(msg.sender, CoolWallet, amount);

    //     provided[msg.sender] +=userShare;

    //     totalBUSD += amount;

    //     totalDAKWithDraw[msg.sender] += _getEstReceivedToken(userShare);

    //     totalDakIBCO += totalDAKWithDraw[msg.sender];

    //     totalProvided += userShare;

    //     userIBCO.push(msg.sender);

    //     emit Deposit(msg.sender, amount);
    // }

    function depositBNB(uint256 amount) external checkTimeDeposit {
        int256 price = getLatestPriceBNB();

        uint256 userShare = (amount * uint256(price)) / 10**8;

        require(
            DakShow.allowance(owner(), address(this)) >=
                _getEstReceivedToken(userShare) + totalDakIBCO,
            "Insufficient DakShow token in contract"
        );
        require(
            BNB.allowance(msg.sender, address(this)) >= amount,
            "Caller must approve first"
        );

        // grab the tokens from msg.sender.
        if(provided[msg.sender] == 0){
            userIBCO.push(msg.sender);
        }
        BNB.transferFrom(msg.sender, CoolWallet, amount);

        provided[msg.sender] +=userShare;

        totalBNB += amount;

        totalDAKWithDraw[msg.sender] += _getEstReceivedToken(userShare);

        totalDakIBCO += totalDAKWithDraw[msg.sender];

        totalProvided += userShare;

        emit Deposit(msg.sender, amount);
    }

    function depositUSDC(uint256 amount) external checkTimeDeposit {
        int256 price = getLatestPriceUSDC();

        uint256 userShare = (amount * uint256(price)) / 10**8;

        require(
            DakShow.allowance(owner(), address(this)) >=
                _getEstReceivedToken(userShare) + totalDakIBCO,
            "Insufficient DakShow token in contract"
        );
        require(
            USDC.allowance(msg.sender, address(this)) >= amount,
            "Caller must approve first"
        );

        // grab the tokens from msg.sender.
        if(provided[msg.sender] == 0){
            userIBCO.push(msg.sender);
        }

        USDC.transferFrom(msg.sender, CoolWallet, amount);

        provided[msg.sender] +=userShare;

        totalUSDC += amount;

        totalDAKWithDraw[msg.sender] += _getEstReceivedToken(userShare);

        totalDakIBCO += totalDAKWithDraw[msg.sender];

        totalProvided += userShare;

        emit Deposit(msg.sender, amount);
    }

    function depositBTC(uint256 amount) external checkTimeDeposit {
        int256 price = getLatestPriceBTC();

        uint256 userShare = (amount * uint256(price)) / 10**8;

        require(
            DakShow.allowance(owner(), address(this)) >=
                _getEstReceivedToken(userShare) + totalDakIBCO,
            "Insufficient DakShow token in contract"
        );
        require(
            BTC.allowance(msg.sender, address(this)) >= amount,
            "Caller must approve first"
        );

        // grab the tokens from msg.sender.
        if(provided[msg.sender] == 0){
            userIBCO.push(msg.sender);
        }
        BTC.transferFrom(msg.sender, CoolWallet, amount);

        provided[msg.sender] +=userShare;

        totalBTC += amount;

        totalDAKWithDraw[msg.sender] += _getEstReceivedToken(userShare);

        totalDakIBCO += totalDAKWithDraw[msg.sender];

        totalProvided += userShare;

        emit Deposit(msg.sender, amount);
    }

    // function depositETC(uint256 amount) external checkTimeDeposit{

    //     require(
    //         ETC.allowance(msg.sender, address(this)) >= amount,
    //         "Caller must approve first"
    //     );

    //     // grab the tokens from msg.sender.
    //     ETC.transferFrom(msg.sender, CoolWallet, amount);

    //     int256 price = getLatestPriceETC();

    //     provided[msg.sender] +=userShare;

    //     totalETC += amount;

    //     uint256 userShare = (amount * uint256(price)) / 10**8;

    //     totalDAKWithDraw[msg.sender] += _getEstReceivedToken(userShare);

    //     totalDakIBCO += totalDAKWithDraw[msg.sender];

    //     totalProvided += userShare;

    //     userIBCO.push(msg.sender);

    //     emit Deposit(msg.sender, amount);
    // }

    function depositETH(uint256 amount) external checkTimeDeposit {
        int256 price = getLatestPriceETH();

        // int256 price = getLatestPriceETH();
        uint256 userShare = (amount * uint256(price)) / 10**8;

        require(
            DakShow.allowance(owner(), address(this)) >=
                _getEstReceivedToken(userShare) + totalDakIBCO,
            "Insufficient DakShow token in contract"
        );
        require(
            ETH.allowance(msg.sender, address(this)) >= amount,
            "Caller must approve first"
        );

        // grab the tokens from msg.sender.
        ETH.transferFrom(msg.sender, CoolWallet, amount);

        if(provided[msg.sender] == 0){
            userIBCO.push(msg.sender);
        }
    
        provided[msg.sender] +=userShare;

        totalETH += amount;

        totalDAKWithDraw[msg.sender] += _getEstReceivedToken(userShare);

        totalDakIBCO += totalDAKWithDraw[msg.sender];

        totalProvided += userShare;

        emit Deposit(msg.sender, amount);
    }

  

    /**
     * @dev Returns total USD deposited in the contract of an address.
     */

    function getUserDeposited(address _user) external view returns (uint256) {
        return provided[_user];
    }

    function getTokenDakWithdraw(address _user)
        external
        view
        returns (uint256)
    {
        return totalDAKWithDraw[_user];
    }

    /**
     * @dev Calculate the amount of BUSD that can be withdrawn by user
     */

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev Estimate the amount of $DakShow that can be claim by user
     */

     function _getEstReceivedToken(uint256 _userShare)
        internal
        view
        returns (uint256)
    {
        uint256 params = (1335 * (_userShare + totalProvided)) /
            10**14+
            225625000000;
        return ((20000000 * sqrt(params))/8010  - 1186017480) * 10**16- totalDakIBCO;
        
    }


    /**
     * @dev Get estimated DakShow token price
     */
    function getEstTokenPrice() public view returns (uint256) {
        return 2403 * totalDakIBCO * 10**5 + (57 * DECIMALS) / 20000;
    }


    /**
     * @dev Get estimated amount of DakShow token an address will receive
     */
    function getEstReceivedToken(uint256 _amount)
        external
        view
        returns (uint256)
    {
        return _getEstReceivedToken(_amount);
    }
    /**
     * @dev The project owner will buy back all remaining dak tokens to end the private sale
     788235*DECIMALS là số lượng tiền khi bán đc 70tr token DAK
     */
    

    function quantityRemaining() public view returns(uint256){
        return 788235*DECIMALS - (2403*((totalDakIBCO/DECIMALS)**2)*10**5  / 2
        + 285*10**13 * totalDakIBCO/DECIMALS);
    }

    
    function buyRemainingQuantity() external {
        uint256 currentDakRemaining = 70000000 * DECIMALS - totalDakIBCO;
        
        uint256 amount =  788235*DECIMALS - (2403*((totalDakIBCO/DECIMALS)**2)*10**5  / 2
        + 285*10**13 * totalDakIBCO/DECIMALS);
       
        require(DakShow.allowance(owner(), address(this)) >= currentDakRemaining,"Insufficient DakShow token in contract");
       
        if(provided[msg.sender] == 0){
            userIBCO.push(msg.sender);
        }
    
        BUSD.transferFrom(msg.sender, CoolWallet, amount);
        END = true;

        AFTEREND = block.timestamp;

        provided[msg.sender] +=amount;

        totalBUSD += amount;

        totalDAKWithDraw[msg.sender] += currentDakRemaining;

        totalDakIBCO += currentDakRemaining;

        totalProvided += amount;

        emit Deposit(msg.sender, amount);
    }
    
}