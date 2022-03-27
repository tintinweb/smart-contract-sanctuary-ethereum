// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Matrix-Money Raffle
/// @notice Randomized from @chainlink VRF
contract MMRaffle is Ownable, VRFConsumerBase {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public linkTokenAddress;
    uint256 public linkFee;
    bytes32 public VRFKeyHash;

    /// ============ Constructor ============

    // A contstructor to deal with randomness
    constructor() VRFConsumerBase(_vrfCoordinator, _linkTokenAddress) {
        linkFee = _linkFee;
        VRFKeyHash = _VRFKeyHash;
        linkTokenAddress = _linkTokenAddress;
    }

    address _vrfCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B; // address to LINK VRF Coordinator
    address _linkTokenAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // address to LINK token
    bytes32 _VRFKeyHash =
        0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311; // key hash for LINK VRF oracle
    uint256 _linkFee = 0.1 * 10**18; // 0.1 LINK, link token fee

    /// ============ Mutable storage ============

    // for Raffle
    struct Raffle {
        uint256 id; // unique identifier for the raffle
        string name; // name of the raffle
        uint256 ticketCount; // number of tickets bought for this raffle
        uint256 ticketPrice; // in omb token
        address winnerOne; // addresses of the top winner of the raffle, by default it's 0x0
        address[] winnersTwo; // array of addresses of the second winners of the raffle, by default it's []
        address[] winnersThree; // array of addresses of the third winners of the raffle, by default it's []
        mapping(address => uint8) winGroupValue; // mapping of address to win group: 1, 2, 3, 0
        address[] winGroup; // array of addresses for winners
        uint256 startTime; // unix timestamp of the start of the raffle
        uint256 endTime; // unix timestamp of the end of the raffle
        RaffleState state; // state of the raffle
        mapping(address => uint256) ticketBalances; // mapping of address to ticket count
        address[] ticketOwners; // array of addresses of the ticket owners (used for iteration through the ticket balances)
    }

    /// @param Open: The raffle is open for entry
    /// @param SelectingWinner: The raffle is closed and the winner is being selected
    /// @param Finished: The raffle is finished and the winner has been selected, prize has been paid
    enum RaffleState {
        Open,
        SelectingWinner,
        Finished
    }
    Counters.Counter public RaffleCount;
    mapping(uint256 => Raffle) public Raffles; // mapping of raffle id to raffle data
    mapping(bytes32 => uint256) public VRFRequestIdTORaffleId; // mapping of VRF request id to raffle id
    address winOnePrize; // address of Prize token for WinGroup(1)
    address winTwoPrize; // address of Prize token for WinGroup(2)
    address winThreePrize; // address of Prize token for WinGroup(3)
    uint8 public numOfWinTwo = 10; // number of winners for WinGroup(2)
    uint8 public numOfWinThree = 100; // number of winners for WinGroup(3)
    uint256 public amountWinOnePrize = 500; // amount of Prize for WinGroup(1)
    uint256 public amountWinTwoPrize = 200; // amount of Prize for WinGroup(2)
    uint256 public amountWinThreePrize = 50; // amount of Prize for WinGroup(3)
    address buyTicketToken; // address of 2omb or 3omb token
    address ownerWallet;

    // for staking
    address stakingToken = 0xc54A1684fD1bef1f077a336E6be4Bd9a3096a6Ca; // token address to be staked, current one is for 2shares
    uint256 public maxTax = 30; // in %, first tax maximum
    uint256 public taxRate = 5 / uint256(2); // in %, tax difference
    uint256 public maxStakeAmount = 10; // max amount of 2share for staking
    uint256 public totalBalance; // total deposited stake amount
    struct Staker {
        uint256 stakesAmount; //staked amount of staker
        uint256 tax; // this will be applied to the prize in raffle
    }
    mapping(address => Staker) public stakers; // mapping staker address to detail params
    address[] public stakerActs; // array of stakers

    /// ============ Events ============

    /// @notice emitted after a successful raffle claim
    /// @param requestId request ID
    event RequestRandomness(bytes32 requestId);

    /// @notice emitted after pick winners and paid out
    /// @param raffleId current raffle ID
    /// @param winner1 address of top winner
    /// @param winners2 address array of winners in group(2)
    /// @param winners3 address array of winners in group(3)
    event WinnerChosen(
        uint256 raffleId,
        address winner1,
        address[] winners2,
        address[] winners3
    );

    /// @notice emitted after create a raffle
    /// @param raffleId created raffle ID
    event RaffleCreated(uint256 raffleId);

    /// @notice emitted after a user staked some 2share token
    /// @param user address of user who just staked
    /// @param stakeAmount amount of staked token by user
    event Staked(address user, uint256 stakeAmount);

    /// @notice emitted after a user withdrew / unstaked some 2share token
    /// @param user address of user who just unstaked
    /// @param unStakeAmount amount of unstaked token by user
    event UnStaked(address user, uint256 unStakeAmount);

    /// @notice emitted after a user unstaked whole tokens staked
    /// @param user address of user who just unstaked all tokens
    event UnStakedAll(address user);

    /// ============ Functions ============

    /// @notice create a raffle
    /// @param _raffleName name of this raffle
    /// @param _ticketPrice price rate to the omb token
    /// @param _raffleDuration the seconds of raffle duration time
    function CreateRaffle(
        string memory _raffleName,
        uint256 _ticketPrice,
        uint256 _raffleDuration
    ) public {
        RaffleCount.increment();
        uint256 _id = RaffleCount.current();
        Raffle storage raffle = Raffles[_id];
        raffle.id = _id;
        raffle.name = _raffleName;
        raffle.ticketCount = 0;
        raffle.ticketPrice = _ticketPrice;
        raffle.startTime = block.timestamp;
        raffle.endTime = block.timestamp + _raffleDuration;
        raffle.state = RaffleState.Open;
        raffle.winnerOne;
        raffle.winnersTwo;
        raffle.winnersThree;

        emit RaffleCreated(_id);
    }

    /// @notice Staking 2share token
    /// @param amount amount of tokens to be staked
    function stake(uint256 amount) external {
        require(amount > 0, "The amount must be greater than 0");
        require(
            IERC20(stakingToken).balanceOf(msg.sender) >= amount,
            "insufficient token for staking in your wallet"
        );
        // approve token to this contract enoughfully
        IERC20(stakingToken).approve(address(this), amount + 1000);
        // transfer 2share tokens from user to contract
        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
        // total staked 2share token balance in contract
        totalBalance += amount;

        // If the staker is not in the stakers array, add him
        Staker storage staker = stakers[msg.sender];
        if (staker.stakesAmount == 0) {
            stakerActs.push(msg.sender);
        }
        // increase staker's stake amount
        staker.stakesAmount += amount;
        // calculate staker's tax which will be applied to raffle prize if wins
        staker.tax = maxTax - (staker.stakesAmount - 1) * taxRate;

        // emit stake event
        emit Staked(msg.sender, amount);
    }

    /// @notice Unstaking some amount
    /// @param amount amount if tokens to be unstaked
    function unStake(uint256 amount) external {
        // get user from staker's array
        Staker storage staker = stakers[msg.sender];
        // get raffle ID
        uint256 raffleId = RaffleCount.current();

        require(
            Raffles[raffleId].state == RaffleState.Finished,
            "Raffle has not finished, can not be unstaked untill raffle closes"
        );
        require(staker.stakesAmount > 0, "There is not staked token");
        require(
            staker.stakesAmount >= amount,
            "The amount to be withdrew should be less than staked amount"
        );

        uint256 totalDeposit = IERC20(stakingToken).balanceOf(address(this));
        require(totalDeposit >= amount, "insufficient in deposit");

        // transfer 2share token from contract to staker
        IERC20(stakingToken).transfer(msg.sender, amount);
        // decrease staker's stake amount
        staker.stakesAmount -= amount;
        // total staked 2share token balance in contract
        totalBalance -= amount;

        // emit unstake event
        emit UnStaked(msg.sender, amount);
    }

    /// @notice Unstaking all amount staked
    function unStakeAll() external {
        // get uer from staker's array
        Staker storage staker = stakers[msg.sender];
        // get raffle ID
        uint256 raffleId = RaffleCount.current();

        require(
            Raffles[raffleId].state == RaffleState.Finished,
            "Raffle's not finished, can not be unstaked untill raffle closes"
        );
        require(staker.stakesAmount > 0, "There is not staked token");

        uint256 totalDeposit = IERC20(stakingToken).balanceOf(address(this));
        require(totalDeposit >= staker.stakesAmount, "insufficient in deposit");

        // transfer all mount of staked tokens from contract to staker
        IERC20(stakingToken).transfer(msg.sender, staker.stakesAmount);
        // set staker's balance to 0
        staker.stakesAmount = 0;

        // total staked 2share token balance in contract
        totalBalance -= staker.stakesAmount;

        // emit unstakeAll event
        emit UnStakedAll(msg.sender);
    }

    /// @notice a reader function for getting info about raffles
    /// @param _id raffle id
    function GetRaffleInfo(uint256 _id)
        public
        view
        returns (
            string memory name,
            uint256 startTime,
            uint256 endTime
        )
    {
        return (
            Raffles[_id].name,
            Raffles[_id].startTime,
            Raffles[_id].endTime
        );
    }

    /// @notice a reader function for getting info about raffle ticket
    function GetRaffleTicketInfo(uint256 _id)
        public
        view
        returns (
            string memory name,
            uint256 startTime,
            uint256 endTime,
            uint256 ticketCount,
            uint256 ticketPrice
        )
    {
        return (
            Raffles[_id].name,
            Raffles[_id].startTime,
            Raffles[_id].endTime,
            Raffles[_id].ticketCount,
            Raffles[_id].ticketPrice
        );
    }

    /// @notice get ticket balance of user
    /// @param _id raffle id
    /// @param owner address of ticket owner
    function GetTicketBalance(uint256 _id, address owner)
        public
        view
        returns (uint256 balance)
    {
        return Raffles[_id].ticketBalances[owner];
    }

    /// @notice get raffle count
    function GetRaffleCount() public view returns (uint256) {
        return RaffleCount.current();
    }

    /// @notice Win Probability in %
    /// @param _id raffle id
    /// @param owner address of ticket owner
    function GetOddsWin(uint256 _id, address owner)
        public
        view
        returns (uint256)
    {
        return
            (Raffles[_id].ticketBalances[owner] / Raffles[_id].ticketCount) *
            100;
    }

    /// @notice claim raffle
    /// @param _id raffle id
    function ClaimRaffle(uint256 _id) public onlyOwner {
        require(
            block.timestamp >= Raffles[_id].endTime,
            "The raffle has not closed yet"
        );
        require(
            Raffles[_id].state == RaffleState.Open,
            "The raffle is not avaible for claiming"
        );
        require(
            IERC20(linkTokenAddress).balanceOf(address(this)) >= linkFee,
            "The contract needs to be paid link token to claim the raffle"
        );
        // set raffle state to the selecting winner
        Raffles[_id].state = RaffleState.SelectingWinner;
        // Fire off the VRF to select the winner
        bytes32 requestId = requestRandomness(VRFKeyHash, linkFee); // Return a bytes 32 which is the request ID
        VRFRequestIdTORaffleId[requestId] = _id; // Map the request ID to the raffle ID

        // emit claim event
        emit RequestRandomness(requestId);
    }

    /// @notice Fullfills randomness from ChainLink VRF, This is run by the VRF coordinator to finalize the winner
    /// @param _requestId returned id of VRF request
    /// @param _randomness random number from VRF
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        uint256 raffleId = VRFRequestIdTORaffleId[_requestId];
        require(
            Raffles[raffleId].state == RaffleState.SelectingWinner,
            "The raffle is not in the SelectingWinner state"
        );
        require(_randomness >= 0, "No randomness found");
        Raffles[raffleId].state = RaffleState.Finished;

        // Winner group(1)
        // random index of top winner
        uint256 indexOfWinOne = _randomness %
            Raffles[raffleId].ticketOwners.length;
        // pick a top winner
        Raffles[raffleId].winnerOne = Raffles[raffleId].ticketOwners[
            indexOfWinOne
        ];
        // add top winner into winner's group and labeled 1
        Raffles[raffleId].winGroup.push(Raffles[raffleId].winnerOne);
        Raffles[raffleId].winGroupValue[Raffles[raffleId].winnerOne] = 1;

        // Send raffle top prize to the winnerOne
        uint256 winOnePrizeBalance = IERC20(winOnePrize).balanceOf(
            address(this)
        );
        require(
            winOnePrizeBalance >= amountWinOnePrize,
            "insufficient Prize(1) deposit"
        );
        require(
            amountWinOnePrize > 0,
            "Prize amount for top winner must be greater than 0"
        );
        Staker storage stakerOne = stakers[Raffles[raffleId].winnerOne];
        IERC20(winOnePrize).transfer(
            Raffles[raffleId].winnerOne,
            amountWinOnePrize * (1 - stakerOne.tax / 100)
        );

        // Winner group(2)
        uint256 winTwoPrizeBalance = IERC20(winTwoPrize).balanceOf(
            address(this)
        );
        require(
            winTwoPrizeBalance >= amountWinTwoPrize * numOfWinTwo,
            "insufficient Prize(2) deposit"
        );
        require(
            amountWinTwoPrize > 0,
            "Prize amount for group(2) winner must be greater than 0"
        );
        // call multiRandomnes function to pick random indexes
        uint256[] memory multiRandomTwo = multiRandomness(
            _randomness,
            numOfWinTwo
        );
        // loop
        for (uint256 i = 0; i < numOfWinTwo; i++) {
            // random index of ith winner(2)
            uint256 indexOfWinTwo = multiRandomTwo[i] %
                Raffles[raffleId].ticketOwners.length;
            // pick a winner(2)
            address winnerTwo = Raffles[raffleId].ticketOwners[indexOfWinTwo];
            // if picked winner is not the top winner, add him into winners(2) array and winner's group, labeled 2, send a prize(2)
            if (winnerTwo != Raffles[raffleId].winnerOne) {
                Raffles[raffleId].winnersTwo.push(winnerTwo);
                Raffles[raffleId].winGroup.push(winnerTwo);
                Raffles[raffleId].winGroupValue[winnerTwo] = 2;
                // Send a raffle prize(2) to the picked winner in group(2)
                Staker storage stakerTwo = stakers[winnerTwo];
                IERC20(winTwoPrize).transfer(
                    winnerTwo,
                    amountWinTwoPrize * (1 - stakerTwo.tax / 100)
                );
            }
        }

        // Winner group(3)
        uint256 winThreePrizeBalance = IERC20(winThreePrize).balanceOf(
            address(this)
        );
        require(
            winThreePrizeBalance >= amountWinThreePrize * numOfWinThree,
            "insufficient Prize(3) deposit"
        );
        require(
            amountWinThreePrize > 0,
            "Prize amount for group(3)  winner must be greater than 0"
        );
        // call multiRandomnes function to pick random indexes, i.e. 10 + 100
        uint256 numOfWinTwoThree = numOfWinTwo + numOfWinThree;
        uint256[] memory multiRandomTwoThree = multiRandomness(
            _randomness,
            numOfWinTwoThree
        );
        // loop
        for (uint256 i = numOfWinTwoThree; i < numOfWinTwo; i--) {
            // random index of ith winner(3)
            uint256 indexOfWinThree = multiRandomTwoThree[i] %
                Raffles[raffleId].ticketOwners.length;
            // pick a winner(3)
            address winnerThree = Raffles[raffleId].ticketOwners[
                indexOfWinThree
            ];
            // if picked winner is not the top winner and is not winner(2), add him into winners(3) array and winner's group, labeled 3, send a prize(3)
            if (
                winnerThree != Raffles[raffleId].winnerOne &&
                Raffles[raffleId].winGroupValue[winnerThree] != 2
            ) {
                Raffles[raffleId].winnersThree.push(winnerThree);
                Raffles[raffleId].winGroup.push(winnerThree);
                Raffles[raffleId].winGroupValue[winnerThree] = 3;
                // Send a raffle prize(3) to the picked winner in group(3)
                Staker storage stakerThree = stakers[winnerThree];
                IERC20(winThreePrize).transfer(
                    winnerThree,
                    amountWinThreePrize * (1 - stakerThree.tax / 100)
                );
            }
        }

        // set raffle state to the "Finished"
        Raffles[raffleId].state == RaffleState.Finished;

        // emit pick winner event
        emit WinnerChosen(
            raffleId,
            Raffles[raffleId].winnerOne,
            Raffles[raffleId].winnersTwo,
            Raffles[raffleId].winnersThree
        );
    }

    /// @notice a function that generate multi random numbers
    /// @param _randomness random number from VRF
    /// @param _numberOfWinners number of winners
    function multiRandomness(uint256 _randomness, uint256 _numberOfWinners)
        public
        pure
        returns (uint256[] memory multiRandom)
    {
        multiRandom = new uint256[](_numberOfWinners);
        for (uint256 i = 0; i < _numberOfWinners; i++) {
            multiRandom[i] = uint256(keccak256(abi.encode(_randomness, i)));
        }
        return multiRandom;
    }

    /// @notice A function to buy tickets for a raffle
    /// @param raffleId raffle id
    /// @param _ticketCount amount of ticket to buy
    function BuyTickets(uint256 raffleId, uint256 _ticketCount) public {
        require(Raffles[raffleId].state == RaffleState.Open, "Raffle not open");

        Staker storage staker = stakers[msg.sender];
        require(
            staker.stakesAmount > 0,
            "There is not staked token, can not buy tickets before staking"
        );
        require(
            block.timestamp < Raffles[raffleId].endTime,
            "Raffle is closed"
        );
        require(_ticketCount > 0, "Ticket count must be greater than 0");
        // amount of omb token for ticket amount to buy
        uint256 countedToken = Raffles[raffleId].ticketPrice * _ticketCount;
        require(
            IERC20(buyTicketToken).balanceOf(msg.sender) >= countedToken,
            "insufficient token to buy in your wallet"
        );
        // approve obm token of buyer to this contract
        IERC20(buyTicketToken).approve(address(this), countedToken + 1000);
        IERC20(buyTicketToken).transferFrom(
            msg.sender,
            address(this),
            countedToken
        );

        Raffles[raffleId].ticketCount += _ticketCount;
        // If the buyer is not in the ticket owners array, add him
        if (Raffles[raffleId].ticketBalances[msg.sender] == 0) {
            Raffles[raffleId].ticketOwners.push(msg.sender);
        }
        // increase ticket amount of buyer
        Raffles[raffleId].ticketBalances[msg.sender] += _ticketCount;
    }

    /// @notice increase raffle duration if insufficient participants
    /// @param raffleId id of raffle
    /// @param moreTime seconds to be increased
    function increaseRaffleEndTime(uint256 raffleId, uint256 moreTime)
        public
        onlyOwner
    {
        Raffles[raffleId].endTime += moreTime;
    }

    /// @notice set new numbers of winner for the winGroup(2) and winGroup(3)
    /// @param _newNumOfWinTwo new number of winners(2)
    /// @param _newNumOfWinThree new number of winners(3)
    function changeNumOfWinners(uint8 _newNumOfWinTwo, uint8 _newNumOfWinThree)
        public
        onlyOwner
    {
        numOfWinTwo = _newNumOfWinTwo;
        numOfWinThree = _newNumOfWinThree;
    }

    /// @notice set new amounts of Prize for winGroup(1), winGroup(2) and winGroup(3)
    /// @param _newAmountWinOnePrize new amount of prize(1)
    /// @param _newAmountWinTwoPrize new amount of prize(2)
    /// @param _newAmountWinThreePrize new amount of prize(3)
    function changeAmountOfPrize(
        uint256 _newAmountWinOnePrize,
        uint256 _newAmountWinTwoPrize,
        uint256 _newAmountWinThreePrize
    ) public onlyOwner {
        amountWinOnePrize = _newAmountWinOnePrize;
        amountWinTwoPrize = _newAmountWinTwoPrize;
        amountWinThreePrize = _newAmountWinThreePrize;
    }

    /// @notice set new address of Prize tokens for winGroup(1), winGroup(2) and winGroup(3)
    /// @param _newWinOnePrize new address of Prize(1) token
    /// @param _newWinTwoPrize new address of Prize(2) token
    /// @param _newWinThreePrize new address of Prize(3) token
    function changeAmountOfPrize(
        address _newWinOnePrize,
        address _newWinTwoPrize,
        address _newWinThreePrize
    ) public onlyOwner {
        winOnePrize = _newWinOnePrize;
        winTwoPrize = _newWinTwoPrize;
        winThreePrize = _newWinThreePrize;
    }

    /// @notice set new buy ticket token address
    /// @param _newToken new address of token to buy
    function changeBuyToken(address _newToken) public onlyOwner {
        buyTicketToken = _newToken;
    }

    /// @notice set new OwnerWallet
    /// @param _newOwnerWallet new address of owner wallet
    function changeOwnerWallet(address _newOwnerWallet) public onlyOwner {
        ownerWallet = _newOwnerWallet;
    }

    /// @notice get the Owner Wallet
    function getOwnerWallet() public view returns (address) {
        return ownerWallet;
    }

    /// @notice change stake params
    /// @param _newStakingToken new address of staking token like 2share
    /// @param _newMaxTax new value of max tax like first tax
    /// @param _newTaxRate new rate of tax
    /// @param _newMaxStakeAmount new max amount of token for staing like 1 ~ 10
    function changeStakeParams(
        address _newStakingToken,
        uint256 _newMaxTax,
        uint256 _newTaxRate,
        uint256 _newMaxStakeAmount
    ) public onlyOwner {
        stakingToken = _newStakingToken;
        maxTax = _newMaxTax;
        taxRate = _newTaxRate;
        maxStakeAmount = _newMaxStakeAmount;
    }

    /// @notice let the owner withdraw Token deposited like USDC, 2omb... from contract
    /// @param earnToken address of token to be withdrew
    function withdrawToken(address earnToken) public onlyOwner {
        // get balance of token in contract
        uint256 tokenBalance = IERC20(earnToken).balanceOf(address(this));
        require(tokenBalance > 0, "Owner has no balance to withdraw");
        // transfer all tokens to owner
        IERC20(earnToken).transfer(ownerWallet, tokenBalance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
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