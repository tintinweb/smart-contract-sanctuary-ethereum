// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Distamarkets is Ownable {
    event MarketCreated(address indexed creator, uint256 indexed marketId, string name);
    event StakeChanged(uint256 indexed stakeId, uint256 amount, uint256 indexed marketId, address indexed user);
    event MarketStateChanged(uint256 indexed marketId, MarketState);

    enum MarketState { OPEN, CLOSED, CANCELED }

    struct Market {
        // market details
        string title;
        string image;
        uint numOutcomes;
        uint256 totalStake;
        MarketState state;
        address creator;
        mapping(uint256 => MarketOutcome) outcomes;
    }

    struct MarketOutcome {
        // outcome details
        uint256 id;
        uint256 totalStake;
        bytes32 outcomeName;
        mapping(address => uint256) holders; // User => UserStake
    }

    struct UserStake {
        uint256 marketId;
        uint256 outcomeId;
        uint256 amount;
        address user;
    }

    Market[] markets;
    UserStake[] userStakes;
    mapping(address => uint256[]) stakesByUser; // User => UserStake Ids

    function createMarket(string calldata _title, string calldata _image, bytes32[] memory _outcomeNames) external returns(uint256) {
        markets.push();
        uint marketId = markets.length;
        
        Market storage market = markets[marketId - 1];
        market.title = _title;
        market.image = _image;
        market.numOutcomes = _outcomeNames.length;
        market.creator = msg.sender;
        market.state = MarketState.OPEN;

        for (uint i = 0; i < _outcomeNames.length; i++) {
            MarketOutcome storage outcome = market.outcomes[i];
            outcome.id = i;
            outcome.outcomeName = _outcomeNames[i];
        }

        emit MarketCreated(msg.sender, marketId, _title); 

        return marketId;
    }

    function addStake(uint256 _marketId, uint256 _outcomeId) external payable openMarket(_marketId) returns (uint256) {
        require(msg.value > 0, "Cannot add 0 stake");

        Market storage market = markets[_marketId - 1];
        MarketOutcome storage outcome = market.outcomes[_outcomeId];

        market.totalStake = market.totalStake + msg.value;
        outcome.totalStake = outcome.totalStake + msg.value;

        // user already has stake?
        uint256 stakeId = outcome.holders[msg.sender];
        UserStake storage stake;

        if (stakeId == 0) {
            // stake does not exist yet
            userStakes.push();
            stakeId = userStakes.length;
            stake = userStakes[stakeId - 1];
            stake.marketId = _marketId;
            stake.outcomeId = _outcomeId;

            stakesByUser[msg.sender].push(stakeId);
            outcome.holders[msg.sender] = stakeId;
        } else {
            // loading existing stake
            stake = userStakes[stakeId - 1];
        }
        
        // update stake amount
        stake.amount = stake.amount + msg.value;

        emit StakeChanged(stakeId, msg.value, _marketId, msg.sender);
        
        return stake.amount;
    }

    function removeStake(uint256 _stakeId, uint256 _amount) external payable openMarket(userStakes[_stakeId - 1].marketId) returns (uint256) {
        require(_amount > 0, "Cannot remove 0 stake");

        UserStake storage stake = userStakes[_stakeId - 1];

        Market storage market = markets[stake.marketId - 1];
        MarketOutcome storage outcome = market.outcomes[stake.outcomeId];

        require(stake.amount >= _amount, "Amount exceeds current stake");

        market.totalStake = market.totalStake - _amount;
        outcome.totalStake = outcome.totalStake - _amount;
        stake.amount = stake.amount - _amount;

        payable(msg.sender).transfer(_amount);

        emit StakeChanged(_stakeId, msg.value, stake.marketId, msg.sender);

        return stake.amount;
    }

    function getMarket(uint256 _marketId) public view returns (string memory, string memory, MarketState, uint256, bytes32[] memory, uint256[] memory) {
        Market storage market = markets[_marketId - 1];
        
        bytes32[] memory outcomeNames = new bytes32[](market.numOutcomes);
        uint256[] memory outcomeStakes = new uint256[](market.numOutcomes);

        for (uint i = 0; i < market.numOutcomes; i++) {
            outcomeNames[i] = (market.outcomes[i].outcomeName);
            outcomeStakes[i] = (market.outcomes[i].totalStake);
        }

        return (market.title, market.image, market.state, market.totalStake, outcomeNames, outcomeStakes);
    }

    function getMarketIndex() public view returns (uint256) {
        return markets.length;
    }

    function getStakeId(address _holder, uint256 _marketId, uint256 _outcomeId) public view returns (uint256) {
        return markets[_marketId - 1].outcomes[_outcomeId].holders[_holder];
    }

    function getMarketTotalStake(uint256 _marketId) public view returns (uint256) {
        return markets[_marketId - 1].totalStake;
    }

    function getUserStakes(address _address) public view returns(uint256[] memory) {
        return stakesByUser[_address];
    }

    function getStake(uint256 stakeId) public view returns(UserStake memory) {
        return userStakes[stakeId - 1];
    }

    modifier openMarket(uint256 _marketId) {
        require(markets[_marketId - 1].state == MarketState.OPEN);
        _;
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