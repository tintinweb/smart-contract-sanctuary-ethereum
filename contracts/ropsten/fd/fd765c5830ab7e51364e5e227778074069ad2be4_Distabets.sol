/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

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

// File: contracts/Distabets.sol


pragma solidity >=0.8.6;


contract Distabets is Ownable {
    event MarketCreated(address indexed creator, uint indexed marketId, string name);

    uint256 public constant ONE = 10**18;

    struct Market {
        // market details
        string title;
        uint numOutcomes;
        mapping(uint256 => MarketOutcome) outcomes;
        // total stake
    }

    struct MarketOutcome {
        // outcome details
        uint256 marketId;
        uint256 id;
        bytes32 outcomeName;
        mapping(address => uint256) holders;
    }

    uint256[] marketIds;
    mapping(uint256 => Market) markets;
    uint256 public marketIndex;

    function createMarket(string calldata _title, bytes32[] memory _outcomeNames) external payable returns(uint256) {
        //require(msg.value > 0, "stake needs to be > 0");

        uint256 marketId = marketIndex;
        marketIds.push(marketId);

        Market storage market = markets[marketId];
        market.title = _title;
        market.numOutcomes = _outcomeNames.length;

        for (uint i = 0; i < _outcomeNames.length; i++) {
            MarketOutcome storage outcome = market.outcomes[i];
            outcome.marketId = marketId;
            outcome.id = i;
            outcome.outcomeName = _outcomeNames[i];
        }

        marketIndex = marketIndex + 1;
        return marketId;
    }

    function getMarket(uint256 _marketId) public view returns (string memory, bytes32[] memory) {
        Market storage market = markets[_marketId];
        
        bytes32[] memory outcomeNames = new bytes32[](market.numOutcomes);

        for (uint i = 0; i < market.numOutcomes; i++) {
            outcomeNames[i] = (market.outcomes[i].outcomeName);
        }
        return (market.title, outcomeNames);
    }


}