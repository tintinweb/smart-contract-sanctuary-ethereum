pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./interfaces/IStakingPool.sol";
import "./FrensBase.sol";


//should ownable be replaces with an equivalent in storage/base?
contract StakingPool is IStakingPool, Ownable, FrensBase {

  event Stake(address depositContractAddress, address caller);
  event DepositToPool(uint amount, address depositer);

  IFrensPoolShare frensPoolShare;

  constructor(address owner_, IFrensStorage frensStorage_) FrensBase(frensStorage_){
    address frensPoolShareAddress = getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare")));
    frensPoolShare = IFrensPoolShare(frensPoolShareAddress); //this hardcodes the nft contract to the pool
    _transferOwnership(owner_);

  }
//TODO: needs to interact with SSVtoken (via amm, check balance, check minimum amount needed in contract etc)
  function depositToPool() public payable {
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "not accepting deposits");
    require(msg.value != 0, "must deposit ether");
    require(getUint(keccak256(abi.encodePacked("total.deposits", address(this)))) + msg.value <= 32 ether, "total depostis cannot be more than 32 Eth");
    addUint(keccak256(abi.encodePacked("token.id")), 1);
    uint id = getUint(keccak256(abi.encodePacked("token.id")));
    setUint(keccak256(abi.encodePacked("deposit.amount", id)), msg.value);
    addUint(keccak256(abi.encodePacked("total.deposits", address(this))), msg.value);
    pushUint(keccak256(abi.encodePacked("ids.in.pool", address(this))), id);
    frensPoolShare.mint(msg.sender, address(this));
    emit DepositToPool(msg.value,  msg.sender);
  }

  function addToDeposit(uint _id) public payable {
    require(frensPoolShare.exists(_id), "id does not exist");
    require(getAddress(keccak256(abi.encodePacked("pool.for.id", _id))) == address(this), "wrong staking pool");
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "not accepting deposits");
    require(getUint(keccak256(abi.encodePacked("total.deposits", address(this)))) + msg.value <= 32 ether, "total depostis cannot be more than 32 Eth");
    addUint(keccak256(abi.encodePacked("deposit.amount", _id)), msg.value);
    addUint(keccak256(abi.encodePacked("total.deposits", address(this))), msg.value);
  }

  function withdraw(uint _id, uint _amount) public {
    require(_getStateHash() != _getStringHash("staked"), "cannot withdraw once staked");//TODO: this may need to be more restrictive
    require(msg.sender == frensPoolShare.ownerOf(_id), "not the owner");
    require(getUint(keccak256(abi.encodePacked("deposit.amount", _id))) >= _amount, "not enough deposited");
    subUint(keccak256(abi.encodePacked("deposit.amount", _id)), _amount);
    subUint(keccak256(abi.encodePacked("total.deposits", address(this))), _amount);
    payable(msg.sender).transfer(_amount);
  }
  //TODO think about other options for distribution
  function distribute() public {
    require(_getStateHash() == _getStringHash("staked"), "use withdraw when not staked");
    uint contractBalance = address(this).balance;
    uint[] memory idsInPool = getIdsInThisPool();
    require(contractBalance > 100, "minimum of 100 wei to distribute");
    for(uint i=0; i<idsInPool.length; i++) {
      uint id = idsInPool[i];
      address tokenOwner = frensPoolShare.ownerOf(id);
      uint share = _getShare(id, contractBalance);
      payable(tokenOwner).transfer(share);
    }
  }

  function getIdsInThisPool() public view returns(uint[] memory) {
    return getArray(keccak256(abi.encodePacked("ids.in.pool", address(this))));
  }

  function _getShare(uint _id, uint _contractBalance) internal view returns(uint) {
    uint depAmt = getUint(keccak256(abi.encodePacked("deposit.amount", _id)));
    uint totDeps = getUint(keccak256(abi.encodePacked("total.deposits", address(this))));
    if(depAmt == 0) return 0;
    uint calcedShare =  _contractBalance * depAmt / totDeps;
    if(calcedShare > 1){
      return(calcedShare - 1); //steal 1 wei to avoid rounding errors drawing balance negative
    }else return 0;
  }

  function getShare(uint _id) public view returns(uint) {
    uint contractBalance = address(this).balance;
    return _getShare(_id, contractBalance);
  }

  function getDistributableShare(uint _id) public view returns(uint) {
    if(_getStateHash() == _getStringHash("acceptingDeposits")) {
      return 0;
    } else {
      return getShare(_id);
    }
  }

  function getPubKey() public view returns(bytes memory){
    return getBytes(keccak256(abi.encodePacked("validator.public.key", address(this))));
  }

  function setPubKey(bytes memory _publicKey) public onlyOwner{
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "wrong state");
    //add checks for ssv operators?
    setBytes(keccak256(abi.encodePacked("validator.public.key", address(this))), _publicKey);
  }

  function getState() public view returns(string memory){
    return getString(keccak256(abi.encodePacked("contract.state", address(this))));
  }

  function _getStateHash() internal view returns(bytes32){
    return keccak256(abi.encodePacked(getState()));
  }

  function _getStringHash(string memory s) internal pure returns(bytes32){
    return keccak256(abi.encodePacked(s));
  }

  function getDepositAmount(uint _id) public view returns(uint){
    return getUint(keccak256(abi.encodePacked("deposit.amount", _id)));
  }

  function getTotalDeposits() public view returns(uint){
    return getUint(keccak256(abi.encodePacked("total.deposits", address(this))));
  }

  function owner() public view override(IStakingPool, Ownable) returns (address){
    return super.owner();
  }

