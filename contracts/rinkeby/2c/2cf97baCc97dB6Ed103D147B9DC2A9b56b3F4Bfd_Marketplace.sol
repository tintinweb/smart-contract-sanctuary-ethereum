// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "./oracleClient/IOracleClient.sol";
import "./interfaces/IProviders.sol";
import "./interfaces/IAssets.sol";
import "./interfaces/INFTdClim.sol";

/// @title Decentralized Marketplace with Commissions v0.2
/// @author Faolain
/// @notice Allows data publishers to monetize IPFS hashes
/// @dev providers must be setup via public/private key generation via chainlink nodes and external adapters for assets w/ price > 0
contract Marketplace is Ownable, Pausable {
    enum OrderStatus {
        PURCHASED,
        COMPLETED,
        CANCELLED
    }

    struct Order {
        uint256 orderId;
        uint256 timestamp;
        uint256 creationId;
        uint256 price;
        address buyer;
        OrderStatus orderstatus;
    }

    /// @dev Chainlink oracle contract which handles calls to external adapter
    IOracleClient public oracleclient;

    /// @dev NFT Contract
    INFTdClim public nftdclim;

    /// @dev LINK Token
    LinkTokenInterface public link;

    /// @dev Token used to purchase Assets
    address public paymentToken;

    /// @dev Treasury address
    address public treasuryAddress;

    /// @dev Providers Address
    IProviders public providers;

    /// @dev Assets Address
    IAssets public assets;

    /// @dev Treasury Commission Balance
    uint256 public treasuryBalance;

    /// @dev Commission disbursed to Treasury from purchases denominated in percent
    uint256 public commission = 1;

    /// @dev number of orders - consuming either free or paid assets
    uint256 public numOrders;

    /// @notice numOrder mapped to Order
    mapping(uint256 => Order) public orders;

    /// @notice Order History Tracking
    mapping(address => Order[]) public buyerSales;
    mapping(address => Order[]) public creatorSales;

    /// @notice Balances
    mapping(uint256 => uint256) public balances;

    /// @notice Constructor for initializing the Smart Contract variables
    constructor(
        address _paymentTokenAddress,
        address _treasuryAddress,
        address NFTdClimAddress,
        address _providers,
        address _assets
    ) {
        paymentToken = _paymentTokenAddress;
        treasuryAddress = _treasuryAddress;
        nftdclim = INFTdClim(NFTdClimAddress);
        providers = IProviders(_providers);
        assets = IAssets(_assets);
    }

    /// @notice Function for initializing treasury address
    /// @dev Treasury address gets comissions from purchases
    function setTreasury(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0), "Error");
        treasuryAddress = _treasuryAddress;
    }

    function setCommission(uint256 _commission) external onlyOwner {
        require(_commission < 100);
        commission = _commission;
    }

    /// @notice Function for initializing Oracle parameters
    function setOracleClient(address _oracleClientAddress) external onlyOwner {
        oracleclient = IOracleClient(_oracleClientAddress);
        link = LinkTokenInterface(oracleclient.paymentTokenAddress());
    }

    /// @notice creation of new order
    /// @dev asset Id must be equal to or less than the number of assets. If asset is not free, provider must have enough link balance for paying fee,
    /// consumer must have enough tokens for paying the asset price, and tokens sent to the marketplace smart contract must be greater or equals than asset price
    /// @param _assetId id for the asset to be ordered
    /// @param _publicKey First half of consumer public key
    function createOrder(
        uint256 _assetId,
        bytes memory _publicKey,
        string memory _cipher
    ) external whenNotPaused {
        (
            uint256 assetId,
            ,
            uint256 assetPrice,
            uint256 assetProviderId,
            string memory assetMetadataCID,
            address assetCreator,

        ) = assets.assets(_assetId);
        require(assetId != 0, "404");
        numOrders++;
        orders[numOrders] = Order(
            numOrders,
            block.timestamp,
            _assetId,
            assetPrice,
            msg.sender,
            OrderStatus.PURCHASED
        );
        if (assetPrice == 0) {
            orders[numOrders].orderstatus = OrderStatus.COMPLETED;
            emit Purchased(
                msg.sender,
                assetCreator,
                _cipher,
                assetMetadataCID,
                _assetId,
                numOrders,
                assetPrice
            );
        } else {
            _createPaidOrder(
                _assetId,
                assetMetadataCID,
                assetPrice,
                assetCreator,
                assetProviderId,
                numOrders,
                _publicKey,
                _cipher
            );
        }
    }

    function _createPaidOrder(
        uint256 assetId,
        string memory assetMetadataCID,
        uint256 assetPrice,
        address assetCreator,
        uint256 assetProviderId,
        uint256 orderId,
        bytes memory publicKey,
        string memory _cipher
    ) internal {
        (
            ,
            bytes32 jobId,
            uint256 oracleOperatorFee,
            uint256 linkBalance,
            ,
            ,
            ,
            ,
            ,
            address oracleAddress,

        ) = providers.providers(assetProviderId);
        if (assetPrice > 0) {
            require(
                linkBalance >= oracleOperatorFee,
                "Insufficient Link in Provider"
            );
            require(
                IERC20(paymentToken).transferFrom(
                    msg.sender,
                    address(this),
                    assetPrice
                ),
                "Failed to deposit"
            );

            providers.subtractLink(assetProviderId);
            link.transfer(address(oracleclient), oracleOperatorFee);
            oracleclient.createOrder(
                jobId,
                oracleAddress,
                orderId,
                oracleOperatorFee,
                publicKey,
                _cipher
            );
            emit NewOrder(
                msg.sender,
                assetCreator,
                _cipher,
                assetMetadataCID,
                assetId,
                assetPrice,
                orderId
            );
        }
    }

    /// @notice function for completing the purchase called by oracle
    /// @dev this function can be only executed by oracle, order id is auto-incremented, and order status cannot be COMPLETED
    /// @param orderId order id to be purchased
    /// @param _cipher encrypted symmetric key with consumer publicKey
    function completeOrder(uint256 orderId, string memory _cipher)
        public
        whenNotPaused
    {
        require(
            msg.sender == address(oracleclient),
            "Only OracleClient can fulfill request"
        );
        require(orderId <= numOrders, "Order doesn't exist");

        Order storage order = orders[orderId];
        require(
            order.orderstatus != OrderStatus.COMPLETED &&
                order.orderstatus != OrderStatus.CANCELLED,
            "Order has already been processed"
        );

        (
            uint256 assetId,
            ,
            ,
            ,
            string memory assetMetadataCID,
            address assetCreator,

        ) = assets.assets(order.creationId);

        order.orderstatus = OrderStatus.COMPLETED;

        uint256 price = order.price;
        uint256 totalCommission = (price * commission) / 100;
        uint256 payment = price - totalCommission;

        buyerSales[order.buyer].push(order);
        creatorSales[assetCreator].push(order);

        balances[assetId] += payment;
        treasuryBalance += totalCommission;

        emit Purchased(
            order.buyer,
            assetCreator,
            _cipher,
            assetMetadataCID,
            assetId,
            order.orderId,
            order.price
        );
    }

    function cancelOrder(uint256 orderId) external whenNotPaused {
        require(orderId <= numOrders, "Order doesn't exist");
        Order storage order = orders[orderId];
        require(order.buyer == msg.sender, "!buyer");
        require(
            order.orderstatus != OrderStatus.COMPLETED &&
                order.orderstatus != OrderStatus.CANCELLED,
            "Order already processed"
        );
        require(block.timestamp >= order.timestamp + 7 days, "!timestamp");

        order.orderstatus = OrderStatus.CANCELLED;
        IERC20(paymentToken).transfer(order.buyer, order.price);
    }

    /// @notice function for claiming fees by data publishers
    /// @dev This function can be called only by asset owner.
    /// Balance of asset must be more or at least same amount as the fee claimed in this function, this amount must be more than 0
    /// and assetId is auto-incremental.
    /// @param assetId asset id from specific publisher
    /// @param _amount amount claimed
    function claimFees(uint256 assetId, uint256 _amount)
        external
        whenNotPaused
    {
        require(
            _amount <= balances[assetId] &&
                _amount > 0 &&
                assetId <= assets.numAssets()
        );
        address assetOwner = nftdclim.ownerOf(assetId);
        require(assetOwner == msg.sender, "Unauthorized");
        balances[assetId] -= _amount;
        IERC20(paymentToken).transfer(assetOwner, _amount);
    }

    /// @notice function to reset treasury balance to 0 and send collected fees to treasury address
    /// @dev this function can be executed only by the owner
    function sweepCommission() external onlyOwner whenNotPaused {
        uint256 oldTreasuryBalance = treasuryBalance;
        treasuryBalance = 0;
        IERC20(paymentToken).transfer(treasuryAddress, oldTreasuryBalance);
    }

    /// @notice event for new orders
    event NewOrder(
        address indexed buyer,
        address indexed creator,
        string cipher,
        string metadataCID,
        uint256 indexed id,
        uint256 price,
        uint256 orderId
    );

    /// @notice event for purchased data
    event Purchased(
        address indexed buyer,
        address indexed creator,
        string cipher,
        string metadataCID,
        uint256 indexed creationId,
        uint256 orderId,
        uint256 price
    );
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// // SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.10;

