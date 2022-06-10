// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "IUniswapV3Pool.sol";
import "OwnableUpgradeable.sol";
import "AccessControlUpgradeable.sol";

import "ICryptoPageBank.sol";
import "ICryptoPageToken.sol";
import "ICryptoPageCalcUserRate.sol";
import "ICryptoPageOracle.sol";

import {DataTypes} from "DataTypes.sol";

/// @title The contract calculates amount and mint / burn PAGE tokens
/// @author Crypto.Page Team
/// @notice
/// @dev 
contract PageBank is
    Initializable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    IPageBank
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant UPDATER_FEE_ROLE = keccak256("UPDATER_FEE_ROLE");
    bytes32 public constant DEFINE_FEE_ROLE = keccak256("DEFINE_FEE_ROLE");
    bytes32 public constant CHANGE_PRICE_ROLE = keccak256("CHANGE_PRICE_ROLE");
    bytes32 public constant VOTE_FOR_EARN_ROLE = keccak256("VOTE_FOR_EARN_ROLE");

    uint256 public FOR_MINT_GAS_AMOUNT = 145000;
    uint256 public FOR_BURN_GAS_AMOUNT = 95000;

    IUniswapV3Pool private wethPagePool;
    IPageOracle public oracle;
    uint256 public staticWETHPagePrice = 600;

    /// Address of Crypto.Page treasury
    address public treasury;
    /// Address of CryptoPageNFT contract
    address public nft;

    uint256 public ALL_PERCENT = 10000;
    /// Treasury fee (1000 is 10%, 100 is 1% 10 is 0.1%)
    uint256 public treasuryFee = 1000;

    /// CryptoPageToken interface
    IPageToken public token;
    IPageCalcUserRate public calcUserRate;

    struct CommunityFee {
        uint64 createPostOwnerFee;
        uint64 createPostCreatorFee;
        uint64 removePostOwnerFee;
        uint64 removePostCreatorFee;

        uint64 createCommentOwnerFee;
        uint64 createCommentCreatorFee;
        uint64 removeCommentOwnerFee;
        uint64 removeCommentCreatorFee;
    }

    mapping(uint256 => CommunityFee) private communityFee;

    // user -> communityId -> finished time
    mapping(address => mapping(uint256 => uint256)) private endPrivacyTime;
    // communityId -> balance of PAGE tokens
    mapping(uint256 => uint256) private communityBalance;
    // communityId -> price for privacy access
    mapping(uint256 => uint256) private privacyPrice;

    uint64 public defaultCreatePostOwnerFee = 4500;
    uint64 public defaultCreatePostCreatorFee = 4500;
    uint64 public defaultRemovePostOwnerFee = 0;
    uint64 public defaultRemovePostCreatorFee = 9000;

    uint64 public defaultCreateCommentOwnerFee = 4500;
    uint64 public defaultCreateCommentCreatorFee = 4500;
    uint64 public defaultRemoveCommentOwnerFee = 0;
    uint64 public defaultRemoveCommentCreatorFee = 9000;

    // Storage balance per address
    mapping(address => uint256) private _balances;

    event Withdraw(address indexed user, uint256 amount);
    event TransferFromCommunity(address indexed user, uint256 amount);
    event AddedBalance(address indexed user, uint256 amount);

    event PaidForPrivacyAccess(address indexed user, uint256 indexed communityId, uint256 amount);
    event SetPriceForPrivacyAccess(uint256 oldValue, uint256 newValue);

    event MintForPost(uint256 indexed communityId, address owner, address creator, uint256 amount);
    event MintForComment(uint256 indexed communityId, address owner, address creator, uint256 amount);

    event BurnForPost(uint256 indexed communityId, address owner, address creator, uint256 amount);
    event BurnForComment(uint256 indexed communityId, address owner, address creator, uint256 amount);

    event UpdatePostFee(
        uint256 indexed communityId,
        uint64 newCreatePostOwnerFee,
        uint64 newCreatePostCreatorFee,
        uint64 newRemovePostOwnerFee,
        uint64 newRemovePostCreatorFee
    );
    event UpdateCommentFee(
        uint256 indexed communityId,
        uint64 newCreateCommentOwnerFee,
        uint64 newCreateCommentCreatorFee,
        uint64 newRemoveCommentOwnerFee,
        uint64 newRemoveCommentCreatorFee
    );
    event SetDefaultFee(uint256 index, uint256 oldFee, uint256 newFee);

    event SetOracle(address indexed newOracle);

    event SetForMintGasAmount(uint256 oldValue, uint256 newValue);
    event SetForBurnGasAmount(uint256 oldValue, uint256 newValue);

    event SetToken(address indexed token);
    event SetTreasuryFee(uint256 treasuryFee, uint256 newTreasuryFee);

    /**
     * @dev Makes the initialization of the initial values for the smart contract
     *
     * @param _treasury Address of our treasury
     * @param _admin Address of admin
     * @param _calcUserRate Address of calcUserRate
     */
    function initialize(address _treasury, address _admin, address _calcUserRate)
        public
        initializer
    {
        __Ownable_init();

        require(_treasury != address(0), "PageBank: wrong address");
        require(_admin != address(0), "PageBank: wrong address");
        require(_calcUserRate != address(0), "PageBank: wrong address");

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(UPDATER_FEE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CHANGE_PRICE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(VOTE_FOR_EARN_ROLE, DEFAULT_ADMIN_ROLE);

        treasury = _treasury;
        calcUserRate = IPageCalcUserRate(_calcUserRate);
    }

    /**
     * @dev Returns the smart contract version
     *
     */
    function version() external pure override returns (string memory) {
        return "1";
    }

    /**
     * @dev Accepts ether to the balance of the contract
     * Required for testing
     *
     */
    receive() external payable {
        // React to receiving ether
        // Uncomment for production
        //revert("PageBank: asset transfer prohibited");
    }

    /**
     * @dev Sets the default commission values for creating and removing posts.
     * These values will be automatically assigned when a new community is created.
     *
     * @param communityId An identification number of community
     */
    function definePostFeeForNewCommunity(uint256 communityId) external override onlyRole(MINTER_ROLE) returns(bool) {
        CommunityFee storage fee = communityFee[communityId];

        fee.createPostOwnerFee = defaultCreatePostOwnerFee;
        fee.createPostCreatorFee = defaultCreatePostCreatorFee;
        fee.removePostOwnerFee = defaultRemovePostOwnerFee;
        fee.removePostCreatorFee = defaultRemovePostCreatorFee;
        return true;
    }

    /**
     * @dev Sets the default commission values for creating and removing comments.
     * These values will be automatically assigned when a new community is created.
     *
     * @param communityId An identification number of community
     */
    function defineCommentFeeForNewCommunity(uint256 communityId) external override onlyRole(MINTER_ROLE) returns(bool) {
        CommunityFee storage fee = communityFee[communityId];

        fee.createCommentOwnerFee = defaultCreateCommentOwnerFee;
        fee.createCommentCreatorFee = defaultCreateCommentCreatorFee;
        fee.removeCommentOwnerFee = defaultRemoveCommentOwnerFee;
        fee.removeCommentCreatorFee = defaultRemoveCommentCreatorFee;
        return true;
    }

    /**
     * @dev Reads the values of commissions from the community for creating and removing posts.
     *
     * @param communityId An identification number of community
     */
    function readPostFee(uint256 communityId) external override view returns(
        uint64 createPostOwnerFee,
        uint64 createPostCreatorFee,
        uint64 removePostOwnerFee,
        uint64 removePostCreatorFee
    ) {
        CommunityFee memory fee = communityFee[communityId];

        createPostOwnerFee = fee.createPostOwnerFee;
        createPostCreatorFee = fee.createPostCreatorFee;
        removePostOwnerFee = fee.removePostOwnerFee;
        removePostCreatorFee = fee.removePostCreatorFee;
    }

    /**
     * @dev Reads the values of commissions from the community for creating and removing comments.
     *
     * @param communityId An identification number of community
     */
    function readCommentFee(uint256 communityId) external override view returns(
        uint64 createCommentOwnerFee,
        uint64 createCommentCreatorFee,
        uint64 removeCommentOwnerFee,
        uint64 removeCommentCreatorFee
    ) {
        CommunityFee memory fee = communityFee[communityId];

        createCommentOwnerFee = fee.createCommentOwnerFee;
        createCommentCreatorFee = fee.createCommentCreatorFee;
        removeCommentOwnerFee = fee.removeCommentOwnerFee;
        removeCommentCreatorFee = fee.removeCommentCreatorFee;
    }

    /**
     * @dev Changes the commission values for creating and removing posts.
     *
     * @param communityId An identification number of community
     */
    function updatePostFee(
        uint256 communityId,
        uint64 newCreatePostOwnerFee,
        uint64 newCreatePostCreatorFee,
        uint64 newRemovePostOwnerFee,
        uint64 newRemovePostCreatorFee
    ) external override onlyRole(UPDATER_FEE_ROLE) {
        CommunityFee storage fee = communityFee[communityId];
        fee.createPostOwnerFee = newCreatePostOwnerFee;
        fee.createPostCreatorFee = newCreatePostCreatorFee;
        fee.removePostOwnerFee = newRemovePostOwnerFee;
        fee.removePostCreatorFee = newRemovePostCreatorFee;

        emit UpdatePostFee(communityId,
            newCreatePostOwnerFee,
            newCreatePostCreatorFee,
            newRemovePostOwnerFee,
            newRemovePostCreatorFee
        );
    }

    /**
     * @dev Changes the commission values for creating and removing comments.
     *
     * @param communityId An identification number of community
     */
    function updateCommentFee(
        uint256 communityId,
        uint64 newCreateCommentOwnerFee,
        uint64 newCreateCommentCreatorFee,
        uint64 newRemoveCommentOwnerFee,
        uint64 newRemoveCommentCreatorFee
    ) external override onlyRole(UPDATER_FEE_ROLE) {
        CommunityFee storage fee = communityFee[communityId];
        fee.createCommentOwnerFee = newCreateCommentOwnerFee;
        fee.createCommentCreatorFee = newCreateCommentCreatorFee;
        fee.removeCommentOwnerFee = newRemoveCommentOwnerFee;
        fee.removeCommentCreatorFee = newRemoveCommentCreatorFee;

        emit UpdateCommentFee(communityId,
            newCreateCommentOwnerFee,
            newCreateCommentCreatorFee,
            newRemoveCommentOwnerFee,
            newRemoveCommentCreatorFee
        );
    }

    /**
     * @dev Calculates the equivalent number of tokens for gas consumption. Makes a mint of new tokens.
     *
     * @param communityId An identification number of community
     * @param owner The owner address
     * @param creator The creator address
     * @param gas Gas used
     */
    function mintTokenForNewPost(
        uint256 communityId,
        address owner,
        address creator,
        uint256 gas
    ) external override onlyRole(MINTER_ROLE) returns (uint256 amount) {
        amount = convertGasToTokenAmount(gas + FOR_MINT_GAS_AMOUNT);
        int256 creatorPercent = calcUserRate.checkCommunityActivity(communityId, creator, DataTypes.ActivityType.POST);
        amount = correctAmount(amount, creatorPercent);
        require(amount > 0, "PageBank: wrong amount");

        mintUserPageToken(owner, amount, communityFee[communityId].createPostOwnerFee);
        mintUserPageToken(creator, amount, communityFee[communityId].createPostCreatorFee);
        mintTreasuryPageToken(amount);

        emit MintForPost(communityId, owner, creator, amount);
    }

    /**
     * @dev Calculates the equivalent number of tokens for gas consumption. Makes a mint of new tokens.
     *
     * @param communityId An identification number of community
     * @param owner The owner address
     * @param creator The creator address
     * @param gas Gas used
     */
    function mintTokenForNewComment(
        uint256 communityId,
        address owner,
        address creator,
        uint256 gas
    ) external override onlyRole(MINTER_ROLE) returns (uint256 amount) {
        amount = convertGasToTokenAmount(gas + FOR_MINT_GAS_AMOUNT);
        int256 creatorPercent = calcUserRate.checkCommunityActivity(communityId, creator, DataTypes.ActivityType.MESSAGE);
        amount = correctAmount(amount, creatorPercent);
        require(amount > 0, "PageBank: wrong amount");

        mintUserPageToken(owner, amount, communityFee[communityId].createCommentOwnerFee);
        mintUserPageToken(creator, amount, communityFee[communityId].createCommentCreatorFee);
        mintTreasuryPageToken(amount);

        emit MintForComment(communityId, owner, creator, amount);
    }

    function addUpDownActivity(
        uint256 communityId,
        address postCreator,
        bool isUp
    ) external override onlyRole(MINTER_ROLE) {
        if (isUp) {
            calcUserRate.checkCommunityActivity(communityId, postCreator, DataTypes.ActivityType.UP);
        } else {
            calcUserRate.checkCommunityActivity(communityId, postCreator, DataTypes.ActivityType.DOWN);
        }
    }

    /**
     * @dev Calculates the equivalent number of tokens for gas consumption. Makes a burn of new tokens.
     *
     * @param communityId An identification number of community
     * @param owner The owner address
     * @param creator The creator address
     * @param gas Gas used
     */
    function burnTokenForPost(
        uint256 communityId,
        address owner,
        address creator,
        uint256 gas
    ) external override onlyRole(BURNER_ROLE) returns (uint256 amount) {
        amount = convertGasToTokenAmount(gas + FOR_BURN_GAS_AMOUNT);

        burnUserPageToken(owner, amount, communityFee[communityId].removePostOwnerFee);
        burnUserPageToken(creator, amount, communityFee[communityId].removePostCreatorFee);
        mintTreasuryPageToken(amount);

        emit BurnForPost(communityId, owner, creator, amount);
    }

    /**
     * @dev Calculates the equivalent number of tokens for gas consumption. Makes a burn of new tokens.
     *
     * @param communityId An identification number of community
     * @param owner The owner address
     * @param creator The creator address
     * @param gas Gas used
     */
    function burnTokenForComment(
        uint256 communityId,
        address owner,
        address creator,
        uint256 gas
    ) external override onlyRole(BURNER_ROLE) returns (uint256 amount) {
        amount = convertGasToTokenAmount(gas + FOR_BURN_GAS_AMOUNT);

        burnUserPageToken(owner, amount, communityFee[communityId].removeCommentOwnerFee);
        burnUserPageToken(creator, amount, communityFee[communityId].removeCommentCreatorFee);
        mintTreasuryPageToken(amount);

        emit BurnForComment(communityId, owner, creator, amount);
    }

    /**
     * @dev Withdraw amount from the bank.
     *
     * @param amount An amount of tokens
     */
    function withdraw(uint256 amount) external override {
        require(_balances[_msgSender()] >= amount, "PageBank: not enough balance of tokens");
        _balances[_msgSender()] -= amount;
        require(token.transfer(_msgSender(),  amount), "PageBank: wrong transfer of tokens");
        emit Withdraw(_msgSender(), amount);
    }

    /**
     * @dev Adds tokens to the user's balance in the contract.
     *
     * @param amount An amount of tokens
     */
    function addBalance(uint256 amount) external override {
        require(amount > 0, "PageBank: wrong amount");
        require(token.transferFrom(_msgSender(), address(this), amount), "PageBank: wrong transfer of tokens");
        _balances[_msgSender()] += amount;
        emit AddedBalance(_msgSender(), amount);
    }

    /**
     * @dev Set the new value of price for privacy access.
     *
     * @param communityId ID of community
     * @param newValue New value for price
     */
    function setPriceForPrivacyAccess(uint256 communityId, uint256 newValue) external override
        onlyRole(VOTE_FOR_EARN_ROLE)
    {
        uint256 oldValue = privacyPrice[communityId];
        require(oldValue != newValue, "PageBank: wrong value for price");
        emit SetPriceForPrivacyAccess(oldValue, newValue);
        privacyPrice[communityId] = newValue;
    }

    /**
     * @dev Transfer of earned tokens.
     *
     * @param communityId ID of community
     * @param amount Value for amount of tokens
     * @param wallet Address for transferring tokens
     */
    function transferFromCommunity(uint256 communityId, uint256 amount, address wallet) external override
        onlyRole(VOTE_FOR_EARN_ROLE) returns(bool)
    {
        require(communityBalance[communityId] >= amount, "PageBank: not enough balance of tokens");
        communityBalance[communityId] -= amount;
        require(token.transfer(wallet,  amount), "PageBank: wrong transfer of tokens");
        emit TransferFromCommunity(wallet, amount);
        return true;
    }

    /**
     * @dev Pay tokens for privacy access.
     *
     * @param amount An amount of tokens
     * @param communityId ID of community
     */
    function payForPrivacyAccess(uint256 amount, uint256 communityId) external override {
        address sender = _msgSender();
        uint256 price = privacyPrice[communityId];
        require(amount > 0, "PageBank: wrong amount");
        require(price > 0, "PageBank: wrong price");

        uint256 daysCount = amount / price;
        uint256 payAmount = daysCount * price;
        require(_balances[sender] >= payAmount, "PageBank: incorrect amount on the user's balance");

        _balances[sender] -= payAmount;
        communityBalance[communityId] += payAmount;
        endPrivacyTime[sender][communityId] += block.timestamp + (daysCount * 1 days);

        emit PaidForPrivacyAccess(_msgSender(), communityId, amount);
    }

    /**
     * @dev Bank balance of community.
     *
     * @param communityId ID of community
     */
    function balanceOfCommunity(uint256 communityId) external view override returns (uint256) {
        return communityBalance[communityId];
    }

    /**
     * @dev Bank balance of the user's address.
     *
     * @param user An address of user
     */
    function balanceOf(address user) external view override returns (uint256) {
        return _balances[user];
    }

    /**
     * @dev Changes default commission values for all new communities.
     *
     * @param index Order number of the commission
     * @param newValue New commission value
     */
    function setDefaultFee(uint256 index, uint64 newValue) external override onlyOwner {
        if (index == 0) {
            emit SetDefaultFee(index, defaultCreatePostOwnerFee, newValue);
            defaultCreatePostOwnerFee = newValue;
        }
        if (index == 1) {
            emit SetDefaultFee(index, defaultCreatePostCreatorFee, newValue);
            defaultCreatePostCreatorFee = newValue;
        }
        if (index == 2) {
            emit SetDefaultFee(index, defaultRemovePostOwnerFee, newValue);
            defaultRemovePostOwnerFee = newValue;
        }
        if (index == 3) {
            emit SetDefaultFee(index, defaultRemovePostCreatorFee, newValue);
            defaultRemovePostCreatorFee = newValue;
        }
        if (index == 4) {
            emit SetDefaultFee(index, defaultCreateCommentOwnerFee, newValue);
            defaultCreateCommentOwnerFee = newValue;
        }
        if (index == 5) {
            emit SetDefaultFee(index, defaultCreateCommentCreatorFee, newValue);
            defaultCreateCommentCreatorFee = newValue;
        }
        if (index == 6) {
            emit SetDefaultFee(index, defaultRemoveCommentOwnerFee, newValue);
            defaultRemoveCommentOwnerFee = newValue;
        }
        if (index == 7) {
            emit SetDefaultFee(index, defaultRemoveCommentCreatorFee, newValue);
            defaultRemoveCommentCreatorFee = newValue;
        }
    }

    /**
     * @dev Changes the value of the FOR_MINT_GAS_AMOUNT.
     *
     * @param newValue New value for FOR_MINT_GAS_AMOUNT
     */
    function setMintGasAmount(uint256 newValue) external override onlyOwner {
        require(FOR_MINT_GAS_AMOUNT != newValue, "PageBank: wrong value for FOR_MINT_GAS_AMOUNT");
        emit SetForMintGasAmount(FOR_MINT_GAS_AMOUNT, newValue);
        FOR_MINT_GAS_AMOUNT = newValue;
    }

    /**
     * @dev Changes the value of the FOR_MINT_GAS_AMOUNT.
     *
     * @param newValue New value for FOR_MINT_GAS_AMOUNT
     */
    function setBurnGasAmount(uint256 newValue) external override onlyOwner {
        require(FOR_BURN_GAS_AMOUNT != newValue, "PageBank: wrong value for FOR_BURN_GAS_AMOUNT");
        emit SetForBurnGasAmount(FOR_BURN_GAS_AMOUNT, newValue);
        FOR_BURN_GAS_AMOUNT = newValue;
    }

    /**
     * @dev Changes the address of the oracle.
     *
     * @param newOracle New oracle address value
     */
    function setOracle(address newOracle) external override onlyOwner {
        require(newOracle != address(0), "PageBank: wrong address");

        oracle = IPageOracle(newOracle);
        emit SetOracle(newOracle);
    }

    /**
     * @dev Changes the address of the token.
     *
     * @param newToken New address value
     */
    function setToken(address newToken) external override onlyOwner {
        token = IPageToken(newToken);
        emit SetToken(newToken);
    }

    /**
     * @dev Changes the value of the fee for the Treasury.
     *
     * @param newTreasuryFee New fee value for the Treasury
     */
    function setTreasuryFee(uint256 newTreasuryFee) external override onlyOwner {
        require(newTreasuryFee != treasuryFee, "PageBank: wrong treasury value");
        emit SetTreasuryFee(treasuryFee, newTreasuryFee);
        treasuryFee = newTreasuryFee;
    }

    /**
     * @dev Checks for privacy access.
     *
     * @param user Address of user
     * @param communityId ID of community
     */
    function isPrivacyAvailable(address user, uint256 communityId) external view override returns(bool) {
        return endPrivacyTime[user][communityId] > block.timestamp;
    }

    // *** --- Private area --- ***

    /**
     * @dev Returns gas multiplied by token's prices and gas price.
     *
     * @param gas Gas used
     * @return PAGE token's count
     */
    function convertGasToTokenAmount(uint256 gas) private view returns (uint256) {
        return oracle.getFromWethToPageAmount(gas * tx.gasprice);
    }

    /**
     * @dev Mints PAGE tokens for Treasury.
     *
     * @param amount Amount of tokens
     */
    function mintTreasuryPageToken(uint256 amount) private {
        require(treasury != address(0), "PageBank: wrong treasury address");
        token.mint(treasury, amount * treasuryFee / ALL_PERCENT);
    }

    /**
     * @dev Mints PAGE tokens for user.
     *
     * @param user Address of user
     * @param amount Amount of tokens
     * @param userFee Fee for operation
     */
    function mintUserPageToken(address user, uint256 amount, uint256 userFee) private {
        require(user != address(0), "PageBank: wrong user address");

        uint256 userAmount = amount * userFee / ALL_PERCENT;
        token.mint(address(this), userAmount);
        _balances[user] += userAmount;
    }

    /**
     * @dev Burns PAGE tokens for user.
     *
     * @param user Address of user
     * @param amount Amount of tokens
     * @param userFee Fee for operation
     */
    function burnUserPageToken(address user, uint256 amount, uint256 userFee) private {
        require(user != address(0), "PageBank: wrong user address");

        uint256 userAmount = amount * userFee / ALL_PERCENT;
        token.burn(address(this), userAmount);
        _balances[user] -= userAmount;
    }

    function correctAmount(uint256 currentAmount, int256 percent) private view returns(uint256 newAmount) {
        int256 creatorAmount = int256(currentAmount) * percent / int256(ALL_PERCENT);
        if (creatorAmount > 0) {
            newAmount = currentAmount + uint256(creatorAmount);
        } else {
            uint256 positiveCreatorAmount = uint256(-creatorAmount);
            if (currentAmount >= positiveCreatorAmount) {
                newAmount = currentAmount - positiveCreatorAmount;
            } else {
                newAmount = 0;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "IUniswapV3PoolImmutables.sol";
import "IUniswapV3PoolState.sol";
import "IUniswapV3PoolDerivedState.sol";
import "IUniswapV3PoolActions.sol";
import "IUniswapV3PoolOwnerActions.sol";
import "IUniswapV3PoolEvents.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControlUpgradeable.sol";
import "ContextUpgradeable.sol";
import "StringsUpgradeable.sol";
import "ERC165Upgradeable.sol";
import "Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "IERC165Upgradeable.sol";
import "Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

pragma solidity 0.8.12;

interface IPageBank {

    function version() external pure returns (string memory);

    function initialize(address _treasury, address _admin, address _calcUserRate) external;

    function definePostFeeForNewCommunity(uint256 communityId) external returns(bool);

    function readPostFee(uint256 communityId) external view returns(
        uint64 createPostOwnerFee,
        uint64 createPostCreatorFee,
        uint64 removePostOwnerFee,
        uint64 removePostCreatorFee
    );

    function defineCommentFeeForNewCommunity(uint256 communityId) external returns(bool);

    function readCommentFee(uint256 communityId) external view returns(
        uint64 createCommentOwnerFee,
        uint64 createCommentCreatorFee,
        uint64 removeCommentOwnerFee,
        uint64 removeCommentCreatorFee
    );

    function updatePostFee(
        uint256 communityId,
        uint64 newCreatePostOwnerFee,
        uint64 newCreatePostCreatorFee,
        uint64 newRemovePostOwnerFee,
        uint64 newRemovePostCreatorFee
    ) external;

    function updateCommentFee(
        uint256 communityId,
        uint64 newCreateCommentOwnerFee,
        uint64 newCreateCommentCreatorFee,
        uint64 newRemoveCommentOwnerFee,
        uint64 newRemoveCommentCreatorFee
    ) external;


    function mintTokenForNewPost(
        uint256 communityId,
        address owner,
        address creator,
        uint256 gas
    ) external returns (uint256 amount);

    function mintTokenForNewComment(
        uint256 communityId,
        address owner,
        address creator,
        uint256 gas
    ) external returns (uint256 amount);

    function addUpDownActivity(
        uint256 communityId,
        address postCreator,
        bool isUp
    ) external;

    function burnTokenForPost(
        uint256 communityId,
        address owner,
        address creator,
        uint256 gas
    ) external returns (uint256 amount);

    function burnTokenForComment(
        uint256 communityId,
        address owner,
        address creator,
        uint256 gas
    ) external returns (uint256 amount);

    function withdraw(uint256 amount) external;

    function addBalance(uint256 amount) external;

    function setPriceForPrivacyAccess(uint256 communityId, uint256 newValue) external;

    function transferFromCommunity(uint256 communityId, uint256 amount, address wallet) external returns(bool);

    function payForPrivacyAccess(uint256 amount, uint256 communityId) external;

    function balanceOf(address user) external view returns (uint256);

    function balanceOfCommunity(uint256 communityId) external view returns (uint256);

    function setDefaultFee(uint256 index, uint64 newValue) external;

    function setMintGasAmount(uint256 newValue) external;

    function setBurnGasAmount(uint256 newValue) external;

    function setOracle(address newOracle) external;

    function setToken(address newToken) external;

    function setTreasuryFee(uint256 newTreasuryFee ) external;

    function isPrivacyAvailable(address user, uint256 communityId) external view returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "IERC20Upgradeable.sol";

interface IPageToken is IERC20Upgradeable {

    function version() external pure returns (string memory);

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import {DataTypes} from "DataTypes.sol";

interface IPageCalcUserRate {

    function version() external pure returns (string memory);

    function checkCommunityActivity(
        uint256 communityId,
        address user,
        DataTypes.ActivityType activityType
    ) external returns(int256 resultPercent);

    function addDealActivity(address user, DataTypes.ActivityType activityType) external;

    function calcPercent(address user, uint256 baseTokenId) external view returns(int256 resultPercent);

    function getUserActivity(uint256 communityId, address user) external view returns(
        uint64 messageCount,
        uint64 postCount,
        uint64 upCount,
        uint64 downCount
    );

    function getUserRedeemed(uint256 communityId, address user) external view returns(
        uint64[3] memory messageCount,
        uint64[3] memory postCount,
        uint64[2] memory upCount,
        uint64[2] memory downCount
    );

    function setInterestAdjustment(uint256[10] calldata values) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

library DataTypes {

    enum ActivityType { POST, MESSAGE, UP, DOWN, DEAL_GUARANTOR, DEAL_SELLER, DEAL_BUYER }

    struct DealMessage {
        string message;
        address sender;
        uint256 writeTime;
    }

    struct SafeDeal {
        string description;
        address seller;
        address buyer;
        address guarantor;
        uint256 amount;
        uint128 startTime;
        uint128 endTime;
        bool startSellerApprove;
        bool startBuyerApprove;
        bool endSellerApprove;
        bool endBuyerApprove;
        bool isIssue;
        bool isEth;
        bool isFinished;
        DealMessage[] messages;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IPageOracle {

    function version() external pure returns (string memory);

    function setTwapIntervals(uint32 newTwapInterval) external;

    function changeStablePriceStatus() external;

    function setStablePrice(uint256 newPrice) external;

    function getFromPageToWethPrice() external view returns (uint256 price);

    function getFromWethToPageAmount(uint256 wethAmountIn) external view returns (uint256 pageAmountOut);

}