//should staking info be added to pool before depositing is enabled?
  function stake(
    bytes calldata pubKey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) public onlyOwner{
    require(address(this).balance >= 32 ether, "not enough eth");
    require(_getStateHash() == _getStringHash("acceptingDeposits"), "wrong state");
    bytes memory zero;
    bytes memory validatorPublicKey = getBytes(keccak256(abi.encodePacked("validator.public.key", address(this))));
    if(keccak256(validatorPublicKey) != keccak256(zero)){
      require(keccak256(validatorPublicKey) == keccak256(pubKey), "pubkey does not match stored value");
    } else setBytes(keccak256(abi.encodePacked("validator.public.key", address(this))), pubKey);
    setString(keccak256(abi.encodePacked("contract.state", address(this))), "staked");
    uint value = 32 ether;
    //get expected withdrawal_credentials based on contract address
    bytes memory withdrawalCredFromAddr = _toWithdrawalCred(address(this));
    //compare expected withdrawal_credentials to provided
    require(keccak256(withdrawal_credentials) == keccak256(withdrawalCredFromAddr), "withdrawal credential mismatch");
    address depositContractAddress = getAddress(keccak256(abi.encodePacked("external.contract.address", "DepositContract")));
    IDepositContract(depositContractAddress).deposit{value: value}(pubKey, withdrawal_credentials, signature, deposit_data_root);
    emit Stake(depositContractAddress, msg.sender);
  }

  function _toWithdrawalCred(address a) private pure returns (bytes memory) {
    uint uintFromAddress = uint256(uint160(a));
    bytes memory withdralDesired = abi.encodePacked(uintFromAddress + 0x0100000000000000000000000000000000000000000000000000000000000000);
    return withdralDesired;
  }

//REMOVE rugpull is for testing only and should not be in the mainnet version
//if this gets deploied on mainnet call 911 or DM @0xWildhare
  function rugpull() public onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }
//REMOVE setFrensPoolShare is for testing only and should not be in the mainnet version
  function setFrensPoolShare(address frensPoolShareAddress_) public onlyOwner {
    frensPoolShare = IFrensPoolShare(frensPoolShareAddress_);
  }

  function unstake() public onlyOwner{
    if(address(this).balance > 100){
      distribute();
    }
    setString(keccak256(abi.encodePacked("contract.state", address(this))), "exited");

    //TODO what else needs to be in here (probably a limiting modifier and/or some requires)
    //TODO: is this where we extract fees?
  }


  // to support receiving ETH by default
  receive() external payable {

  }

  fallback() external payable {}
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT


interface IDepositContract {

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";


interface IFrensPoolShare is IERC721Enumerable{

  function mint(address userAddress, address _pool) external;

  function exists(uint _id) external view returns(bool);

  function getPoolById(uint _id) external view returns(address);

  function tokenURI(uint256 id) external view returns (string memory);

  function renderTokenById(uint256 id) external view returns (string memory);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IStakingPool{

  function owner() external view returns (address);

  function depositToPool() external payable;

  function addToDeposit(uint _id) external payable;

  function withdraw(uint _id, uint _amount) external;

  function distribute() external;

  function getIdsInThisPool() external view returns(uint[] memory);

  function getShare(uint _id) external view returns(uint);

  function getDistributableShare(uint _id) external view returns(uint);

  function getPubKey() external view returns(bytes memory);

  function setPubKey(bytes memory _publicKey) external;

  function getState() external view returns(string memory);

  function getDepositAmount(uint _id) external view returns(uint);


  function stake(
    bytes calldata pubkey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) external;

    function unstake() external;

}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/IFrensStorage.sol";

/// @title Base settings / modifiers for each contract in Frens Pool
/// @author modified 04-Dec-2022 by 0xWildhare originally by David Rugendyke (h/t David and Rocket Pool!)
/// this code is modified from the Rocket Pool RocketBase contract all "Rocket" replaced with "Frens"

abstract contract FrensBase {

    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    IFrensStorage frensStorage;


    /*** Modifiers **********************************************************/

    /**
    * @dev Throws if called by any sender that doesn't match a Frens Pool network contract
    */
    modifier onlyLatestNetworkContract() {
        require(getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
    */
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))), "Invalid or outdated contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered node
    */
    //removed  0xWildhare
    /*
    modifier onlyRegisteredNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress))), "Invalid node");
        _;
    }
    */
    /**
    * @dev Throws if called by any sender that isn't a trusted node DAO member
    */
    //removed  0xWildhare
    /*
    modifier onlyTrustedNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("dao.trustednodes.", "member", _nodeAddress))), "Invalid trusted node");
        _;
    }
    */

