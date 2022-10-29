// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error Lottery__UnAuthorized();
error Lottery__NeedToSendCorrectAmount();
error Lottery__TransferGainsToWinnerFailed();
error Lottery__NotOPEN_TO_LEND();
error Lottery__UpKeepNotNeeded(
    uint256 _lotteryBalance,
    uint256 _numberOfPlayers,
    uint256 _lotteryState
);
error Lottery__CompoundAllowanceFailed();
error Lottery__NotOPEN_TO_WITHDRAW();
error Lottery__PlayerHas0Ticket();
error Lottery__PlayerWithdrawLotteryFailed();
error Lottery__AdminWithdrawETHFailed();
error Lottery__AdminWithdrawUSDCFailed();
error Lottery__AdminCanNotPerformMyUpkeep();

// import "hardhat/console.sol";

// LotteryToken LTK ERC20
import "./LotteryToken.sol";
// Chainlink VRF v2 - Verifiable Random Function
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// Chainlink Keepers - Automation
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
// USDC ERC20
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Compound V3
import "./interfaces/IComet.sol";

/** @title A sample Lottery contract
 * @author SiegfriedBz
 * @notice This contract is for creating an untamperable decentralized Lottery smart contract
 * @dev This implements Chainlink VRF v2 and Chainlink Keeper ("Automation")
 * @notice Chainlink VRF will pick a random number
 * @notice Chainlink Keeper will call the function to pick a winner
 * @dev This implements CompoundV3 to lend USDC
 * @notice User can enter Lottery by:
 * // sending ETH to pay the Lottery ("lotteryFee") + transfering USDC to start lending ("lotteryTicketPrice")
 * @notice User receives 1 Lottery Token (LTK) by entering Lottery
 */

contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type Declaration */
    enum LotteryState {
        OPEN_TO_LEND,
        CALCULATING,
        OPEN_TO_WITHDRAW
    }

    /* State Variables */
    // Lottery Variables
    uint256 private immutable i_lotteryFee; // ETH 18 decimals
    uint256 private immutable i_lotteryTicketPrice; // USDC 6 decimals
    uint256 private immutable i_interval; // Lottery & ChainLink Keepers
    uint256 private s_lastTimeStamp;
    uint256 private s_newPrize;
    uint256 private s_totalNumTickets; // total number of active tickets == total number of LTK owned by Players
    mapping(address => uint256) private playerToNumTickets; // player's active tickets number
    address payable private immutable i_owner;
    address private s_newWinner;
    address[] private s_players;
    LotteryState private s_lotteryState;
    bool public isFirstPlayer = true; // reset at each Lottery round

    // LotteryToken
    LotteryToken public lotteryToken;

    // ChainLink Keepers & VRF config
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // VRF
    bytes32 private immutable i_gasLane; // VRF
    uint64 private immutable i_subscriptionId; // VRF
    uint32 private immutable i_callbackGasLimit; // VRF
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // VRF
    uint32 private constant NUMWORDS = 1; // VRF

    // USDC
    ERC20 public usdc;

    // CompoundV3
    Comet public comet;

    /* Events */
    event LotteryEntered(address indexed player);
    event RandomWinnerRequested(uint256 indexed requestId);
    event WinnerPicked(
        address indexed s_newWinner,
        uint256 indexed s_newPrize,
        uint256 indexed winDate
    );
    event SupplyCompoundDone(uint256 indexed amount);
    event CompoundWithdrawRequested();
    event CompoundWithdrawDone();
    event UserWithdraw(address indexed player, uint256 indexed amount);


    modifier onlyOwner() {
        if (i_owner != msg.sender) {
            revert Lottery__UnAuthorized();
        }
        _;
    }

    constructor(
        uint256 _lotteryFee, // ETH
        uint256 _lotteryTicketPrice, // USDC
        uint256 _interval,
        // note: TODO add intervalWithdraw
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        address payable _USDCAddress,
        address payable _cometcUSDCv3Address
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        /* Lottery */
        i_owner = payable(msg.sender);
        i_lotteryFee = _lotteryFee;
        i_lotteryTicketPrice = _lotteryTicketPrice;
        s_lotteryState = LotteryState.OPEN_TO_LEND;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        /* ChainLink */
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        /* LotteryToken */
        lotteryToken = new LotteryToken();
        /* USDC */
        usdc = ERC20(_USDCAddress);
        /* CompoundV3 */
        comet = Comet(_cometcUSDCv3Address);
    }

    /**
     * @dev function called by the ChainLink Keeper ("Automation") nodes
     * They look for "upkeepNeeded" to return true
     * To return true the following is needed
     * 1. Lottery is in "OPEN_TO_LEND" state ("CALCULATING" when waiting for a random number from Chainlink VRF)
     * 2. Lottery Time interval has passed
     * 3. Lottery has >= 1player, and Lottery is funded
     * 4. ChainLink subscription has enough LINK
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOPEN_TO_LEND = (s_lotteryState == LotteryState.OPEN_TO_LEND);
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayer = (s_players.length > 0);
        bool isFunded = (address(this).balance > 0);
        upkeepNeeded = (isOPEN_TO_LEND && timePassed && hasPlayer && isFunded);
    }

    /**
     * @dev function called by the ChainLink Keeper ("Automation") nodes
     * when checkUpkeep() return true.
     * If upkeepNeeded is true:
     * // a request for randomness is made to ChainLink VRF
     * // a call is made by Lottery to Coumpound to withdraw all available USDC
     */
    function performUpkeep(
        bytes memory /* performData */
    ) external override {
        // upkeep revalidation
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        // update LotteryState
        s_lotteryState = LotteryState.CALCULATING;
        // request the random number from ChainLink VRF
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUMWORDS
        );
        // calls Coumpound to withdraw all available USDC => Lottery
        _withdrawfromCompound();
        emit RandomWinnerRequested(requestId);
        emit CompoundWithdrawRequested();
    }

    /**
     * @dev function called by the ChainLink nodes
     * After the request for randomness is made, a Chainlink Node calls its own fulfillRandomWords to run off-chain calculation => randomWords.
     * Then, a Chainlink Node calls our fulfillRandomWords (on-chain) and pass to it the requestId and the randomWords.
     * Picks Address Winner
     * Transfer Winner USDC GAINS to its wallet
     * The Winner by default, like all other Players, keep its USDC in Lottery for next run. Also, all Players, including Winner, keep their Lottery Tokens.
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        // set Winner
        uint256 indexOfWinner = randomWords[0] % s_players.length; // randomWords[0] : we expect only 1 "random word" (having passed NUMWORDS = 1;) and we want a "random word" belonging to [0, players.length-1]
        address newWinner = s_players[indexOfWinner];
        s_newWinner = newWinner;
        s_lastTimeStamp = block.timestamp;
        // set Winner GAINS
        uint256 lotteryBaseUSDCValue = s_totalNumTickets * i_lotteryTicketPrice; // withOut potential interests
        uint256 lotteryCurrentUSDCBalance = _getlotteryUSDCBalance(); // with potential interests
        // check if GAINS > 0
        if(lotteryCurrentUSDCBalance > lotteryBaseUSDCValue) {
          s_newPrize = lotteryCurrentUSDCBalance - lotteryBaseUSDCValue;
          // transfer GAINS to winner
          (bool success) = usdc.transfer(newWinner, s_newPrize);
          if (!success) {
            revert Lottery__TransferGainsToWinnerFailed();
          }
        } else {
          s_newPrize = 0;
          }
        // reset Players array
        s_players = new address[](0);
        // set LotteryState
        // note: TODO set LotteryState to OPEN_TO_WITHDRAW and Set a KEEPERS WITH TIME AUTOMATION to set set LotteryState to OPEN_TO_LEND
        s_lotteryState = LotteryState.OPEN_TO_WITHDRAW;
        emit WinnerPicked(s_newWinner, s_newPrize, block.timestamp);
    }

    /**
     * @notice function called by Player
     * adds msg.sender to the players array
     * adds 1 ticket to Player playerToNumTickets mapping
     * transfers 1 LTK token to Player
     * calls USDC to approve Compound
     * calls Compound to supply in USDC
     */
    function enterLottery() public payable {
        if (s_lotteryState != LotteryState.OPEN_TO_LEND) {
            revert Lottery__NotOPEN_TO_LEND();
        }
        if (msg.value != i_lotteryFee) {
            revert Lottery__NeedToSendCorrectAmount();
        }
        // update Player's tickets
        playerToNumTickets[msg.sender] += 1; // increment Player number of tickets
        s_totalNumTickets += 1; // increment total number of tickets
        lotteryToken.transfer(msg.sender, 1); // transfer 1 LTK to Player
        s_players.push(msg.sender);
        // call Compound to supply
        _approveAndSupplyCompound();
        emit LotteryEntered(msg.sender);
    }

     /**
     * note IF called by PLAYER:
     * need 1. Player transfer USDC to "this" and then 2. _approveAndSupplyCompound() called by Lottery contract
     * note: /!\ to implement from FRONT END with USDC instance: firstly REQUIRES PLAYER DIRECT INTERACTION with USDC ERC20 CONTRACT for USER TO TRANSFER i_lotteryTicketPrice USDC TO "this"
     * note IF called by ADMIN: no need for 1. All current Lottery USDC balance will supply Compound
     * note: "This" accumulates USDC from Players: total lotteryUSDCBalance = _getlotteryUSDCBalance()
     * 3. Lottery Approve Compound to use Lottery's USDC
     * 4. Lottery Supply Compound with USDC (amount = f( isFirstPlayer, Admin ))
     */
    function _approveAndSupplyCompound() internal {
        // Lottery gives allowance to Compound for all USDC
        uint256 lotteryUSDCBalance = _getlotteryUSDCBalance();
        bool success = usdc.increaseAllowance(
            address(comet),
            lotteryUSDCBalance
        );
        if (!success) {
            revert Lottery__CompoundAllowanceFailed();
        }
        // Lottery supplies Compound
        uint256 amountToSupply;
        if (isFirstPlayer || (msg.sender == i_owner)) {
            // adds all current lotteryUSDCBalance to supply : includes last current player TicketPrice + all previous lottery runs remainings from users having not withdrawn their USDC
            amountToSupply = lotteryUSDCBalance;
            if(isFirstPlayer) { isFirstPlayer = false; }
        } else {
            // adds only 1 TicketPrice to supply
            amountToSupply = i_lotteryTicketPrice;
        }
        comet.supply(address(usdc), amountToSupply);
        emit SupplyCompoundDone(amountToSupply);
    }

     /**
     * @notice function called by Lottery to withdraw all available USDC
     * Transfer all available USDC from Compound to Lottery
     * Reset isFirstPlayer for next Lottery round
     * note: Lottery is in CALCULATING state
     */
    function _withdrawfromCompound() internal {
        uint128 availableUSDC = _getlotteryUSDCBalanceOnCompound();
        comet.withdraw(address(usdc), availableUSDC);
        isFirstPlayer = true;
        emit CompoundWithdrawDone();
    }

    /**
   * @notice function called by Player to withdraw its USDC from Lottery
   * 1. Player calls LotteryToken => transfers Player LotteryTokens to Lottery
   * Reset Player mapping toNumTickets
   * Updates totalNumTickets
   * 2. Lottery calls USDC => Transfer Player's USDC from Lottery to Player
   * // Player gets MAX of (PlayerNumTokens * TicketPrice, PlayerRatio * LotteryCurrentUSDCBalance)
   * note: Lottery is in OPEN_TO_WITHDRAW state
   */
    function withdrawFromLottery() public
    {
      if (s_lotteryState != LotteryState.OPEN_TO_WITHDRAW) {
          revert Lottery__NotOPEN_TO_WITHDRAW();
        }
      if(playerToNumTickets[msg.sender] == 0) {
        revert Lottery__PlayerHas0Ticket();
      }
      // transfer Player LotteryTokens to Lottery
      uint256 playerNumTickets = playerToNumTickets[msg.sender];
      lotteryToken.transfer(address(this), playerNumTickets);

      // set Player due USDC
      uint256 amountDuetoPlayer;
      uint256 playerBaseUSDCValue = playerNumTickets * i_lotteryTicketPrice;
      uint256 lotteryBaseUSDCValue = s_totalNumTickets * i_lotteryTicketPrice; // withOut potential interests
      uint256 lotteryCurrentUSDCBalance = _getlotteryUSDCBalance(); // with potential interests
      if(lotteryCurrentUSDCBalance > lotteryBaseUSDCValue) {
        uint256 userRatio = (playerNumTickets * 10**18) / s_totalNumTickets;
        amountDuetoPlayer = userRatio * lotteryCurrentUSDCBalance / 10**18;
      } else {
        amountDuetoPlayer = playerBaseUSDCValue;
      }
      // transfer USDC due amount to Player
      bool success = usdc.transfer(msg.sender, amountDuetoPlayer);
      if (!success) {
        revert Lottery__PlayerWithdrawLotteryFailed();
      }
      // reset
      s_totalNumTickets -= playerToNumTickets[msg.sender];
      playerToNumTickets[msg.sender] = 0;
      emit UserWithdraw(msg.sender, amountDuetoPlayer);
    }


  /* View/Pure functions */

    /**
   * @notice Getter for front end
   * returns the entrance fee
   */
    function getLotteryFee() public view returns (uint256) {
        return i_lotteryFee;
    }

    /**
   * @notice Getter for front end
   * returns the lottery Ticket Price
   */
    function getLotteryTicketPrice() public view returns (uint256) {
        return i_lotteryTicketPrice;
    }

    /**
     * @notice Getter for front end
     * returns the players array
     */
    function getPlayers() public view returns (address[] memory) {
        return s_players;
    }

    /**
     * @notice Getter
     * returns the total number of active tickets
     */
    function getTotalNumTickets() public view returns (uint256) {
        return s_totalNumTickets;
    }

     /**
     * @notice Getter
     * returns the Player's number of tickets
     */
    function getPlayerNumberOfTickets(address _player) public view returns (uint256) {
        return playerToNumTickets[_player];
    }

    /**
     * @notice Getter for front end
     */
    function getNewWinner() public view returns (address) {
        return s_newWinner;
    }

    /**
     * @notice Getter for front end
     */
    function getNewWinnerPrize() public view returns (uint256) {
        return s_newPrize;
    }

    /**
     * @notice Getter for front end
     */
    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    /**
     * @notice Getter for front end
     */
    function getLotteryState() public view returns (uint256) {
        return uint256(s_lotteryState);
    }

    /**
     * @notice Getter for front end
     */
    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    /**
     * @notice Getter for front end
     */
    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    /**
    * @notice Getter for front end
    */
    function getNumWords() public pure returns (uint256) {
        return NUMWORDS;
    }

    /**
    * @notice Getter
    * returns the Lottery USDC current balance
    */
    function _getlotteryUSDCBalance() public view returns (uint256) {
        uint256 lotteryUSDCBalance = uint256(usdc.balanceOf(address(this)));
        return lotteryUSDCBalance;
    }

    /**
     * @notice Getter
     * returns USDC amount available for Lottery to withdraw on Compound
     */
    function _getlotteryUSDCBalanceOnCompound()
        public
        view
        returns (uint128 balance)
    {
        balance = uint128(comet.balanceOf(address(this)));
    }

    /**
    * @notice Getter
    * returns the ratio = user's active numTickets / total active tickets
    */
    function getPlayerRatio(address _player)
        public
        returns (
          uint256 userRatio
        )
    {
        uint256 playerNumTickets = playerToNumTickets[_player];
        userRatio = (playerNumTickets * 10**18) / s_totalNumTickets;
    }

    /**
    * @notice Getter
    * returns the admin address
    */
    function getAdmin() public returns (address) {
      return i_owner;
    }

    /* Functions for Admin */
      /**
     * @notice function for Admin
     * note: NEED TO SET UP A CHAINLINK KEEPERS WITH TIME TO REPLACE/AUTOMATE THIS FUNCTION:
     * note xhours after WinnerIsPicked (lotteryState being then in OPEN_TO_WITHDRAW)
     * note performUpkeep => LotteryState.OPEN_TO_LEND + ApproveAndSupplyCompound()
     * Sets LotteryState to OPEN_TO_LEND for new Players to play + Supply current Lottery USDC balance to Compound
     */
      function adminPerformMyUpkeep() external onlyOwner {
        // if(s_lotteryState != LotteryState.OPEN_TO_WITHDRAW) {
        //   revert Lottery__AdminCanNotPerformMyUpkeep();
        // }
        s_lotteryState = LotteryState.OPEN_TO_LEND;
        _approveAndSupplyCompound();
      }

    /**
     * @notice function for Admin
     * returns the Lottery USDC amount approved to be used by Compound
     */
      function getLotteryGivenApprovalsToComet()
        external
        view
        onlyOwner
        returns (uint256)
      {
        return usdc.allowance(address(this), address(comet));
      }

      /**
      * @notice function for Admin
      * sends the ETH Lottery value to Admin
      */
      function withdrawLotteryETH() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) {
           revert Lottery__AdminWithdrawETHFailed();
       }
      }

      /**
      * @notice function for Admin
      * returns the Lottery USDC amount
      */
      function __withdrawLotteryUSDC() external onlyOwner {
        uint256 lotteryUSDCBalance = _getlotteryUSDCBalance();
        bool success = usdc.transfer(msg.sender, lotteryUSDCBalance);
        if (!success) {
           revert Lottery__AdminWithdrawUSDCFailed();
       }
      }

      /* Functions fallbacks */
      receive() external payable {
        enterLottery();
      }
      fallback() external payable {
        enterLottery();
      }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LotteryToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("LotteryToken", "LTK") {
        _mint(msg.sender, 10000 * 10**18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library CometStructs {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct TotalsBasic {
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct RewardOwed {
        address token;
        uint owed;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }
}

interface Comet {
    function balanceOf(address account) external view returns (uint256);

    function collateralBalanceOf(address account, address asset)
        external
        view
        returns (uint128);

    function baseScale() external view returns (uint);

    function supply(address asset, uint amount) external;

    function withdraw(address asset, uint amount) external;

    function getSupplyRate(uint utilization) external view returns (uint);

    function getBorrowRate(uint utilization) external view returns (uint);

    function getAssetInfoByAddress(address asset)
        external
        view
        returns (CometStructs.AssetInfo memory);

    function getAssetInfo(uint8 i)
        external
        view
        returns (CometStructs.AssetInfo memory);

    function getPrice(address priceFeed) external view returns (uint128);

    function userBasic(address)
        external
        view
        returns (CometStructs.UserBasic memory);

    function totalsBasic()
        external
        view
        returns (CometStructs.TotalsBasic memory);

    function userCollateral(address, address)
        external
        view
        returns (CometStructs.UserCollateral memory);

    function baseTokenPriceFeed() external view returns (address);

    function numAssets() external view returns (uint8);

    function getUtilization() external view returns (uint);

    function baseTrackingSupplySpeed() external view returns (uint);

    function baseTrackingBorrowSpeed() external view returns (uint);

    function totalSupply() external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function baseIndexScale() external pure returns (uint64);

    function totalsCollateral(address asset)
        external
        view
        returns (CometStructs.TotalsCollateral memory);

    function baseMinForRewards() external view returns (uint256);

    function baseToken() external view returns (address);
}

interface CometRewards {
    function getRewardOwed(address comet, address account)
        external
        returns (CometStructs.RewardOwed memory);

    function claim(
        address comet,
        address src,
        bool shouldAccrue
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
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