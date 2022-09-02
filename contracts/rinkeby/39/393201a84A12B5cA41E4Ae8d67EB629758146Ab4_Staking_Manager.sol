// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "ReentrancyGuard.sol";
import "Ownable.sol";
import "AggregatorV3Interface.sol";
import "KeeperCompatible.sol";
import "Staking.sol";

error withdrawalErrorOnUpKeep();

/**
    @title MeetsMeta Staking Manager Contract
    @author ^M
 */
contract Staking_Manager is
    Ownable,
    ReentrancyGuard,
    KeeperCompatibleInterface
{
    /**
    @dev chainlink aggregator price feed
    */

    AggregatorV3Interface internal priceFeed;

    /**
    @dev beneficiary address - address that withdrawal send funds to
    */
    address public beneficiary_add;

    /**
    @dev Creating staking contract fee - in USD
    */
    int256 public creating_staking_contract_fee = 20;

    /**
    @dev contract address => owner - mapping
    */
    mapping(address => address) private contract_owner;

    /**
    @dev mapping of owner address to created staking contracts
     */
    mapping(address => address[]) private owners_staking_contracts;

    // Events
    // updating beneficiary address
    event benecifiary_updated(address new_wallet);
    // withdrawing any amount of token/ETH/NFT from the contract
    event withdraw_event(address token_address);
    // new staking contract created
    event new_staking_contract_created(
        address new_staking_contract_address,
        address owner
    );
    // new event happened on a client contract
    event client_event(
        address indexed client,
        address holder,
        address player,
        address collection,
        uint256 tokenId,
        uint256 indexed client_ID,
        bool indexed status
    );
    // Creating Staking Contract fee has been updated
    event creating_staking_contract_fee_updated(int256 new_amount);

    constructor(address _linkAggAdd) {
        // setting the beneficiary address for the first time
        beneficiary_add = _msgSender();
        priceFeed = AggregatorV3Interface(_linkAggAdd);
    }

    /**
    @dev updates the beneficiary wallet to the one that sent along with function call
    @param _new_wallet is the new beneficiary address
     */
    function update_beneficiary_add(address _new_wallet)
        public
        onlyOwner
        nonReentrant
    {
        beneficiary_add = _new_wallet;
        emit benecifiary_updated(beneficiary_add);
    }

    /**
    @dev withdraw all the ETH holdings to the beneficiary address 
    */
    function withdraw() public onlyOwner nonReentrant {
        payable(beneficiary_add).transfer(address(this).balance);
        emit withdraw_event(beneficiary_add);
    }

    /**
    @dev called by chainlink keepers in order to check whether should perform an UpKeep or not
    */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (address(this).balance >= 1e18) {
            upkeepNeeded = true;
            performData = bytes("");
        } else {
            upkeepNeeded = false;
            performData = bytes("");
        }
    }

    /**
    @dev performing upkeep, here it will be withdrawal
     */
    function performUpkeep(bytes calldata) external override {
        if (address(this).balance >= 1e18) {
            payable(beneficiary_add).transfer(address(this).balance);
            emit withdraw_event(beneficiary_add);
        } else {
            revert withdrawalErrorOnUpKeep();
        }
    }

    /** 
    @dev this is a withdrawal in case of any ERC20 mistake deposit
    @param _contract_address is the token contract address
    @notice this function withdraw all holdings of the token to the beneficiarys' address
    */
    function withdraw_erc20(address _contract_address)
        public
        onlyOwner
        nonReentrant
    {
        IERC20(_contract_address).transfer(
            beneficiary_add,
            IERC20(_contract_address).balanceOf(address(this))
        );
        emit withdraw_event(_contract_address);
    }

    /** 
    @dev this is a withdrawal in case of any ERC721 mistake deposit
    @param _contract_address is the token contract address
    @param _tokenID of the ERC721 item
    @notice this function withdraw the ERC721 token to the beneficiarys' address
    */
    function withdraw_erc721(address _contract_address, uint256 _tokenID)
        public
        onlyOwner
        nonReentrant
    {
        IERC721(_contract_address).transferFrom(
            address(this),
            beneficiary_add,
            _tokenID
        );
        emit withdraw_event(_contract_address);
    }

    /**
    @dev will update chainlink aggregator v3 address,
    @param _newAggAdd is the new ETH/USD Aggregator address for price feed
     */
    function setChainlinkAggAdd(address _newAggAdd)
        public
        nonReentrant
        onlyOwner
    {
        priceFeed = AggregatorV3Interface(_newAggAdd);
    }

    /**
    @dev updating the creating staking contract fee
    @param _new_fee new fee in USD
    @notice only owner can perform this action
     */
    function set_fee(int256 _new_fee) public onlyOwner nonReentrant {
        creating_staking_contract_fee = _new_fee;
        emit creating_staking_contract_fee_updated(_new_fee);
    }

    /**
    @dev getting the latest price of ETH from chainlink
    @notice before staking call this function to get the exact ETH worth of fee
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        int256 stakeEthPrice = ((creating_staking_contract_fee * (10**18)) /
            price);
        int256 result = stakeEthPrice;
        while (stakeEthPrice != 0) {
            stakeEthPrice /= 10;
            result *= 10;
        }
        return (result / 10);
    }

    /**
    @dev this will create the new staking contract and set the owners' and beneficiarys' address along with initial staking fee and minimum percentage
    @param _owner address of the new staking contract
    @param _initial_staking_fee which user's paying to stake his/her pass into the contract
    @param _client_ID of the client
    @param _min_percentage for staking
     */

    function create_staking(
        address _owner,
        int256 _initial_staking_fee,
        uint256 _client_ID,
        uint256 _min_percentage
    ) public payable nonReentrant {
        if (msg.value < uint256(getLatestPrice())) {
            revert NotEnoughETH();
        }

        Staking staking_contract = new Staking(
            _owner,
            priceFeed,
            _initial_staking_fee,
            _min_percentage,
            _client_ID
        );
        owners_staking_contracts[_owner].push(address(staking_contract));
        emit new_staking_contract_created(address(staking_contract), _owner);
    }

    /**
    @dev getting all owners created staking contracts
     */
    function get_owners_staking_contracts(address _owner)
        public
        view
        returns (address[] memory)
    {
        return owners_staking_contracts[_owner];
    }

    /**
    @dev getting owner of a staking contract
     */
    function get_contract_owner(address _contract_add)
        public
        view
        returns (address)
    {
        return contract_owner[_contract_add];
    }

    /**
    @dev this will be called whenever someone STAKED something into the any clients contract
    @param _holder owner of the token
    @param _player to whom it staked
    @param _collection of the token
    @param _tokenId of the token
    @param _ID of the client
    @param _status if its false means its staked, if its true means its unstaked
     */
    function client_updated(
        address _holder,
        address _player,
        address _collection,
        uint256 _tokenId,
        uint256 _ID,
        bool _status
    ) external {
        if (contract_owner[msg.sender] != address(0)) {
            emit client_event(
                msg.sender,
                _holder,
                _player,
                _collection,
                _tokenId,
                _ID,
                _status
            );
        }
    }

    /**
    @dev should be deleted before mainnet deploy
     */
    function pay() public payable {
        emit withdraw_event(address(this));
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
pragma solidity ^0.8.0;

import "KeeperBase.sol";
import "KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "ReentrancyGuard.sol";
import "AggregatorV3Interface.sol";

interface IStaking_Manager {
    function client_updated(
        address _holder,
        address _player,
        address _collection,
        uint256 _tokenId,
        uint256 _ID,
        bool _status
    ) external;
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

error notOwner();
error notAllowed();
error NotApprovedCollection();
error NotEnoughETH();
error Address0();
error PercentageIsLessThan35();
error PermissionDenied();
error CannotUnstakeBeforeEnd();

/**
    @title MeetsMeta Staking Contract
    @author ^M
 */

contract Staking is ReentrancyGuard {
    /**
    @dev keeps the owner address and cannot be changed after setting for the first time in constructor
     */
    address private immutable owner;

    /**
    @dev manager_contract address which manager contract address
     */
    address private immutable manager_contract;

    /**
    @dev has the staking fee in USD
     */
    int256 private fee;

    /**
    @dev minimum percentage in bp
     */
    uint256 public min_percentage;

    /**
    @dev Client ID
    */
    uint256 public immutable client_ID;

    /**
    @dev struct for stakes info
     */
    struct StakeInfo {
        string _scholarshipID;
        address player;
        address holder;
        address collection;
        uint256 tokenId;
        uint256 percentage;
        uint256 stakedDate;
        uint256 lockingPeriod;
        uint256 id;
    }

    /**
    @dev chainlink aggregator price feed
    */
    AggregatorV3Interface internal priceFeed;

    /**
    @dev holders mapping to an array of indexes of their staked passports
     */
    mapping(address => uint256[]) private holders;

    /**
    @dev players mapping to an array of indexes of their assigned passports
     */
    mapping(address => uint256[]) private players;

    /**
    @dev approved NFT collection which holders of tokens from allowed to stake their passes 
     */
    address[] private approved_collections;

    /**
    @dev in this array we hold all of stakes information
     */
    StakeInfo[] public all_stakes;

    // Events
    // minimum staking percentage has been updated
    event minimum_staking_updated(uint256 new_min);
    // Staking fee has been updated
    event staking_fee_updated(int256 new_amount);
    // Withdrawal happen
    event withdraw_event(address token_contract);
    // since its untransferable contract, in constructor a created event will be emitted
    event created(address contract_add);
    // collection approved
    event collection_approved(address new_collection);
    // collection removed from approved list
    event approved_collection_removed(address _collection);
    // new staking
    event Staked(
        address indexed holder,
        address indexed player,
        address collection,
        uint256 tokenId
    );
    // unstaking
    event Unstaked(
        address indexed holder,
        address indexed player,
        address indexed collection,
        uint256 tokenId
    );

    // constructor
    constructor(
        address _owner,
        AggregatorV3Interface _linkAggAdd,
        int256 _fee,
        uint256 _min_percentage,
        uint256 _client_ID
    ) {
        owner = _owner;
        manager_contract = msg.sender;
        fee = _fee;
        priceFeed = _linkAggAdd;
        client_ID = _client_ID;
        min_percentage = _min_percentage;
        emit created(address(this));
    }

    /**
    @dev will update chainlink aggregator v3 address,
    @param _newAggAdd is the new ETH/USD Aggregator address for price feed
     */
    function setChainlinkAggAdd(address _newAggAdd) public nonReentrant {
        if (msg.sender != owner) {
            revert notOwner();
        }
        priceFeed = AggregatorV3Interface(_newAggAdd);
    }

    /**
    @dev getting the latest price of ETH from chainlink

    
    @notice before staking call this function to get the exact ETH worth of fee
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        int256 stakeEthPrice = ((fee * (10**18)) / price);
        int256 result = stakeEthPrice;
        while (stakeEthPrice != 0) {
            stakeEthPrice /= 10;
            result *= 10;
        }
        return (result / 10);
    }

    /**
    @dev updating the minimum percentage required for a staking
    @param _new_min_percentage for staking
    @notice only owner can perform this action
     */
    function set_min_percentage(uint256 _new_min_percentage)
        public
        nonReentrant
    {
        if (msg.sender != owner) {
            revert notOwner();
        }
        min_percentage = _new_min_percentage;
        emit minimum_staking_updated(min_percentage);
    }

    /**
    @dev updating the staking fee
    @param _new_fee of the staking
    @notice only owner can perform this action
     */
    function set_fee(int256 _new_fee) public nonReentrant {
        if (msg.sender != owner) {
            revert notOwner();
        }
        fee = _new_fee;
        emit staking_fee_updated(_new_fee);
    }

    /**
    @dev getter for the staking fee
     */
    function get_fee() public view returns (int256) {
        return fee;
    }

    /**
    @dev this is to withdraw staking fees
    @notice only owner can call this function any contract ETH balance will be transfered to owners address
     */
    function withdraw() public nonReentrant {
        if (msg.sender != owner) {
            revert notOwner();
        }
        payable(owner).transfer(address(this).balance);
        emit withdraw_event(owner);
    }

    /** 
    @dev this is a withdrawal in case of any ERC20 mistake deposit
    @param _contract_address is the token contract address
    @notice this function withdraw all holdings of the token to the owners' address
    */
    function withdraw_erc20(address _contract_address) public nonReentrant {
        if (msg.sender != owner) {
            revert notOwner();
        }
        IERC20(_contract_address).transfer(
            owner,
            IERC20(_contract_address).balanceOf(address(this))
        );
        emit withdraw_event(_contract_address);
    }

    /** 
    @dev this is a withdrawal in case of any ERC721 mistake deposit
    @param _contract_address is the token contract address
    @param _tokenID of the ERC721 item
    @notice this function withdraw the ERC721 token to the owners' address. **only NFTs which are not in the approved list
    */
    function withdraw_erc721(address _contract_address, uint256 _tokenID)
        public
        nonReentrant
    {
        if (msg.sender != owner) {
            revert notOwner();
        }
        for (uint256 i = 0; i < approved_collections.length; i++) {
            if (approved_collections[i] == _contract_address) {
                revert notAllowed();
            }
        }
        IERC721(_contract_address).transferFrom(address(this), owner, _tokenID);
        emit withdraw_event(_contract_address);
    }

    /**
    @dev this will add a new approved NFT collection address to the list
    @param _collection_address to be listed as approved
     */
    function approve(address _collection_address) public nonReentrant {
        if (msg.sender != owner) {
            revert notOwner();
        }
        approved_collections.push(_collection_address);
        emit collection_approved(_collection_address);
    }

    /**
    @dev this will remove an approved NFT collection address from the list
    @param _collection_address to be removed from approved list
     */
    function remove_approved(address _collection_address) public nonReentrant {
        if (msg.sender != owner) {
            revert notOwner();
        }
        for (uint256 i = 0; i < approved_collections.length; i++) {
            if (approved_collections[i] == _collection_address) {
                delete approved_collections[i];
                break;
            }
        }
        emit approved_collection_removed(_collection_address);
    }

    /**
    @dev getter for the list of approved collections
     */
    function get_approved_collections() public view returns (address[] memory) {
        return approved_collections;
    }

    /**
    @dev getter for the all stakes
     */
    function get_all_stakes() public view returns (StakeInfo[] memory) {
        return all_stakes;
    }

    /**
    @dev stake function
    @param _player address
    @param _collection address
    @param _tokenId in the collection
    @param _percentage of earnings which holder will share with the player. **should be multiplied by 100 before passing**
    @param _lockingPeriod of the token in seconds timestamp
    @param _scholarshipID the ID of the scholarship
     */
    function stake(
        address _player,
        address _collection,
        uint256 _tokenId,
        uint256 _percentage,
        uint256 _lockingPeriod,
        string calldata _scholarshipID
    ) public payable nonReentrant {
        bool isApproved = false;
        for (uint256 i = 0; i < approved_collections.length; i++) {
            if (approved_collections[i] == _collection) {
                isApproved = true;
                break;
            }
        }
        if (!isApproved) {
            revert NotApprovedCollection();
        }

        if (msg.value < uint256(getLatestPrice())) {
            revert NotEnoughETH();
        }

        // percentage should be in bp
        if (_percentage < min_percentage) {
            revert PercentageIsLessThan35();
        }

        if (_player == address(0)) {
            revert Address0();
        }

        IERC721(_collection).transferFrom(msg.sender, address(this), _tokenId);

        all_stakes.push(
            StakeInfo(
                _scholarshipID,
                _player,
                msg.sender,
                _collection,
                _tokenId,
                _percentage,
                block.timestamp,
                _lockingPeriod,
                all_stakes.length
            )
        );
        holders[msg.sender].push(all_stakes.length - 1);
        players[_player].push(all_stakes.length - 1);

        // Firing an event on manager contract
        IStaking_Manager(manager_contract).client_updated(
            msg.sender,
            _player,
            _collection,
            _tokenId,
            client_ID,
            false
        );
        // Firing the Staked event
        emit Staked(msg.sender, _player, _collection, _tokenId);
    }

    /**
    @dev unstake function
    @param _stakeId of the item. this is the index of the item in allStakes array
    */
    function unstake(uint256 _stakeId) public nonReentrant {
        if (
            (_stakeId >= all_stakes.length || _stakeId < 0) ||
            (all_stakes[_stakeId].holder != msg.sender && msg.sender != owner)
        ) {
            revert PermissionDenied();
        }

        StakeInfo memory _stake = all_stakes[_stakeId];
        if (
            (_stake.stakedDate + _stake.lockingPeriod) > block.timestamp &&
            msg.sender != owner
        ) {
            revert CannotUnstakeBeforeEnd();
        }

        // deleting all the info before transfering the NFT
        uint256 i = 0;
        for (i = 0; i < holders[_stake.holder].length; i++) {
            if (holders[_stake.holder][i] == _stakeId) {
                delete holders[_stake.holder][i];
                break;
            }
        }
        for (i = 0; i < players[_stake.player].length; i++) {
            if (players[_stake.player][i] == _stakeId) {
                delete players[_stake.player][i];
                break;
            }
        }
        delete all_stakes[_stakeId];

        IERC721(_stake.collection).transferFrom(
            address(this),
            _stake.holder,
            _stake.tokenId
        );

        // Firing an event on manager contract
        IStaking_Manager(manager_contract).client_updated(
            _stake.holder,
            _stake.player,
            _stake.collection,
            _stake.tokenId,
            client_ID,
            true
        );

        emit Unstaked(
            _stake.holder,
            _stake.player,
            _stake.collection,
            _stake.tokenId
        );
    }

    /**
    @dev getting the player info
    @param _player address
    @return an array of players assigned passports
     */
    function getPlayerInfo(address _player)
        public
        view
        returns (StakeInfo[] memory)
    {
        uint256[] memory playerIds = players[_player];
        if (playerIds.length == 0) {
            return new StakeInfo[](1);
        } else {
            StakeInfo[] memory _results = new StakeInfo[](playerIds.length);
            for (uint256 i = 0; i < playerIds.length; i++) {
                _results[i] = all_stakes[playerIds[i]];
            }
            return _results;
        }
    }

    /**
    @dev getting holders info
    @param _holder address
    @return holders all staked passports info
     */
    function getHolderInfo(address _holder)
        public
        view
        returns (StakeInfo[] memory)
    {
        uint256[] memory holderIds = holders[_holder];
        if (holderIds.length == 0) {
            return new StakeInfo[](1);
        } else {
            StakeInfo[] memory _results = new StakeInfo[](holderIds.length);
            for (uint256 i = 0; i < holderIds.length; i++) {
                _results[i] = all_stakes[holderIds[i]];
            }
            return _results;
        }
    }

    /**
    @dev all staked info
    @return a list of stakes info
     */
    function getAllInfo() public view returns (StakeInfo[] memory) {
        return all_stakes;
    }
}