    /**
    * @dev Throws if called by any sender that isn't a registered Frens StakingPool
    */
    modifier onlyStakingPool(address _stakingPoolAddress) {
        require(getBool(keccak256(abi.encodePacked("pool.exists", _stakingPoolAddress))), "Invalid Pool");
        _;
    }


    /**
    * @dev Throws if called by any account other than a guardian account (temporary account allowed access to settings before DAO is fully enabled)
    */
    modifier onlyGuardian() {
        require(msg.sender == frensStorage.getGuardian(), "Account is not a temporary guardian");
        _;
    }


    





    /*** Methods **********************************************************/

    /// @dev Set the main Frens Storage address
    constructor(IFrensStorage _frensStorage) {
        // Update the contract address
        frensStorage = IFrensStorage(_frensStorage);
    }


    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }


    /// @dev Get the address of a network contract by name (returns address(0x0) instead of reverting if contract does not exist)
    function getContractAddressUnsafe(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Return
        return contractAddress;
    }


    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress) internal view returns (string memory) {
        // Get the contract name
        string memory contractName = getString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }



    /*** Frens Storage Methods ****************************************/

    // Note: Unused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) { return frensStorage.getAddress(_key); }
    function getUint(bytes32 _key) internal view returns (uint) { return frensStorage.getUint(_key); }
    function getString(bytes32 _key) internal view returns (string memory) { return frensStorage.getString(_key); }
    function getBytes(bytes32 _key) internal view returns (bytes memory) { return frensStorage.getBytes(_key); }
    function getBool(bytes32 _key) internal view returns (bool) { return frensStorage.getBool(_key); }
    function getInt(bytes32 _key) internal view returns (int) { return frensStorage.getInt(_key); }
    function getBytes32(bytes32 _key) internal view returns (bytes32) { return frensStorage.getBytes32(_key); }
    function getArray(bytes32 _key) internal view returns (uint[] memory) { return frensStorage.getArray(_key); }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal { frensStorage.setAddress(_key, _value); }
    function setUint(bytes32 _key, uint _value) internal { frensStorage.setUint(_key, _value); }
    function setString(bytes32 _key, string memory _value) internal { frensStorage.setString(_key, _value); }
    function setBytes(bytes32 _key, bytes memory _value) internal { frensStorage.setBytes(_key, _value); }
    function setBool(bytes32 _key, bool _value) internal { frensStorage.setBool(_key, _value); }
    function setInt(bytes32 _key, int _value) internal { frensStorage.setInt(_key, _value); }
    function setBytes32(bytes32 _key, bytes32 _value) internal { frensStorage.setBytes32(_key, _value); }
    function setArray(bytes32 _key, uint[] memory _value) internal { frensStorage.setArray(_key, _value); }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal { frensStorage.deleteAddress(_key); }
    function deleteUint(bytes32 _key) internal { frensStorage.deleteUint(_key); }
    function deleteString(bytes32 _key) internal { frensStorage.deleteString(_key); }
    function deleteBytes(bytes32 _key) internal { frensStorage.deleteBytes(_key); }
    function deleteBool(bytes32 _key) internal { frensStorage.deleteBool(_key); }
    function deleteInt(bytes32 _key) internal { frensStorage.deleteInt(_key); }
    function deleteBytes32(bytes32 _key) internal { frensStorage.deleteBytes32(_key); }
    function deleteArray(bytes32 _key) internal { frensStorage.deleteArray(_key); }

    /// @dev Storage arithmetic methods - push added by 0xWildhare
    function addUint(bytes32 _key, uint256 _amount) internal { frensStorage.addUint(_key, _amount); }
    function subUint(bytes32 _key, uint256 _amount) internal { frensStorage.subUint(_key, _amount); }
    function pushUint(bytes32 _key, uint256 _amount) internal { frensStorage.pushUint(_key, _amount); }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

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

pragma solidity >=0.8.0 <0.9.0;


// SPDX-License-Identifier: GPL-3.0-only
//modified from IRocketStorage on 03/12/2022 by 0xWildhare

interface IFrensStorage {

    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);
    function getArray(bytes32 _key) external view returns (uint[] memory);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;
    function setArray(bytes32 _key, uint[] calldata _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
    function deleteArray(bytes32 _key) external;

    // Arithmetic (and stuff) - push added by 0xWildhare
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
    function pushUint(bytes32 _key, uint256 _amount) external;

    // Protected storage removed ~ 0xWildhare
    /*
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
    */
}