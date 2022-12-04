// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./StakingPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract StakingPoolFactory is Ownable{

  mapping(address => bool) existsStakingPool;

  //this is used for testing may be removed for deployment
  address public lastContract;

  address depositContractAddress;
  address ssvRegistryAddress;
  address frensPoolShareAddress;

  event Create(
    address indexed contractAddress,
    address creator,
    address owner,
    address depositContractAddress
  );

  constructor(address depContAddress_, address ssvRegistryAddress_) {
    depositContractAddress = depContAddress_;
    ssvRegistryAddress = ssvRegistryAddress_;
  }
  function setFrensPoolShare(address frensPoolShareAddress_) public onlyOwner {
    frensPoolShareAddress = frensPoolShareAddress_;
  }

  function create(
    address owner_
  ) public returns(address) {
    StakingPool stakingPool = new StakingPool(depositContractAddress, address(this), frensPoolShareAddress, owner_);
    existsStakingPool[address(stakingPool)] = true;
    lastContract = address(stakingPool); //used for testing can be removed
    emit Create(address(stakingPool), msg.sender, owner_, depositContractAddress);
    return(address(stakingPool));
  }

  function doesStakingPoolExist(address _stakingPoolAddress) public view returns(bool){
    return(existsStakingPool[_stakingPoolAddress]);
  }

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IFrensPoolShare.sol";


contract StakingPool is Ownable {

  event Stake(address depositContractAddress, address caller);
  event DepositToPool(uint amount, address depositer);

  mapping (uint => uint) public depositAmount;
  uint public totalDeposits;
  uint[] public idsInThisPool;

  enum State { acceptingDeposits, staked, exited }
  State currentState;

  address public depositContractAddress;
  bytes public validatorPubKey;

  IDepositContract depositContract;
  IStakingPoolFactory factoryContract;
  IFrensPoolShare frensPoolShare;

  constructor(address depositContractAddress_, address factory_, address frensPoolShareAddress_, address owner_) {
    currentState = State.acceptingDeposits;
    depositContractAddress = depositContractAddress_;
    depositContract = IDepositContract(depositContractAddress);
    factoryContract = IStakingPoolFactory(factory_);
    frensPoolShare = IFrensPoolShare(frensPoolShareAddress_);
    _transferOwnership(owner_);

  }

  function depositToPool() public payable {
    require(currentState == State.acceptingDeposits, "not accepting deposits");
    require(msg.value != 0, "must deposit ether");
    uint id = frensPoolShare.incrementTokenId();
    depositAmount[id] = msg.value;
    totalDeposits += msg.value;
    idsInThisPool.push(id);
    frensPoolShare.mint(msg.sender, id, address(this));
    emit DepositToPool(msg.value, msg.sender);
  }

  function addToDeposit(uint _id) public payable {
    require(frensPoolShare.exists(_id), "not exist");
    require(frensPoolShare.getPoolById(_id) == address(this), "wrong staking pool");
    require(currentState == State.acceptingDeposits, "not accepting deposits");
    require(currentState == State.acceptingDeposits);
    depositAmount[_id] += msg.value;
    totalDeposits += msg.value;
  }

  function withdraw(uint _id, uint _amount) public {
    require(currentState != State.staked, "cannot withdraw once staked");
    require(msg.sender == frensPoolShare.ownerOf(_id), "not the owner");
    require(depositAmount[_id] >= _amount, "not enough deposited");
    depositAmount[_id] -= _amount;
    totalDeposits -= _amount;
    payable(msg.sender).transfer(_amount);
  }

  function distribute() public {
    require(currentState == State.staked, "use withdraw when not staked");
    uint contractBalance = address(this).balance;
    require(contractBalance > 100, "minimum of 100 wei to distribute");
    for(uint i=0; i<idsInThisPool.length; i++) {
      uint id = idsInThisPool[i];
      address tokenOwner = frensPoolShare.ownerOf(id);
      uint share = _getShare(id, contractBalance);
      payable(tokenOwner).transfer(share);
    }
  }

  function _getShare(uint _id, uint _contractBalance) internal view returns(uint) {
    if(depositAmount[_id] == 0) return 0;
    uint calcedShare =  _contractBalance * depositAmount[_id] / totalDeposits;
    if(calcedShare > 1){
      return(calcedShare - 1); //steal 1 wei to avoid rounding errors drawing balance negative
    }else return 0;
  }

  function getShare(uint _id) public view returns(uint) {
    uint contractBalance = address(this).balance;
    return _getShare(_id, contractBalance);
  }

  function getDistributableShare(uint _id) public view returns(uint) {
    if(currentState == State.acceptingDeposits) {
      return 0;
    } else {
      return getShare(_id);
    }
  }

  function getPubKey() public view returns(bytes memory){
    return validatorPubKey;
  }

  function setPubKey(bytes memory publicKey) public onlyOwner{
    validatorPubKey = publicKey;
  }

  function getState() public view returns(string memory){
    if(currentState == State.staked) return "staked";
    if(currentState == State.acceptingDeposits) return "accepting deposits";
    if(currentState == State.exited) return "exited";
    return "state failure"; //should never happen
  }

  function getDepositAmount(uint _id) public view returns(uint){
    return depositAmount[_id];
  }


  function stake(
    bytes calldata pubkey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) public onlyOwner{
    require(address(this).balance >= 32 ether, "not enough eth");
    require(currentState == State.acceptingDeposits, "wrong state");
    bytes memory zero;
    if(keccak256(validatorPubKey) != keccak256(zero)){
      require(keccak256(validatorPubKey) == keccak256(pubkey), "pubkey does not match stored value");
    } else validatorPubKey = pubkey;
    currentState = State.staked;
    uint value = 32 ether;
    //get expected withdrawal_credentials based on contract address
    bytes memory withdrawalCredFromAddr = _toWithdrawalCred(address(this));
    //compare expected withdrawal_credentials to provided
    require(keccak256(withdrawal_credentials) == keccak256(withdrawalCredFromAddr), "withdrawal credential mismatch");
    depositContract.deposit{value: value}(pubkey, withdrawal_credentials, signature, deposit_data_root);
    emit Stake(depositContractAddress, msg.sender);
  }

  function _toWithdrawalCred(address a) private pure returns (bytes memory) {
    uint uintFromAddress = uint256(uint160(a));
    bytes memory withdralDesired = abi.encodePacked(uintFromAddress + 0x0100000000000000000000000000000000000000000000000000000000000000);
    return withdralDesired;
  }

//REMOVE rugpull is for testing only and should not be in the mainnet version
  function rugpull() public onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }
//REMOVE setFrensPoolShare is for testing only and should not be in the mainnet version
  function setFrensPoolShare(address frensPoolShareAddress_) public onlyOwner {
    frensPoolShare = IFrensPoolShare(frensPoolShareAddress_);
  }

  function unstake() public {
    distribute();
    currentState = State.exited;
    //TODO what else needs to be in here (probably a limiting modifier and/or some requires)
  }


  // to support receiving ETH by default
  receive() external payable {
    /*
    _tokenId++;
    uint256 id = _tokenId;
    depositAmount[id] = msg.value;
    _mint(msg.sender, id);
    */
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

interface IStakingPoolFactory {

  function doesStakingPoolExist(address stakingPoolAddress) external view returns(bool);

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

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";


interface IFrensPoolShare is IERC721Enumerable{
  function incrementTokenId() external returns(uint);

  function mint(address userAddress, uint id, address _pool) external;

  function exists(uint _id) external returns(bool);

  function getPoolById(uint _id) external view returns(address);


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