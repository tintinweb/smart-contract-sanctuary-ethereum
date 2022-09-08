// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "hardhat/console.sol";

contract CollectiveVault is Ownable, ReentrancyGuard {
    bool initializer = false;
    IERC20 public XIV;
    uint256 public tokenCounter;
    uint256 public constant divisor = 10000;
    uint256 public fees;
    address public operator;

    // mapping for valid tokens
    mapping(uint256 => address) public Tokens;
    mapping(address => bool) public validTokens;

    //mapping for counter
    mapping(uint8 => mapping(address => uint256)) public counter;

    //mapping for priceFeeds
    mapping(address => address) public chainlinkAddress;

    //dynamic values for slots change by admin
    mapping(uint8 => SlotType) public slotPlan;
    struct SlotType {
        uint128 slot; //in seconds
        uint128 userlimit;
        uint256 minimumAmt;
    }
    struct PredictionSlot {
        uint256 totalAmount;
        uint256 finalPrice;
        uint248 endTime;
        bool status;
        address[] user;
    }
    //Prediction Details as per counter, predictionType, Token, Slot
    mapping(uint8 => mapping(address => mapping(uint256 => PredictionSlot)))
        public PredictionDetail;

    struct Prediction {
        uint256 amount;
        uint256 price;
        uint128 predictionTime;
        uint128 status; // 1 pending, 2 win, 3 loss
    }

    //Prediction by user
    mapping(uint8 => mapping(address => mapping(uint256 => mapping(address => Prediction))))
        public UserPrediction;

    event Predictions(
        uint256 indexed counter,
        uint256 amount,
        uint256 price,
        address token,
        uint256 totalAmount,
        uint88 endTime,
        uint8 indexed predictionType,
        address indexed user
    );

    event ResolvedPredictions(
        uint256 indexed counter,
        uint256 amount,
        uint256 price,
        address token,
        uint256 finalPrice,
        uint256 totalAmount,
        address indexed user,
        uint8 indexed predictionType,
        uint88 resolvedTime
    );

    function initialize(
        address xiv,
        address _owner,
        address _operator
    ) external {
        require(!initializer, "CV: Already instialised");
        initializer = true;
        _transferOwnership(_owner);
        operator = _operator;

        //Solo
        slotPlan[1].userlimit = 10;
        slotPlan[1].minimumAmt = 1000e18;
        slotPlan[1].slot = 10800;
        //Shared
        slotPlan[2].userlimit = 10;
        slotPlan[2].minimumAmt = 2000e18;
        slotPlan[2].slot = 10800;
        //User vs User
        slotPlan[3].userlimit = 2;
        slotPlan[3].minimumAmt = 3000e18;
        slotPlan[3].slot = 1800;

        XIV = IERC20(xiv);
        fees = 2500;
    }

    function predict(
        uint256 _amount,
        uint256 _price,
        uint8 _predictionType,
        address _token
    ) external nonReentrant {
        address user = _msgSender();
        require(_price > 0, "CV: Price should be greater than zero");
        require(
            (_predictionType == 1 ||
                _predictionType == 2 ||
                _predictionType == 3),
            "CV: PredictionType should be valid"
        );
        require(validTokens[_token], "CV: Token is not valid");

        SlotType storage slotDetails = slotPlan[_predictionType];
        require(_amount >= slotDetails.minimumAmt, "CV: Invalid Amount");
        uint256 adminFees = (_amount * fees) / divisor;
        //Transfer the XIV
        XIV.transferFrom(user, address(this), _amount);
        XIV.transfer(owner(), adminFees);
        uint256 amt = _amount - adminFees;

        //get counter of prediction details
        uint256 _counter = counter[_predictionType][_token];

        //create the predictionDetail according to slot
        PredictionSlot storage predictionDetails = PredictionDetail[
            _predictionType
        ][_token][_counter];

        if (predictionDetails.endTime > 0) {
            if (predictionDetails.endTime < block.timestamp) {
                //increment the counter
                counter[_predictionType][_token]++;
                _counter = counter[_predictionType][_token];

                predictionDetails = PredictionDetail[_predictionType][_token][
                    _counter
                ];

                predictionDetails.endTime = uint248(
                    block.timestamp + slotDetails.slot
                );
            }
        } else {
            //first time
            predictionDetails.endTime = uint248(
                block.timestamp + slotDetails.slot
            );
        }
        predictionDetails.totalAmount += amt;

        require(
            predictionDetails.user.length < slotDetails.userlimit,
            "CV: User limit exceeded"
        );

        predictionDetails.user.push(user);

        Prediction storage userDetails = UserPrediction[_predictionType][
            _token
        ][_counter][user];

        require(
            userDetails.status == 0,
            "CV: Can't participate twice in a slot"
        );

        userDetails.amount = amt;

        userDetails.price = _price;

        userDetails.predictionTime = uint128(block.timestamp);

        userDetails.status = 1; //pending

        //emit the event Predictions
        emit Predictions(
            _counter,
            _amount,
            _price,
            _token,
            predictionDetails.totalAmount,
            uint88(predictionDetails.endTime),
            _predictionType,
            user
        );
    }

    // Get users list for a particular slot and particular token
    function getUsersList(
        uint8 _predictionType,
        address _token,
        uint256 _counter
    ) public view returns (address[] memory users) {
        return PredictionDetail[_predictionType][_token][_counter].user;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    modifier onlyOperator() {
        require(operator == _msgSender(), "CV: caller is not the operator");
        _;
    }

    //resolving external hit by owner
    function resolving(
        uint8 _predictionType,
        address _token,
        uint256 _counter
    ) public onlyOperator {
        require(_counter > 0, "CV: counter should be greater than zero");
        require(
            (_predictionType == 1 ||
                _predictionType == 2 ||
                _predictionType == 3),
            "CV: PredictionType should be valid"
        );
        require(validTokens[_token], "CV: Token is not valid");

        //create the predictionDetail according to slot
        PredictionSlot storage predictionDetails = PredictionDetail[
            _predictionType
        ][_token][_counter];
        SlotType storage slotDetails = slotPlan[_predictionType];
        require(
            (predictionDetails.status == false &&
                predictionDetails.endTime > 0),
            "CV: End time error or resolved"
        );
        require((predictionDetails.endTime + (24 * 60 * 60)) < block.timestamp, "CV: Invalid resolved time");

        //call oracale for the final price;
        // uint256 finalPrice = 19 * 1e8;
        uint256 finalPrice = getLastestPrice(_token);
        require(_predictionType != 2, "CV: Prediction should be solo and user-user");
        //solo or user-user
        Prediction storage userDetails = UserPrediction[
            _predictionType
        ][_token][_counter][predictionDetails.user[0]];
        uint256 closest = userDetails.price;
        uint8 winnerCounter;
        address[] memory winners = new address[](slotDetails.userlimit); //winners array
        for (uint8 i = 0; i < predictionDetails.user.length; i++) {
            //get users
            address user = predictionDetails.user[i];
            userDetails = UserPrediction[_predictionType][_token][
                _counter
            ][user];

            uint256 a = abs(
                int256(userDetails.price) - int256(finalPrice)
            );
            uint256 b = abs(int256(closest) - int256(finalPrice));
          
            if (a < b) {
                //solo, user
                closest = userDetails.price;
                winners[winnerCounter] = user;
                winnerCounter++;
            } else if (a == b && winnerCounter == 0) {
                //for single user or equal price
                closest = userDetails.price;
                winners[winnerCounter] = user;
                winnerCounter++;
            } else {
                //loss for everyone
                userDetails.status = 3; //loss
                address t = _token;

                emit ResolvedPredictions(
                    _counter,
                    userDetails.amount,
                    userDetails.price,
                    t,
                    getLastestPrice(t),
                    0,
                    user,
                    _predictionType,
                    uint88(block.timestamp)
                );
            }
        }

        fundTransfer(
            _predictionType,
            _token,
            _counter,
            finalPrice,
            winners,
            predictionDetails.totalAmount,
            winnerCounter
        );
        predictionDetails.status = true;
        
    }

    //fund transfer to winners for solo and user-user
    function fundTransfer(
        uint8 _predictionType,
        address _token,
        uint256 _counter,
        uint256 _finalPrice,
        address[] memory winners,
        uint256 amount,
        uint8 _winnerCounter
    ) internal {
        for (uint8 i = 0; i < _winnerCounter; i++) {
            Prediction storage userDetails = UserPrediction[_predictionType][
                _token
            ][_counter][winners[i]];
            //last winner
            if (winners[i] == winners[_winnerCounter - 1]) {
                XIV.transfer(winners[_winnerCounter - 1], amount);
                userDetails.status = 2; //win
                emit ResolvedPredictions(
                    _counter,
                    userDetails.amount,
                    userDetails.price,
                    _token,
                    _finalPrice,
                    amount,
                    winners[i],
                    _predictionType,
                    uint88(block.timestamp)
                );
            } else {
                //loss for everyone
                userDetails.status = 3; //loss
                emit ResolvedPredictions(
                    _counter,
                    userDetails.amount,
                    userDetails.price,
                    _token,
                    _finalPrice,
                    0,
                    winners[i],
                    _predictionType,
                    uint88(block.timestamp)
                );
            }
        }
    }

    //resloving shared internal function
    function resolvingShared(
        address _token,
        uint256 _counter,
        address[] calldata winners,
        address oddUser
    ) public onlyOperator {
        PredictionSlot storage predictionDetails = PredictionDetail[2][_token][
            _counter
        ];

        require(
            !PredictionDetail[2][_token][_counter].status,
            "CV: Prediction already resolved."
        );
        require((predictionDetails.endTime + (24 * 60 * 60)) < block.timestamp, "CV: Invalid resolved time");

        uint256 amt = predictionDetails.totalAmount / winners.length;
        //decrease the total amount due to odd user
        if(oddUser != address(0)){
            Prediction storage userDetails = UserPrediction[2][_token][
                _counter
            ][oddUser];
            amt = (predictionDetails.totalAmount - userDetails.amount) / winners.length;
        }
        address t = _token;

        for (uint8 i = 0; i < predictionDetails.user.length; i++) {
            bool check = false;
            address user = predictionDetails.user[i];
            Prediction storage userDetails = UserPrediction[2][_token][
                _counter
            ][user];
            //handling odd user case
            if (oddUser != address(0) && user == oddUser) {
                userDetails.status = 3;
                //odd case
                XIV.transfer(oddUser, userDetails.amount);
                emit ResolvedPredictions(
                    _counter,
                    userDetails.amount,
                    userDetails.price,
                    t,
                    getLastestPrice(t),
                    0,
                    user,
                    2,
                    uint88(block.timestamp)
                );
                continue;
            }

            for (uint8 j = 0; j < winners.length; j++) {
                if (user == winners[j]) {
                    check = true;
                }
            }
            if (check) {
                //winner
                XIV.transfer(user, amt);
                userDetails.status = 2; //win
                emit ResolvedPredictions(
                    _counter,
                    userDetails.amount,
                    userDetails.price,
                    t,
                    getLastestPrice(t),
                    amt,
                    user,
                    2,
                    uint88(block.timestamp)
                );
            } else {
                //loser
                userDetails.status = 3; //loss
                emit ResolvedPredictions(
                    _counter,
                    userDetails.amount,
                    userDetails.price,
                    t,
                    getLastestPrice(t),
                    0,
                    user,
                    2,
                    uint88(block.timestamp)
                );
            }
        }
        predictionDetails.status = true;
    }

    // to get absolute value
    function abs(int256 x) private pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }

    //set admin commission (fees)
    function setAdminFees(uint256 per) public onlyOwner {
        require(per > 0, "CV: Percentage should be greater then zero");
        fees = per;
    }

    //add token and create counter for new token
    function addToken(address _tokenAddress) public onlyOwner {
        require(!(validTokens[_tokenAddress]), "CV: Token is already added.");
        Tokens[tokenCounter] = _tokenAddress;
        validTokens[_tokenAddress] = true;
        tokenCounter++;
        //creating the counter for 3 types of slots
        for (uint8 i = 1; i <= 3; i++) {
            counter[i][_tokenAddress] = 1;
        }
    }

    //add address for chainLink
    function addChainlinkAddress(
        address _tokenAddress,
        address _chainLinkAddress
    ) public onlyOwner {
        require((validTokens[_tokenAddress]), "CV: Token is disabled.");
        chainlinkAddress[_tokenAddress] = _chainLinkAddress;
    }

    //enable/ disable the tokens
    function setTokenAddress(address _tokenAddress, bool check)
        public
        onlyOwner
    {
        validTokens[_tokenAddress] = check;
    }

    //slotPlan Details
    function setSlotDetails(
        uint8 _predictionType,
        uint128 _slot,
        uint128 _userlimit,
        uint256 _minimumAmt
    ) external onlyOwner {
        require(
            (_predictionType == 1 ||
                _predictionType == 2 ||
                _predictionType == 3),
            "CV: PredictionType should be valid"
        );
        require(_slot > 0, "CV: Time can't be greater then zero");
        require(_userlimit > 0, "CV: UserLimit can't be greater then zero");
        require(_minimumAmt > 0, "CV: Minimum can't be greater then zero");
        slotPlan[_predictionType].slot = _slot;
        slotPlan[_predictionType].userlimit = _userlimit;
        slotPlan[_predictionType].minimumAmt = _minimumAmt;
    }
    // get latest price of the token
    function getLastestPrice(address _token) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            chainlinkAddress[_token]
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price);
    }
    //get decimals places for the token
    function getDecimals(address _token) public view returns (uint8 decimals) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            chainlinkAddress[_token]
        );

        return priceFeed.decimals();
    }
    //set the operator address
    function setOperator(address _operator) public onlyOwner {
        operator=_operator;
    }
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