/// @title OracleClient interface
/// @author Faolain
/// @notice Allow the interaction between marketplace and oracle
interface IOracleClient {
    /// @notice is the erc20 address of the link token
    /// @return erc20 address for link tokens used for paying oracle
    function paymentTokenAddress() external view returns (address);

    /// @notice function for creating an order
    /// @dev this function can be only called by marketplace Smart Contract, in order to
    /// transfer this amount fee to the oracle using sendChainlinkRequestTo function to create order
    /// @param _jobId bytes32 job id requested
    /// @param _oracleAddress address oracle address
    /// @param _orderId uint256 order Id
    /// @param _fee uint256 fee to be paid for creating the order
    /// @param _publicKey First half of consumer public key
    /// @param _cipher encrypted symmetric key used to decrypt data and consumer publicKey
    function createOrder(
        bytes32 _jobId,
        address _oracleAddress,
        uint256 _orderId,
        uint256 _fee,
        bytes memory _publicKey,
        string memory _cipher
    ) external;

    /// @notice completing the purchase
    /// @param _requestId bytes32 request id
    /// @param _orderId uint256 order id
    /// @param _cipher encrypted symmetric key with consumer publicKey
    function completeOrder(
        bytes32 _requestId,
        uint256 _orderId,
        string memory _cipher
    ) external;
}

// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IProviders {
    struct Provider {
        uint256 id;
        bytes32 jobId;
        uint256 oracleOperatorFee;
        uint256 linkBalance;
        uint256 minAssetPrice;
        bytes32 name;
        bytes32 firstHalfProviderPublicKey;
        bytes32 secondHalfProviderPublicKey;
        address owner;
        address oracleAddress;
        bool enabled;
    }

    // Function signature for mapping
    function providers(uint256 _providerId)
        external
        view
        returns (
            uint256 id,
            bytes32 jobId,
            uint256 oracleOperatorFee,
            uint256 linkBalance,
            uint256 minAssetPrice,
            bytes32 name,
            bytes32 firstHalfProviderPublicKey,
            bytes32 secondHalfProviderPublicKey,
            address owner,
            address oracleAddress,
            bool enabled
        );

    function setMarketplace(address _marketplace) external;

    /// @notice function for adding link value to providers for executing operations
    /// @dev function caller must have more or at least the same amount of link tokens as the _amount specified in the parameter, and link amount sent to oracle must be greater
    /// or equals to _amount specified in parameters
    /// @param _providerId provider id to allocate the link tokens
    /// @param _amount amount of link tokens to be sent
    function depositLink(uint256 _providerId, uint256 _amount) external;

    function subtractLink(uint256 _providerId) external;

    /// @notice event for newly create provider
    event NewProvider(uint256 id, bytes32 name);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "./IProviders.sol";
import "./IMarketplace.sol";
import "./INFTdClim.sol";

/// @title Decentralized Marketplace with Commissions v0.2
/// @author Faolain
/// @notice Allows data publishers to monetize IPFS hashes
/// @dev providers must be setup via public/private key generation via chainlink nodes and external adapters for assets w/ price > 0
interface IAssets {
    enum AssetType {
        DATASET,
        MODEL,
        FORECAST
    }

    struct Asset {
        uint256 id;
        uint256 timestamp;
        uint256 price;
        uint256 providerId;
        string metadataCID;
        address creator;
        uint16 skillScore;
    }

    // Function signature for mapping
    function assets(uint256 _assetId)
        external
        view
        returns (
            uint256 id,
            uint256 timestamp,
            uint256 price,
            uint256 providerId,
            string memory metadataCID,
            address creator,
            uint16 skillScore
        );

    // Function signature for mapping
    // function assets(uint256 _assetId) external view returns (Asset memory);

    function numAssets() external returns (uint256);

    function setSkillScoreVerifier(address _skillScoreVerifier) external;

    function setStakeReq(uint256 _stakeReq) external;

    /// @notice Set Grace Period where Governance can slash assets for malicious activity
    /// @dev This should be set(!) if setStakeReq() is set with a particular requirement otherwise
    /// withdrawStake() can be called by a publisher essentially at any point (since default is 0)
    /// @param _stakeGracePeriod uin256 number of days to set as the grace (probationary) period
    function setStakeGracePeriod(uint256 _stakeGracePeriod) external;

