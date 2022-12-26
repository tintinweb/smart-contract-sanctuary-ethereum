// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "Staking.sol";
import "Ownable.sol";
import "Pausable.sol";
import "KeeperCompatible.sol";
import "ReentrancyGuard.sol";
import "AccessControlEnumerable.sol";
import "AggregatorV3Interface.sol";

error withdrawalErrorOnUpKeep();

/**
    @title MeetsMeta Staking Manager Contract
    @author ^M
 */
contract Staking_Manager is
    Ownable,
    Pausable,
    ReentrancyGuard,
    AccessControlEnumerable,
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
    int256 public creating_staking_contract_fee;

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
        string scholarshipID,
        address indexed client,
        address holder,
        address player,
        address collection,
        uint256 tokenId,
        uint256 indexed client_ID,
        uint256 stakingID,
        bool indexed status
    );
    // Creating Staking Contract fee has been updated
    event creating_staking_contract_fee_updated(int256 new_amount);

    constructor(address _linkAggAdd, int256 _creating_staking_contract_fee) {
        // setting the beneficiary address for the first time
        beneficiary_add = _msgSender();
        priceFeed = AggregatorV3Interface(_linkAggAdd);
        creating_staking_contract_fee = _creating_staking_contract_fee;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
    @dev updates the beneficiary wallet to the one that sent along with function call
    @param _new_wallet is the new beneficiary address
     */
    function update_beneficiary_add(address _new_wallet)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        beneficiary_add = _new_wallet;
        emit benecifiary_updated(beneficiary_add);
    }

    /**
    @dev withdraw all the ETH holdings to the beneficiary address 
    */
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
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
    @dev this is a rescue function in case of any ERC20 mistake deposit
    @param _contract_address is the token contract address
    @notice this function withdraw all holdings of the token to the beneficiarys' address
    */
    function rescue_erc20(address _contract_address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        IERC20(_contract_address).transfer(
            beneficiary_add,
            IERC20(_contract_address).balanceOf(address(this))
        );
        emit withdraw_event(_contract_address);
    }

    /** 
    @dev this is a rescue function in case of any ERC721 mistake deposit
    @param _contract_address is the token contract address
    @param _tokenID of the ERC721 item
    @notice this function withdraw the ERC721 token to the beneficiarys' address
    */
    function rescue_erc721(address _contract_address, uint256 _tokenID)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
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
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        priceFeed = AggregatorV3Interface(_newAggAdd);
    }

    /**
    @dev updating the creating staking contract fee
    @param _new_fee new fee in USD * 1e18
    @notice only owner can perform this action
     */
    function set_fee(int256 _new_fee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        creating_staking_contract_fee = _new_fee;
        emit creating_staking_contract_fee_updated(_new_fee);
    }

    /**
    @dev getting the latest price of ETH from chainlink
    @notice before staking call this function to get the exact ETH worth of fee
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        int256 stakePrice = (creating_staking_contract_fee * 1e18) /
            (price * 1e18);
        return (stakePrice * int256(10**priceFeed.decimals()));
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
    ) public payable nonReentrant whenNotPaused {
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
        contract_owner[address(staking_contract)] = _owner;
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
        string memory _scholarshipID,
        address _holder,
        address _player,
        address _collection,
        uint256 _tokenId,
        uint256 _ID,
        uint256 _stakingID,
        bool _status
    ) external {
        if (contract_owner[_msgSender()] != address(0)) {
            emit client_event(
                _scholarshipID,
                _msgSender(),
                _holder,
                _player,
                _collection,
                _tokenId,
                _ID,
                _stakingID,
                _status
            );
        }
    }

    /**
     * @dev Pauses any transaction.
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all transactions.
     * Requirements:
     *
     * - the caller   must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "IStaking_Manager.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "AccessControlEnumerable.sol";
import "AggregatorV3Interface.sol";

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

contract Staking is Pausable, ReentrancyGuard, AccessControlEnumerable {
    /**
    @dev keeps the owner/deployer address and CAN NOT be changed after setting for the first time during construction
     */
    address private immutable owner;

    /**
    @dev keeps the manager contract address
     */
    address private immutable manager_contract;

    /**
    @dev has the staking fee in USD
     */
    int256 private fee;

    /**
    @dev minimum percentage in bp (*100)
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
        string scholarshipID;
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
    @dev approved NFT collection which holders of tokens from them can stake their tokens
     */
    address[] private approved_collections;

    /**
    @dev in this array we hold all of stakes information
     */
    StakeInfo[] public all_stakes;

    // Events
    // minimum staking percentage has been updated
    event minimum_percentage_updated(uint256 new_min);
    // Staking fee has been updated
    event staking_fee_updated(int256 new_amount);
    // fires when a Withdrawal happens
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
        uint256 tokenId,
        string scholarshipID
    );
    // unstaking
    event Unstaked(
        address indexed holder,
        address indexed player,
        address indexed collection,
        uint256 tokenId,
        string scholarshipID
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
        fee = _fee * 1e18;
        priceFeed = _linkAggAdd;
        client_ID = _client_ID;
        min_percentage = _min_percentage;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        emit created(address(this));
    }

    /**
    @dev will update chainlink aggregator v3 address,
    @param _newAggAdd is the new ETH/USD Aggregator address for price feed
     */
    function setChainlinkAggAdd(address _newAggAdd)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        priceFeed = AggregatorV3Interface(_newAggAdd);
    }

    /**
    @dev getting the latest price of ETH from chainlink
    @notice before staking, call this function to get the exact ETH worth of fee
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        int256 stakePrice = (fee * 1e18) / (price * 1e18);
        return (stakePrice * int256(10**priceFeed.decimals()));
    }

    /**
    @dev updating the minimum percentage required for a staking
    @param _new_min_percentage for staking
    @notice only Admin can perform this action
     */
    function set_min_percentage(uint256 _new_min_percentage)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        min_percentage = _new_min_percentage;
        emit minimum_percentage_updated(min_percentage);
    }

    /**
    @dev updating the staking fee
    @param _new_fee of the staking
    @notice only Admin can perform this action
     */
    function set_fee(int256 _new_fee)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
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
    function withdraw() public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(owner).transfer(address(this).balance);
        emit withdraw_event(owner);
    }

    /** 
    @dev this is a rescue function in case of any ERC20 mistake deposit
    @param _contract_address is the token contract address
    @notice this function withdraw all holdings of the token to the owners' address
    */
    function rescue_erc20(address _contract_address)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(_contract_address).transfer(
            owner,
            IERC20(_contract_address).balanceOf(address(this))
        );
        emit withdraw_event(_contract_address);
    }

    /** 
    @dev this is a rescue function in case of any ERC721 mistake deposit
    @param _contract_address is the token contract address
    @param _tokenID of the ERC721 item
    @notice this function withdraw the ERC721 token to the owners' address. **only NFTs which are not in the approved list
    */
    function rescue_erc721(address _contract_address, uint256 _tokenID)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
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
    function approve(address _collection_address)
        public
        whenNotPaused
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        approved_collections.push(_collection_address);
        emit collection_approved(_collection_address);
    }

    /**
    @dev this will remove an approved NFT collection address from the list
    @param _collection_address to be removed from approved list
     */
    function remove_approved(address _collection_address)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < approved_collections.length; i++) {
            if (approved_collections[i] == _collection_address) {
                approved_collections[i] = approved_collections[
                    approved_collections.length - 1
                ];
                approved_collections.pop();
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
    ) public payable nonReentrant whenNotPaused {
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

        if (_player == address(0) || _collection == address(0)) {
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
            _scholarshipID,
            msg.sender,
            _player,
            _collection,
            _tokenId,
            client_ID,
            all_stakes.length - 1,
            false
        );
        // Firing the Staked event
        emit Staked(msg.sender, _player, _collection, _tokenId, _scholarshipID);
    }

    /**
    @dev unstake function
    @param _stakeId of the item. this is the index of the item in allStakes array
    */
    function unstake(uint256 _stakeId) public nonReentrant whenNotPaused {
        if (
            (_stakeId >= all_stakes.length || _stakeId < 0) ||
            (all_stakes[_stakeId].holder != msg.sender && msg.sender != owner)
        ) {
            revert PermissionDenied();
        }

        StakeInfo memory _stake = all_stakes[_stakeId];
        if (
            (_stake.stakedDate + _stake.lockingPeriod) > block.timestamp &&
            (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
        ) {
            revert CannotUnstakeBeforeEnd();
        }

        // deleting all the info before transfering the NFT
        uint256 i = 0;
        for (i = 0; i < holders[_stake.holder].length; i++) {
            if (holders[_stake.holder][i] == _stakeId) {
                holders[_stake.holder][i] = holders[_stake.holder][
                    holders[_stake.holder].length - 1
                ];
                holders[_stake.holder].pop();
                break;
            }
        }
        for (i = 0; i < players[_stake.player].length; i++) {
            if (players[_stake.player][i] == _stakeId) {
                players[_stake.player][i] = players[_stake.player][
                    players[_stake.player].length - 1
                ];
                players[_stake.player].pop();
                break;
            }
        }

        // delete the stake item
        all_stakes[_stakeId] = all_stakes[all_stakes.length - 1];
        all_stakes.pop();

        IERC721(_stake.collection).transferFrom(
            address(this),
            _stake.holder,
            _stake.tokenId
        );

        // Firing an event on manager contract
        IStaking_Manager(manager_contract).client_updated(
            _stake.scholarshipID,
            _stake.holder,
            _stake.player,
            _stake.collection,
            _stake.tokenId,
            client_ID,
            _stakeId,
            true
        );

        emit Unstaked(
            _stake.holder,
            _stake.player,
            _stake.collection,
            _stake.tokenId,
            _stake.scholarshipID
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

    /**
     * @dev Pauses any transaction.
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all transactions.
     * Requirements:
     *
     * - the caller   must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IStaking_Manager {
    function client_updated(
        string memory _scholarshipID,
        address _holder,
        address _player,
        address _collection,
        uint256 _tokenId,
        uint256 _ID,
        uint256 _stakingID,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControlEnumerable.sol";
import "AccessControl.sol";
import "EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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