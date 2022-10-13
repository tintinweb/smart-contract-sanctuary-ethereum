// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IAggregator.sol";
import "./routes/ValidatorNftRouter.sol";
import "./routes/LidoRouter.sol";
import "./routes/RocketPoolRouter.sol";


/** @title Staking Aggregator for Eth
  * @author ChainUp Dev
  * @dev Accepts incoming data and and route to different startegies. 
 **/
contract Aggregator is IAggregator, ValidatorNftRouter, UUPSUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable, LidoRouter, RocketPoolRouter {
    bytes1 private constant ETH32_STRATEGY = 0x01;  
    bytes1 private constant LIDO_STRATEGY = 0x02; 
    bytes1 private constant SWELL_STRATEGY = 0x03;
    bytes1 private constant ROCKETPOOL_STRATEGY = 0x04; 
    bytes1 private constant STAKEWISE_STRATEGY = 0x05;
    bytes1 private constant NODE_TRADE_STRATEGY = 0x06;
    bytes1 private constant SSV_STRATEGY = 0x07; 
    bytes1 private constant ONEINCH_STRATEGY = 0x08;  

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    /**
    * @notice Initializes the contract by setting the required external
    *  contracts for different strategies (Eth32,Lido,Rocket, Stakewise)
    * ReentrancyGuardUpgradeable, OwnableUpgradeable, UUPSUpgradeable .  
    * @dev initializer- A modifier that defines a protected initializer function that can be invoked at most once. 
    **/
    function initialize(
        address depositContractAddress,
        address vaultAddress,
        address nftContractAddress,
        address lidoContractAddress,
        address lidoControllerContractAddress,
        address rocketStorageAddressContractAddress,
        address rocketPoolControllerContractAddress
    ) 
    external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __ValidatorNftRouter__init(depositContractAddress, vaultAddress, nftContractAddress);
        __LidoRouter__init(lidoContractAddress, lidoControllerContractAddress);
        __RocketPoolRouter__init( rocketStorageAddressContractAddress, rocketPoolControllerContractAddress );

    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
    * @dev See {IAggregator-stake}.
    */
    function stake(bytes[] calldata data) payable external override nonReentrant whenNotPaused returns (bool) {
        uint256 total_ether = 0;

        for (uint256 i = 0; i < data.length; i++) {
            require(data[i].length > 0, "Empty data provided");
            bytes1 prefix = bytes1(data[i][0]);
            if (prefix == ETH32_STRATEGY) {
                require(data[i].length == 320 , "Eth32 Contract: Invalid Data Length");
                super.eth32Route(data[i]);
                total_ether += 32 ether;
            } else if (prefix == LIDO_STRATEGY) {
                require(data[i].length == 64, "LidoContract: invalid data.length");
                total_ether += super.lidoRoute(data[i]);
            } else if (prefix == ROCKETPOOL_STRATEGY) {
                require(data[i].length == 64, "Rocket Pool Contract: invalid data.length");
                total_ether += super.rocketPoolRoute(data[i]);
            }
             else if (prefix == NODE_TRADE_STRATEGY) {
                total_ether += super.tradeRoute(data[i]);
            }
        }
        require(msg.value == total_ether, "Incorrect Ether amount provided");
        return true;
    }

    /**
    * @dev See {IAggregator-unstake}.
    */
    function unstake(bytes[] calldata data) payable external override nonReentrant whenNotPaused returns (bool) {
        return data.length == 0;
    }

    /**
    * @dev See {IAggregator-disperseRewards}.
    */
    function disperseRewards(uint256 tokenId) external override whenNotPaused {
        require(msg.sender == nftAddress, "Message sender is not the Nft contract");
        vault.publicSettle();
        rewardRoute(tokenId);
    }

    function claimRewards(uint256 tokenId) external override nonReentrant whenNotPaused {
        rewardRoute(tokenId);
    }

    function batchClaimRewards(uint256[] calldata tokenIds) external override nonReentrant whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            rewardRoute(tokenIds[i]);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/* @title Interface for Aggregator
    @author ChainUp Dev
    @notice Execute different functions for the user accordingly. 
*/

interface IAggregator {

    /**
    * @notice Route user's investment into different protocols
    * @param data - byte array which has unique prefix for different strategy 
    * @return bool return true if staked amount adds up to initial staked amount.
    **/
    function stake(bytes[] calldata data) payable external returns (bool);

    function unstake(bytes[] calldata data) payable external returns (bool);

    /**
    * @notice Transfer earned rewards to user
    * @param tokenId - representation of user's nft
    **/
    function disperseRewards(uint256 tokenId) external;

    function claimRewards(uint256 tokenId) external;

    function batchClaimRewards(uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
import "../interfaces/ILido.sol";
import "../controller-interface/ILidoController.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../controller-interface/ILidoERC20.sol";

/** @title Router for Lido Strategy
@author ChainUp Dev
@dev Routes incoming data(Lido pre-fix) to outbound contracts 
**/
contract LidoRouter is Initializable {
    ILido public lidoContract;
    ILidoController public lidoController;
    ILidoERC20 public iLidoERC20;
    address public lidoContractControllerAddress;

    event LidoDeposit(address _owner, uint256 _stake_amount);

    /**
     * @notice Initializes the contract by setting the required external contracts ,
     * @param lidoContract_ official Lido Contract for Staking 
     * @param lidoControllerContract_ lidoController Contract 
     * @dev onlyInitializing  .
     **/
    function __LidoRouter__init(address lidoContract_, address lidoControllerContract_) internal onlyInitializing {
        lidoContract = ILido(lidoContract_);
        lidoController = ILidoController(lidoControllerContract_);
        iLidoERC20 = ILidoERC20(lidoContract_);
        lidoContractControllerAddress = lidoControllerContract_;
    }

    function lidoRoute(bytes calldata data) internal returns (uint256) {
        return _lido_stake(uint256(bytes32(data[32:64])));
    }

    /**
     * @notice Routes incoming data (Lido Strategy) to outbound contracts, Lido Staking Contract for the staking function
     * and calls the controller function like adding to stETH shares and also transferring of stETH to the controller address
     * @dev `msg.value` has to be more than `stake_amount` 
     * @param stake_amount must be minumum 1 wei (minimum deposit) 
     */
    function _lido_stake(uint256 stake_amount) internal returns (uint256) {
        require(msg.value >= stake_amount, "Stake amount is not enough!");
        require(stake_amount >= 1 wei, "Deposit must not be zero and must be minumum 1 wei");
       
        uint256 shareAmount = lidoContract.submit{value: stake_amount}(lidoController.getReferral());
        iLidoERC20.transfer(lidoContractControllerAddress, shareAmount);
        lidoController.addStEthShares(msg.sender, shareAmount);
        emit LidoDeposit(msg.sender, stake_amount);

        return stake_amount;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IDepositContract.sol";
import "../interfaces/IValidatorNft.sol";
import "../interfaces/INodeRewardVault.sol";

/** @title Router for RocketPool Strategy
@author ChainUp Dev
@dev Routes incoming data(ValidatorNftRouter strategy) to outbound contracts 
**/
contract ValidatorNftRouter is Initializable {
    event NodeTrade(uint256 _tokenId, address _from, address _to, uint256 _amount);
    event Eth32Deposit(bytes _pubkey, bytes _withdrawal, address _owner);

    IValidatorNft public nftContract;
    INodeRewardVault public vault;
    IDepositContract public depositContract;

    address public nftAddress;
    mapping(uint256 => uint64) public nonces;

    function __ValidatorNftRouter__init(address depositContract_, address vault_, address nftContract_) internal onlyInitializing {
        depositContract = IDepositContract(depositContract_);
        vault = INodeRewardVault(vault_);
        nftContract = IValidatorNft(nftContract_);
        nftAddress = nftContract_;
    }

    //slither-disable-next-line calls-loop

    /**
    * @notice Pre-processing before performing the signer verification.  
    * @return bytes32 hashed value of the pubkey, withdrawalCredentials, signature,
    *  depositDataRoot, bytes32(blockNumber
    **/
    function precheck(bytes calldata data) private view returns (bytes32) {
        bytes calldata pubkey = data[16:64];
        bytes calldata withdrawalCredentials = data[64:96];
        bytes calldata signature = data[96:192];
        bytes32 depositDataRoot = bytes32(data[192:224]);
        uint256 blockNumber = uint256(bytes32(data[224:256]));

        require(!nftContract.validatorExists(pubkey), "Pub key already in used");
        uint256 currentBlock = block.number ;
        require(blockNumber > currentBlock , "Block height too old, please generate a new transaction");

        return keccak256(abi.encodePacked(pubkey, withdrawalCredentials, signature, depositDataRoot, bytes32(blockNumber)));
    }

    /**
    * @notice Performs signer verification, prevents unauthorized usage .  
    * @param v, r, and s parts of a signature
    * @param hash_ - hashed value from precheck
    * @param signer_ - authentic signer to check against
    **/
    function signercheck(bytes32 s, bytes32 r, uint8 v, bytes32 hash_, address signer_) private pure {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash_));
        address signer = ecrecover(prefixedHash, v, r, s);

        require(signer == signer_, "Not authorized");
        require(signer != address(0), "ECDSA: invalid signature");
    }

    //slither-disable-next-line calls-loop
    /**
    * @notice Routes incoming data(Trade Strategy) to outbound contracts, ETH2 Official Deposit Contract 
    * and calls internal functions for pre-processing and signer verfication
    * check for expired transaction through block height
    * @return uint256 sum of the trades
    */
    //slither-disable-next-line calls-loop
    function _tradeRoute(bytes calldata data) private returns (uint256) {
        address tradeReceiver = address(bytes20(data[12:32]));
        require(tradeReceiver == msg.sender, "Not allowed to make this trade");
        require(uint256(bytes32(data[96:128])) > block.number, "Trade has expired");

        // change this in the future
        uint256 sum = 0;
        uint256 i = 0;

        for (i = 0; i < uint256(bytes32(data[128:160])); i++) {
            uint256 price = uint256(bytes32(data[160 + i * 224:192 + i * 224]));
            uint256 tokenId = uint256(bytes32(data[192 + i * 224:224 + i * 224]));
            uint256 rebate = uint256(bytes32(data[224 + i * 224:256 + i * 224]));
            uint256 expiredHeight = uint256(bytes32(data[256 + i * 224:288 + i * 224]));
            address signer = address(bytes20(data[352 + i * 224:372 + i * 224]));
            uint64 nonce = uint64(bytes8(data[376 + i * 224:384 + i * 224]));

            require(expiredHeight > block.number, "Listing has expired");
            require(nftContract.ownerOf(tokenId) == signer, "Not owner");
            require(nonce == nonces[tokenId], "Incorrect nonce");
            
            nonces[tokenId]++;
            sum += price;

            bytes32 hash = keccak256(abi.encodePacked(tokenId, rebate, expiredHeight, nonce));
            signercheck(bytes32(data[320 + i * 224:352 + i * 224]), bytes32(data[288 + i * 224:320 + i * 224]), uint8(bytes1(data[372 + i * 224])), hash, signer);
            
            uint256 nodeCapital = nftContract.nodeCapitalOf(tokenId);
            uint256 userPrice = price;
            if (price > nodeCapital) {
                userPrice = price - (price - nodeCapital) * vault.comission() / 10000;
                payable(vault.dao()).transfer(price - userPrice);
            }
            require(userPrice > 30 ether, "Node too cheap");

            payable(signer).transfer(userPrice);
            nftContract.safeTransferFrom(signer, tradeReceiver, tokenId);
            nftContract.updateNodeCapital(tokenId, price);
            
            emit NodeTrade(tokenId, signer, tradeReceiver, price);
        }

        bytes32 authHash = keccak256(abi.encodePacked(data[160:], uint256(bytes32(data[96:128])), tradeReceiver));
        signercheck(bytes32(data[64:96]), bytes32(data[32:64]), uint8(bytes1(data[1])), authHash, vault.authority());

        return sum;
    }

    /**
    * @notice Allows transfer funds of 32 ETH to the Official Ethereum 2.0 deposit contract
    */
    //slither-disable-next-line reentrancy-events
    function deposit(bytes calldata data) private {
        bytes calldata pubkey = data[16:64];
        bytes calldata withdrawalCredentials = data[64:96];
        bytes calldata signature = data[96:192];
        bytes32 depositDataRoot = bytes32(data[192:224]);

        depositContract.deposit{value: 32 ether}(pubkey, withdrawalCredentials, signature, depositDataRoot);
        
        emit Eth32Deposit(pubkey, withdrawalCredentials, msg.sender);
    }

    /**
    * @notice Routes incoming data(ETH32 Strategy) to outbound contracts, ETH2 Official Deposit Contract 
    * and calls internal functions for pre-processing and signer verfication, minting of nft to user.
    */
    //slither-disable-next-line calls-loop
    function eth32Route(bytes calldata data) internal returns (bool) {
        bytes32 hash = precheck(data);
        signercheck(bytes32(data[256:288]), bytes32(data[288:320]), uint8(bytes1(data[1])), hash, vault.authority());
        deposit(data);

        vault.settle();
        nftContract.whiteListMint(data[16:64], msg.sender);

        return true;
    }

    /**
    * @notice Routes incoming data(Trade Strategy) to outbound contracts, ETH2 Official Deposit Contract 
    * and calls internal functions for pre-processing and signer verfication
    * check for expired transaction through block height
    * @return uint256 sum of the trades
    */
    function tradeRoute(bytes calldata data) internal returns (uint256) {
        return _tradeRoute(data);
    }

    /**
    * @dev See {IAggregator-disperseRewards}.
    */
    //slither-disable-next-line reentrancy-events
    function rewardRoute(uint256 tokenId) internal {
        vault.claimRewards(tokenId);
        nftContract.setGasHeight(tokenId, vault.rewardsHeight());
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../controller-interface/IRocketController.sol";
import "../interfaces/RocketDepositPoolInterface.sol";
import "../controller-interface/RocketTokenRETHInterface.sol";
import "../controller-interface/RocketStorageInterface.sol";

/** @title Router for RocketPool Strategy
  * @author ChainUp Dev
  * @dev Routes incoming data(RocketPool strategy) to outbound contracts 
**/
contract RocketPoolRouter is Initializable {
    IRocketController public rocketController;
    RocketDepositPoolInterface public rocketDepositPool;
    RocketTokenRETHInterface public rocketTokenRETH;
    RocketStorageInterface public rocketStorage;

    address public rocketPoolContractControllerAddress;

    event RocketPoolDeposit(address _owner, uint256 rEthMinted);

    /**
     * @notice Initializes the contract by setting the required external contracts
     * @param  rocketStorageAddress_ - deployed rocket storage contract address
     * @param  rocketPoolControllerContract_ - deployed rocketpool controller address
     * @dev The RocketStorage contract also stores the addresses of all other network contracts,
     * therefore the rocketpool-related contracts are queried before use to prevent outdated addresses.
     **/
    function __RocketPoolRouter__init(address rocketStorageAddress_, address rocketPoolControllerContract_)
        internal
        onlyInitializing
    {
        rocketPoolContractControllerAddress = rocketPoolControllerContract_;
        rocketController = IRocketController(rocketPoolControllerContract_);
        rocketStorage = RocketStorageInterface(rocketStorageAddress_);

        address rocketDepositPoolAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketDepositPool"))
        );
        address rocketTokenRETHAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))
        );

        rocketTokenRETH = RocketTokenRETHInterface(rocketTokenRETHAddress);
        rocketDepositPool = RocketDepositPoolInterface(rocketDepositPoolAddress);
    }

    function rocketPoolRoute(bytes calldata data) internal returns (uint256) {
        return _rocket_deposit(uint256(bytes32(data[32:64])));
    }

    /**
     * @notice Routes incoming data(Rocket Strategy) to outbound contracts, RocketPool Deposit Contract
     * and calls internal controller functions and also transferring of stETH to the RocketPoolController Contract
     * @dev `stake_amount` must be minumum 0.01 ether (minimum deposit)
     * if the deposit to RocketPool is successful, `afterREthBalance` must be more than `beforeREthBalance`
     * @return stake_amount - successfully staked ether to rocketpool deposit contract
     */
    function _rocket_deposit(uint256 stake_amount) internal returns (uint256) {
        require(stake_amount >= 0.01 ether, "The deposited amount is less than the minimum deposit size");
        require(msg.value >= stake_amount, "Stake amount is not enough!");

        uint256 beforeREthBalance = rocketTokenRETH.balanceOf(address(this));
        rocketDepositPool.deposit{value: stake_amount}();
        uint256 afterREthBalance = rocketTokenRETH.balanceOf(address(this));
        require(afterREthBalance > beforeREthBalance, "No rETH was minted");
        uint256 actualRethMinted = afterREthBalance - beforeREthBalance;
        rocketTokenRETH.transfer(rocketPoolContractControllerAddress, actualRethMinted);
        rocketController.addREthBalance(msg.sender, actualRethMinted);
        emit RocketPoolDeposit(msg.sender, actualRethMinted);

        return stake_amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Interface for Lido liquid staking pool
 * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
 * and stakes it via the deposit_contract.sol contract. It doesn't hold ether on it's balance,
 * only a small portion (buffer) of it.
 */
interface ILido {
    /** Records a deposit made by a user  */
    event Submitted(address indexed sender, uint256 amount, address referral);

    /**
     * @notice Adds eth to the pool
     * @param _referral referral address
     * @return StETH Amount of StETH generated
     */
    function submit(address _referral) external payable returns (uint256 StETH);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface ILidoController   {
    /**
     * @dev Returns a string, `referral`.
     * Requirements:
     * - `referral` must exist.
     */
    function getReferral() external view returns (address) ;

    /**
     * @dev Adds `stEthShares` shares to `stEthSharesMap` that keep tracks of stETH shares owned by each address `.
     * Requirements:
     * - `userAddress` must exist.
     * - `msg.sender` must be under list of allowed addresses, `allowList`. 
     */
    function addStEthShares(address userAddress, uint256 stEthShares) external  ;

    /**
     * @dev Returns the number of stETH shares, `stEthBalance` owned by the address `userAddress`.
     * @param userAddress : the user's unique address
     * Requirements:
     * - `userAddress` must exist 
    * @return uint256 : the number of stETH shares owned by `userAddress`.
     */
    function getStEthShares(address userAddress ) external view  returns (uint256) ;

    /**
    * @dev Adds `userAddress` to a list of allowed address, `allowList`
    * will only allow call of function by the address registered as the owner
    * @param userAddress : the user's unique address
    */
    function addAllowList(address userAddress) external;

    /**
    * @dev Remove `userAddress` from a list of allowed address, `allowList`.
    * will only allow call of function by the address registered as the owner
    * @param userAddress : the user's unique address
    */
    function removeAllowList(address userAddress) external;

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ILidoERC20 {

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
import './IERC721AQueryable.sol';

interface IValidatorNft is IERC721AQueryable {
    function activeValidators() external view returns (bytes[] memory);

    function validatorExists(bytes calldata pubkey) external view returns (bool);

    function validatorOf(uint256 tokenId) external view returns (bytes memory);

    function validatorsOfOwner(address owner) external view returns (bytes[] memory);

    function tokenOfValidator(bytes calldata pubkey) external view returns (uint256);

    function setGasHeight(uint256 tokenId, uint256 value) external;

    function gasHeightOf(uint256 tokenId) external view returns (uint256);

    function lastOwnerOf(uint256 tokenId) external view returns (address);

    function whiteListMint(bytes calldata data, address _to) external payable;

    function whiteListBurn(uint256 tokenId) external;

    function updateNodeCapital(uint256 tokenId, uint256 value) external;

    function nodeCapitalOf(uint256 tokenId)  external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

  /**
  * @title Interface for NodeRewardVault
  * Vault will manage methods for rewards, commissions, tax
  */
interface INodeRewardVault {
    struct RewardMetadata {
        uint256 value;
        uint256 height;
    }

    function nftContract() external view returns (address);

    function rewards(uint256 tokenId) external view returns (uint256);

    function rewardsHeight() external view returns (uint256);

    function rewardsAndHeights(uint256 amt) external view returns (RewardMetadata[] memory);

    function comission() external view returns (uint256);

    function tax() external view returns (uint256);

    function dao() external view returns (address);
    
    function authority() external view returns (address);

    function aggregator() external view returns (address);

    function settle() external;

    function publicSettle() external;

    function claimRewards(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IRocketController {
    /**
     * @notice Adds `rEthBalance` shares to `rEthBalanceMap` that keep tracks of RETH Tokens owned by each address.
     * @param userAddress : the user's unique address.
     * @param rEthBalance : rETH Tokens owned.
     * @dev `userAddress` cannot be the zero address, `msg.sender` must be inside list of allowed addresses.
     */
    function addREthBalance(address userAddress, uint256 rEthBalance) external;

    /**
     * @notice Returns the balance of RETH Tokens owned by the address `userAddress`.
     * @param userAddress : the user's unique address
     * @return uint256 : REth Balance owned by `userAddress`.
     */
    function getREthBalance(address userAddress) external view returns (uint256);

    /**
     * @notice Adds `userAddress` to a list of allowed address, `allowList`.
     * @param userAddress : the user's unique address
     * @dev will only allow call of function by the address registered as the owner
     */
    function addAllowList(address userAddress) external;

    /**
     * @notice Remove `userAddress` from a list of allowed address, `allowList`.
     * @param userAddress : the user's unique address
     * @dev will only allow call of function by the address registered as the owner
     */
    function removeAllowList(address userAddress) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.7;

  /**
  * @title Interface for RocketPool Liquid staking pool
  * Accepts user-deposited ETH and handles assignment to minipools
  * Implement custom deposit logic which funnels user deposits into the deposit poo
  */

interface RocketDepositPoolInterface {
    /**
    * @notice Deposits ETH into Rocket Pool and minted rETH back to the caller
    */    
    function deposit() external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.7;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface RocketTokenRETHInterface is IERC20 {
    /**
    * @dev Interface of the ERC20 standard as defined in the EIP.
    */

    function getEthValue(uint256 _rethAmount) external view returns (uint256);
    function getRethValue(uint256 _ethAmount) external view returns (uint256);
    function getExchangeRate() external view returns (uint256);
    function getTotalCollateral() external view returns (uint256);
    function getCollateralRate() external view returns (uint256);
    function depositExcess() external payable;
    function depositExcessCollateral() external;
    function mint(uint256 _ethAmount, address _to) external;
    function burn(uint256 _rethAmount) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.7;

interface RocketStorageInterface {
    /**
    * @notice Rocket Storage Methods
    * @dev method interfaces for deployed, getter, setter, arithmetic, guardian, delete, protected storage 
    */

    /* Deployment */
    function getDeployedStatus() external view returns (bool);

    /* Guardian */
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

     /* Getters */
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

     /* Setters */
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

     /* Deleters */
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

     /* Arithmetic */
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;

     /* Protected storage */
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
  
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}