    function withdrawStake(uint256 _assetId) external;

    /// @notice function for publishing asset
    /// @dev to call this function it is required that the parameter providerId already exists in the providers state variable.
    /// Price set in parameter must be greater or equals to minimum price related to provider id set in parameters
    /// @param _providerId uint256 provider Id related to provider executing this function
    /// @param price uint256 price to pay for the asset
    /// @param metadataCID string metadataCID of the asset
    /// @param metadata string metadata of the asset which includes cipher ( encrypted symmetric key with provider publicKey)
    function publish(
        uint256 _providerId,
        uint256 price,
        string calldata metadataCID,
        string calldata metadata
    ) external;

    function updatePrice(uint256 _assetId, uint256 _price) external;

    /// @notice updates the "skill score" of a asset using a chainlink external adapter
    /// @dev can only be executed by skillScoreVerifier which is a chainlink operator contract which executes fulfillment
    /// @param  _assetId asset to be verified
    /// @param _skillScore skill score for assets which measures quality 0 <= x <= 5.000
    /// @param _reportCID ipfs CID of report generated after running skillscore validation
    function updateSkillScore(
        uint256 _assetId,
        uint16 _skillScore,
        string memory _reportCID
    ) external;

    function slashPublisher(uint256 _assetId) external;

    event Slashed(uint256 indexed assetId, uint256 amountSlashed);

    /// @notice event for successfully published data
    event Published(
        address indexed creator,
        string metadataCID,
        string metadata,
        uint256 indexed id,
        uint256 price
    );

    /// @notice event emitted after validation script is run to assign skillscore to asset
    event SkillScoreUpdated(
        uint256 indexed assetId,
        uint16 indexed skillScore,
        string indexed reportCID
    );
}

// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.10;
import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface INFTdClim is IERC721 {
    function newAsset(address _creator, uint256 _assetId)
        external
        returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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

import "./IERC165.sol";

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

// // SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.10;

/// @title Marketplace interface
/// @author Faolain
/// @notice Allows data publishers to monetize IPFS hashes
/// @dev providers must be setup via public/private key generation via chainlink nodes and external adapters for assets w/ price > 0
interface IMarketplace {
    /// @notice function that grants provider role to specific address
    /// @dev set the address sent as parameter as provider. This function can be called only by the owner
    /// @param _provider address to be set as provider
    function whitelistProviderCreator(address _provider) external;

    /// @notice function for publishing asset
    /// @dev for running this function it is required that providerId from the parameters was correct and there was one provider in providers state variable associated to
    /// this provider id set in the parameters. Price set in parameter must be greater or equals to minimum price related to provider id set in parameters
    /// @param _providerId uint256 provider Id related to provider executing this function
    /// @param locationHash string location hash with the information related to IPFS address where encrypted information is stored
    /// @param metadata string metadata of the data being published
    /// @param price uint256 price to pay for the metadata
    function publish(
        uint256 _providerId,
        string memory locationHash,
        string memory metadata,
        uint256 price
    ) external returns (bool);

    /// @notice creation of new order
    /// @dev asset Id must be equals or less than the number of assets. If asset is not free, provider must have enough link balance for paying fee,
    /// consumer must have enough tokens for paying the asset price, and tokens sent to the marketplace smart contract must be greater or equals than asset price
    /// @param _assetId id for the asset to be ordered
    /// @param _firstHalfPublicKey First half of consumer public key
    /// @param _secondHalfPublicKey First half of consumer public key
    function createOrder(
        uint256 _assetId,
        bytes32 _firstHalfPublicKey,
        bytes32 _secondHalfPublicKey
    ) external;

    /// @notice function for completing the purchase called by oracle
    /// @dev this function can be only executed by oracle, order id is auto-incremented, and order status cannot be COMPLETED
    /// @param orderId order id to be purchased
    /// @param _cipher encrypted symmetric key with consumer publicKey
    function completeOrder(uint256 orderId, string memory _cipher) external;

    /// @notice updates the "skill score" of a asset using a chainlink external adapter
    /// @dev can only be executed by skillScoreVerifier which is a chainlink operator contract which executes fulfillment
    /// @param  _assetId asset to be verified
    /// @param _skillScore skill score for assets which measures quality 0 <= x <= 5.000
    /// @param _reportCID ipfs CID of report generated after running skillscore
    function updateSkillScore(
        uint256 _assetId,
        uint16 _skillScore,
        string memory _reportCID
    ) external;

    /// @notice function for reset treasury balance to 0 and send treasury balance to dClimate address
    /// @dev this function can be executed only by the owner
    function sweepCommission() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}