// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

///@title Frens Staking Pool Factory
///@author 0xWildhare and Frens team
///@dev allows user to create a new staking pool

//import "hardhat/console.sol";
import "./StakingPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./interfaces/IFrensArt.sol";
import "./interfaces/IFrensStorage.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

contract StakingPoolFactory is IStakingPoolFactory{
    event Create(
        address indexed contractAddress,
        address creator,
        address owner
    );

    IFrensPoolShare frensPoolShare;
    IFrensStorage frensStorage;

    constructor(IFrensStorage frensStorage_) {
       frensStorage = frensStorage_;
       frensPoolShare = IFrensPoolShare(frensStorage.getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare"))));
    }

    ///@dev creates a new pool
    ///@return address of new pool
    function create(
        address _owner,
        bool _validatorLocked
    )
        public
        returns (
            address
        )
    {
        StakingPool stakingPool = new StakingPool(
            _owner,
            _validatorLocked,
            frensStorage
        );
        // allow this stakingpool to mint shares in our NFT contract
        IAccessControl(address(frensPoolShare)).grantRole(keccak256("MINTER_ROLE"),address(stakingPool));
        emit Create(address(stakingPool), msg.sender, address(this));
        return (address(stakingPool));
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

///@title Frens Staking Pool Contract
///@author 0xWildhare and the FRENS team
///@dev A new instance of this contract is created everytime a user makes a new pool

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IFrensArt.sol";
import "./interfaces/IFrensOracle.sol";
import "./interfaces/IFrensStorage.sol";

contract StakingPool is IStakingPool, Ownable{
    event Stake(address depositContractAddress, address caller);
    event DepositToPool(uint amount, address depositer, uint id);

    modifier noZeroValueTxn() {
        require(msg.value > 0, "must deposit ether");
        _;
    }

    modifier maxTotDep() {
        require(
            msg.value + totalDeposits <= 32 ether,
            "total deposits cannot be more than 32 Eth"
        );
        _;
    }

    modifier mustBeAccepting() {
        require(
            currentState == PoolState.acceptingDeposits,
            "not accepting deposits"
        );
        _;
    }

    modifier correctPoolOnly(uint _id) {
        require(
            frensPoolShare.poolByIds(_id) == address(this),
            "wrong staking pool for id"
        );
        _;
    }

    enum PoolState {
        awaitingValidatorInfo,
        acceptingDeposits,
        staked,
        exited
    }
    PoolState currentState;
    
    //this is unused in this version of the system
    //it must be included to avoid requiring an update to FrensPoolShare when rageQuit is added
    struct RageQuit {
        uint price;
        uint time;
        bool rageQuitting;
    }

    //maps the ID for each FrensPoolShare NFT in the pool to the deposit for that share
    mapping(uint => uint) public depositForId;
    //maps each ID to the rewards it has already claimed (used in calculating the claimable rewards)
    mapping(uint => uint) public frenPastClaim;
    //this is unused in this version of the system
    //it must be included to avoid requiring an update to FrensPoolShare when rageQuit is added
    mapping(uint => bool) public locked; //transfer locked (must use ragequit)
    //this is unused in this version of the system
    //it must be included to avoid requiring an update to FrensPoolShare when rageQuit is added
    mapping(uint => RageQuit) public rageQuitInfo;

    //total eth deposited to pool by users (does not include attestation or block rewards)
    uint public totalDeposits;
    //total amount of rewards claimed from pool (used in calculating the claimable rewards)
    uint public totalClaims;
    //these are the ids which have deposits in this pool
    uint[] public idsInPool;

    //this is set in the constructor and requires the validator public key and other validator info be set before deposits can be made
    //also, if the validator is locked, once set, the pool owner cnnot change the validator pubkey and other info
    bool public validatorLocked;
    //this is unused in this version of the system
    //it must be included to avoid requiring an update to FrensPoolShare when rageQuit is added
    bool public transferLocked;
    //set as true once the validator info has been set for the pool
    bool public validatorSet;

    //validator public key for pool
    bytes public pubKey;
    //validator withdrawal credentials - must be set to pool address
    bytes public withdrawal_credentials;
    //bls signature for validator
    bytes public signature;
    //deposit data root for validator
    bytes32 public deposit_data_root;

    IFrensPoolShare public frensPoolShare;
    IFrensArt public artForPool;
    IFrensStorage public frensStorage;

    /**@dev when the pool is deploied by the factory, the owner, art contract, 
    *storage contract, and if the validator is locked are all set. 
    *The pool state is set according to whether or not the validator is locked.
    */
    constructor(
        address owner_,
        bool validatorLocked_,
        IFrensStorage frensStorage_
    ) {
        frensStorage = frensStorage_;
        artForPool = IFrensArt(frensStorage.getAddress(keccak256(abi.encodePacked("contract.address", "FrensArt"))));
        frensPoolShare = IFrensPoolShare(frensStorage.getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare"))));
        validatorLocked = validatorLocked_;
        if (validatorLocked) {
            currentState = PoolState.awaitingValidatorInfo;
        } else {
            currentState = PoolState.acceptingDeposits;
        }
        _transferOwnership(owner_);
    }

    ///@notice This allows a user to deposit funds to the pool, and recieve an NFT representing their share
    ///@dev recieves funds and returns FrenspoolShare NFT
    function depositToPool()
        external
        payable
        noZeroValueTxn
        mustBeAccepting
        maxTotDep
    {
        uint id = frensPoolShare.totalSupply();
        depositForId[id] = msg.value;
        totalDeposits += msg.value;
        idsInPool.push(id);
        frenPastClaim[id] = 1; //this avoids future rounding errors in rewardclaims
        locked[id] = transferLocked;
        frensPoolShare.mint(msg.sender); //mint nft
        emit DepositToPool(msg.value, msg.sender, id);
    }

    ///@notice allows a user to add funds to an existing NFT ID
    ///@dev recieves funds and increases deposit for a FrensPoolShare ID
    function addToDeposit(uint _id) external payable mustBeAccepting maxTotDep correctPoolOnly(_id){
        require(frensPoolShare.exists(_id), "id does not exist"); //id must exist
        
        depositForId[_id] += msg.value;
        totalDeposits += msg.value;
    }

    ///@dev stakes 32 ETH from this pool to the deposit contract, accepts validator info
    function stake(
        bytes calldata _pubKey,
        bytes calldata _withdrawal_credentials,
        bytes calldata _signature,
        bytes32 _deposit_data_root
    ) external onlyOwner {
        //if validator info has previously been entered, check that it is the same, then stake
        if (validatorSet) {
            require(keccak256(_pubKey) == keccak256(pubKey), "pubKey mismatch");
        } else {
            //if validator info has not previously been entered, enter it, then stake
            _setPubKey(
                _pubKey,
                _withdrawal_credentials,
                _signature,
                _deposit_data_root
            );
        }
        _stake();
    }

    ///@dev stakes 32 ETH from this pool to the deposit contract. validator info must already be entered
    function stake() external onlyOwner {
        _stake();
    }

    function _stake() internal {
        require(address(this).balance >= 32 ether, "not enough eth");
        require(totalDeposits == 32 ether, "not enough deposits");
        require(currentState == PoolState.acceptingDeposits, "wrong state");
        require(validatorSet, "validator not set");
        
        address depositContractAddress = frensStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "DepositContract")));
        currentState = PoolState.staked;
        IDepositContract(depositContractAddress).deposit{value: 32 ether}(
            pubKey,
            withdrawal_credentials,
            signature,
            deposit_data_root
        );
        emit Stake(depositContractAddress, msg.sender);
    }

    ///@dev sets the validator info required when depositing to the deposit contract
    function setPubKey(
        bytes calldata _pubKey,
        bytes calldata _withdrawal_credentials,
        bytes calldata _signature,
        bytes32 _deposit_data_root
    ) external onlyOwner {
        _setPubKey(
            _pubKey,
            _withdrawal_credentials,
            _signature,
            _deposit_data_root
        );
    }

    function _setPubKey(
        bytes calldata _pubKey,
        bytes calldata _withdrawal_credentials,
        bytes calldata _signature,
        bytes32 _deposit_data_root
    ) internal {
        //get expected withdrawal_credentials based on contract address
        bytes memory withdrawalCredFromAddr = _toWithdrawalCred(address(this));
        //compare expected withdrawal_credentials to provided
        require(
            keccak256(_withdrawal_credentials) ==
                keccak256(withdrawalCredFromAddr),
            "withdrawal credential mismatch"
        );
        if (validatorLocked) {
            require(currentState == PoolState.awaitingValidatorInfo, "wrong state");
            assert(!validatorSet); //this should never fail
            currentState = PoolState.acceptingDeposits;
        }
        require(currentState == PoolState.acceptingDeposits, "wrong state");
        pubKey = _pubKey;
        withdrawal_credentials = _withdrawal_credentials;
        signature = _signature;
        deposit_data_root = _deposit_data_root;
        validatorSet = true;
    }

    ///@notice To withdraw funds previously deposited - ONLY works before the funds are staked. Use Claim to get rewards.
    ///@dev allows user to withdraw funds if they have not yet been deposited to the deposit contract with the Stake method
    function withdraw(uint _id, uint _amount) external mustBeAccepting {
        require(msg.sender == frensPoolShare.ownerOf(_id), "not the owner");
        require(depositForId[_id] >= _amount, "not enough deposited");
        depositForId[_id] -= _amount;
        totalDeposits -= _amount;
        (bool success, /*return data*/) = frensPoolShare.ownerOf(_id).call{value: _amount}("");
        assert(success);
    }

    ///@notice allows user to claim their portion of the rewards
    ///@dev calculates the rewards due to `_id` and sends them to the owner of `_id`
    function claim(uint _id) external correctPoolOnly(_id){
        require(
            currentState != PoolState.acceptingDeposits,
            "use withdraw when not staked"
        );
        require(
            address(this).balance > 100,
            "must be greater than 100 wei to claim"
        );
        //has the validator exited?
        bool exited;
        if (currentState != PoolState.exited) {
            IFrensOracle frensOracle = IFrensOracle(frensStorage.getAddress(keccak256(abi.encodePacked("contract.address", "FrensOracle"))));
            exited = frensOracle.checkValidatorState(address(this));
            if (exited && currentState == PoolState.staked ){
                currentState = PoolState.exited;
            }
        } else exited = true;
        //get share for id
        uint amount = _getShare(_id);
        //claim
        frenPastClaim[_id] += amount;
        totalClaims += amount;
        //fee? not applied to exited
        uint feePercent = frensStorage.getUint(keccak256(abi.encodePacked("protocol.fee.percent")));
        if (feePercent > 0 && !exited) {
            address feeRecipient = frensStorage.getAddress(keccak256(abi.encodePacked("protocol.fee.recipient")));
            uint feeAmount = (feePercent * amount) / 100;
            if (feeAmount > 1){ 
                (bool success1, /*return data*/) = feeRecipient.call{value: feeAmount - 1}(""); //-1 wei to avoid rounding error issues
                assert(success1);
            }
            amount = amount - feeAmount;
        }
        (bool success2, /*return data*/) = frensPoolShare.ownerOf(_id).call{value: amount}("");
        assert(success2);
    }

    //getters

    function getIdsInThisPool() public view returns(uint[] memory) {
      return idsInPool;
    }

    ///@return the share of the validator rewards climable by `_id`
    function getShare(uint _id) public view correctPoolOnly(_id) returns (uint) {
        return _getShare(_id);
    }

    function _getShare(uint _id) internal view returns (uint) {
        if (address(this).balance == 0) return 0;
        uint frenDep = depositForId[_id];
        uint frenPastClaims = frenPastClaim[_id];
        uint totFrenRewards = ((frenDep * (address(this).balance + totalClaims)) / totalDeposits);
        if (totFrenRewards == 0) return 0;
        uint amount = totFrenRewards - frenPastClaims;
        return amount;
    }

    ///@return the share of the validator rewards climable by `_id` minus fees. Returns 0 if pool is still accepting deposits
    ///@dev this is used for the traits in the NFT
    function getDistributableShare(uint _id) public view returns (uint) {
        if (currentState == PoolState.acceptingDeposits) {
            return 0;
        } else {
            uint share = _getShare(_id);
            uint feePercent = frensStorage.getUint(keccak256(abi.encodePacked("protocol.fee.percent")));
            if (feePercent > 0 && currentState != PoolState.exited) {
                uint feeAmount = (feePercent * share) / 100;
                share = share - feeAmount;
            }
            return share;
        }
    }

    ///@return pool state
    function getState() public view returns (string memory) {
        if (currentState == PoolState.awaitingValidatorInfo)
            return "awaiting validator info";
        if (currentState == PoolState.staked) return "staked";
        if (currentState == PoolState.acceptingDeposits)
            return "accepting deposits";
        if (currentState == PoolState.exited) return "exited";
        return "state failure"; //should never happen
    }

    function owner()
        public
        view
        override(IStakingPool, Ownable)
        returns (address)
    {
        return super.owner();
    }

    function _toWithdrawalCred(address a) private pure returns (bytes memory) {
        uint uintFromAddress = uint256(uint160(a));
        bytes memory withdralDesired = abi.encodePacked(
            uintFromAddress +
                0x0100000000000000000000000000000000000000000000000000000000000000
        );
        return withdralDesired;
    }

    ///@dev allows pool owner to change the art for the NFTs in the pool
    function setArt(IFrensArt newArtContract) external onlyOwner {
        IFrensArt newFrensArt = newArtContract;
        string memory newArt = newFrensArt.renderTokenById(1);
        require(bytes(newArt).length != 0, "invalid art contract");
        artForPool = newArtContract;
    }

    // to support receiving ETH by default
    receive() external payable {}

    fallback() external payable {}
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./IFrensArt.sol";

interface IStakingPoolFactory {

  function create(
    address _owner, 
    bool _validatorLocked 
    //bool frensLocked,
    //uint poolMin,
    //uint poolMax
   ) external returns(address);

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";


interface IFrensPoolShare is IERC721Enumerable{
  
  function poolByIds(uint _id) external view returns(address);

  function mint(address userAddress) external;

  function burn(uint tokenId) external;

  function exists(uint _id) external view returns(bool);

  function getPoolById(uint _id) external view returns(address);

  function tokenURI(uint256 id) external view returns (string memory);

  function renderTokenById(uint256 id) external view returns (string memory);

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IFrensArt {
  function renderTokenById(uint256 id) external view returns (string memory);
}

pragma solidity >=0.8.0 <0.9.0;


// SPDX-License-Identifier: GPL-3.0-only
//modified from IRocketStorage on 03/12/2022 by 0xWildhare

interface IFrensStorage {

   
    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;
    function burnKeys() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getBool(bytes32 _key) external view returns (bool);   

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setBool(bytes32 _key, bool _value) external;    

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;    

    // Arithmetic 
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
    
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

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT


interface IDepositContract {

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    function get_deposit_count() external view returns (bytes memory);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IFrensArt.sol";

interface IStakingPool {

    function pubKey() external view returns(bytes memory);

    function depositForId(uint _id) external view returns (uint);

    function totalDeposits() external view returns(uint);

    function transferLocked() external view returns(bool);

    function locked(uint id) external view returns(bool);

    function artForPool() external view returns (IFrensArt);

    function owner() external view returns (address);

    function depositToPool() external payable;

    function addToDeposit(uint _id) external payable;

    function withdraw(uint _id, uint _amount) external;

    function claim(uint id) external;

    function getIdsInThisPool() external view returns(uint[] memory);

    function getShare(uint _id) external view returns (uint);

    function getDistributableShare(uint _id) external view returns (uint);

    function rageQuitInfo(uint id) external view returns(uint, uint, bool);

    function setPubKey(
        bytes calldata pubKey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external;

    function getState() external view returns (string memory);

    // function getDepositAmount(uint _id) external view returns(uint);

    function stake(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external;

    function stake() external;

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT


interface IFrensOracle {

   function checkValidatorState(address pool) external returns(bool);

   function setExiting(bytes memory pubKey, bool isExiting) external;

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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