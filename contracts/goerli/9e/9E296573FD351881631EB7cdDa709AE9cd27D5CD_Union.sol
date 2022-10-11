//SPDX-License-Identifier: MIT


// We can look at Governor.sol from OZ, but we need to simply implement off-chain voting by tg api, so we should look at snapshot mechanism



pragma solidity ^0.8.0;

//import "hardhat/console.sol";

// direct imports -- use it for compile contracts and webapp

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


// relative imports (for building ABI and go) -- use it for build

/*
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
*/


import "./TGPassport.sol";

contract Union is Ownable {

    using Counters for Counters.Counter;

    uint private _passportFee;
    address private _owner = owner();

    bytes4 private constant _INTERFACE_ID_IERC721ENUMERABLE = 0x780e9d63;

    // events
    event ApplicationForJoin(int64 chat_id, int64 applier_id,address multy_wallet_address,VotingType vote_type, address voting_token_address, string group_name);
    event ApplicationForJoinIndexed(int64 indexed chat_id, int64 applier_id,address multy_wallet_address,VotingType vote_type, address voting_token_address, string group_name);
    event ApprovedJoin(int chat_id,address multy_wallet_address,VotingType vote_type, address voting_token_address, string group_name);
    event DeclinedApplication(int chat_id,address multy_wallet_address,VotingType vote_type, address voting_token_address, string group_name);



    //
    enum VotingType {erc20, erc20Snapshot, erc721 }


    // Meta information about dao
    struct DAO {
      address chatOwnerAddress;
      int64 tgId;
      bool valid;
      address multisigAddress;
      VotingType votingType;
      address votingToken;
      string group_name;
               }



    // set passport contract address
    constructor(address passportContract_){
        _passportContract = passportContract_;
        tgpassport = TGPassport(passportContract_);

        /*
        if (block.chainid == uint(4)) {
          tgpassport.
          ApplyForUnion(1111,1234567,address(0x0),VotingType.erc20,address(0x0),"bolvanka");
          ApproveJoin(address(0x0));
        }
        */
    }

    // TODO: import Multisig contract, make sure we map tgid to multisig contract, not address!
    mapping (int64 => address) public daoAddresses;

    int64[] public Chat_id_array;

    Counters.Counter dao_count;

    // mapping from multisig address to attached meta-info
    mapping(address => DAO) public daos;

    address private _passportContract;
    TGPassport public tgpassport;

    

    /**  This function suggest applying for union for any dao
    *   REQUIREMENTS:
    *   1.dao should have it's multisig address
    *   2.owner of multisig must be registred in Passport contract with it's personal tg_id
    *   3.  this tg_id must be equal to tgid of appling chat admin.
    *   Last check can be done only by oracle
    *   @param applyerTg -- tgid of user who sent apply
    *   @param daoTg -- tgid of chat
    *   @param dao_ -- multisig address
    *   @param votingType_ -- represents voting token's type: 0=erc20 1=erc20Snapshot 2=erc721
    *   @param dao_name_ -- string name of group chat. can be uses as a link (if link is https://t.me/eth_ru then name is @eth_ru)
    */
    function ApplyForUnion (int64 applyerTg, int64 daoTg, address dao_, VotingType votingType_, address votingTokenContract_, string memory dao_name_) public payable {
      // TODO: add require for check if dao is a gnosis safe multisig! (check support interface?)
      // require(...)
      
      // add passport and owner check
        address daoOwner = tgpassport.GetPassportWalletByID(applyerTg);
        require(daoOwner == msg.sender,"User did not registred in TGP");

      require(daoAddresses[daoTg] == address(0x0), "this chat tgid already taken");
      daoAddresses[daoTg] = dao_;      
      bool checkStandard = _checkStandardVotingToken(votingType_, votingTokenContract_);
      require(checkStandard == true,"Contract does not match with corresponding type");

      _passportFee = tgpassport.GetPassportFee();
      daos[dao_] = DAO(msg.sender, daoTg, false, dao_, votingType_, votingTokenContract_, dao_name_);
      (bool feePaid,) = _owner.call{value: _passportFee}("");  
      require(feePaid, "Unable to transfer fee");
      require (msg.value == _passportFee, "Passport fee is not paid");
      emit ApplicationForJoinIndexed(daoTg,applyerTg,dao_,votingType_,votingTokenContract_, dao_name_);
   }


    // This function intended to be used by bot, cause only bot can check if tg id of multisig owner is eqal of tg id of chat admin
    function ApproveJoin(address daoAddress) public onlyOwner {
      DAO memory org = daos[daoAddress];
      require(org.valid == false, "already has been approved OR didn't applied at all");
      org.valid = true;
      daos[daoAddress] = org;
      dao_count.increment();
      Chat_id_array.push(org.tgId);
      emit ApprovedJoin(org.tgId,org.multisigAddress,org.votingType,org.votingToken, org.group_name);
    }

    function DeclineJoin(address daoAddress) public onlyOwner {
        DAO memory org = daos[daoAddress];
        require(org.valid == false, "already has been approved OR didn't applied at all");
        delete daos[daoAddress];
        delete daoAddresses[org.tgId];
       // daoAddresses[org.tgId] = address(0x0);
        emit DeclinedApplication(org.tgId,org.multisigAddress,org.votingType,org.votingToken, org.group_name);
    }


    function  _checkStandardVotingToken(VotingType votingType_, address votingTokenContract_) internal view returns (bool success) {
      if (votingType_ == VotingType.erc721) {
      (success) = IERC721Enumerable(votingTokenContract_).
          supportsInterface(_INTERFACE_ID_IERC721ENUMERABLE);
          return success;
      }
      if (votingType_ == VotingType.erc20) {
        // TODO: check this. decimals of standard token should be equal 18. Probably remove this check
        (success) = IERC20Metadata(votingTokenContract_).decimals() == 18;
      }
      // TODO: add check for snapshot
    }


  function getDaoAddressbyChatId(int64 chat_id) public view returns (address) {
        address dao = daoAddresses[chat_id];
        return dao;
    }


  function getDaoCount() public view returns (uint256) {
     return dao_count.current();
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";                  // @WARN: it's direct import change to ../node_modules/ for ABI
//import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";    // @WARN: it's an absolute path witch is required for build abi, binaries and go files

contract TGPassport is Ownable {
   
   
   uint private _passportFee; 
   address private _owner; 

   struct Passport {
      address userAddress;
      int64 tgId;      // unic Id for telegram (number)
      bool valid;
      address validatorAddress;
      string userName; // can be changed, do not trust it
     // int64[] itrust_to; // I trust somebody
     // int64[] trusted_by; // somebody trust me
   }

   //mappings
   mapping(int64 => address) public tgIdToAddress;
   mapping(address => Passport) public passports;
   mapping(string => address) public username_wallets;  // usernames can be changed, do not trust it, use as utility
   mapping(int64 => int64[]) public itrust_to_global; // I trust somebody
   mapping(int64 => int64[]) public trusted_by_global; // somebody trust me
 
   // EVENTS
   //
   event passportApplied(int64 applyerTg, address wallet_address);
   event passportAppliedIndexed(int64 indexed applyerTg, address wallet_address);
   event passportApproved(int applyerTg, address wallet_address, address issuer);
   event passportDenied(int applyerTg, address wallet);


   constructor() Ownable() {
      _passportFee = 1000 wei; // TODO: calculate gas costs
      _owner = owner();
   }


   function _updateAddress(int64 tgId, address userAddress, string memory user_name_) internal {
      require(tgIdToAddress[tgId] == address(0x0), "There's address connected to that TG ID already.");  // if cell is not empty revert
      tgIdToAddress[tgId] = userAddress;
      username_wallets[user_name_] = userAddress;
   }

   /**
   *  @dev This function update user nicname if user change it
   */
   function UpdateUserName(string memory new_user_name_) public {
     Passport memory p = GetPassportByAddress(msg.sender);
     require(p.userAddress == msg.sender, "you don't now own this username");
     p.userName = new_user_name_;
     passports[msg.sender] = p;
   }

   /**
   *   @notice This function for USER who try to obtain some tg_id
   *   @param applyerTg unic id for telegram user, in telegram it's int64 (number)
   *   @param user_name_ is username (like @username)
   **/
   function ApplyForPassport (int64 applyerTg, string memory user_name_) public payable {
      address applyerAddress = msg.sender;      // ЛИЧНАЯ ПОДАЧА ПАСПОРТА В ТРЕТЬЕ ОКОШКО МФЦ
      _updateAddress(applyerTg,applyerAddress,user_name_);  
      require (msg.value == _passportFee, "Passport fee is not paid");

      passports[msg.sender] = Passport(applyerAddress, applyerTg, false, address(0x0),user_name_);
      emit passportApplied(applyerTg, msg.sender);
      emit passportAppliedIndexed(applyerTg, msg.sender);
      (bool feePaid,) = _owner.call{value: _passportFee}("");
      require(feePaid, "Unable to transfer fee");
   }

   /** 
   *    @notice  This function approving passport (use for bot) which approve that user owns it's tg_id and nicname he want to attach with
   *    @param passportToApprove address of user wallet which attached to him
   */
   function ApprovePassport (address passportToApprove) public onlyOwner {
        int64 _tgId = passports[passportToApprove].tgId;
        string memory user_name_ = passports[passportToApprove].userName;
        require(passports[passportToApprove].valid == false, "already approved OR do not exists yet");
        int64[] storage itrust = itrust_to_global[_tgId];
        itrust.push(_tgId);
        passports[passportToApprove] = Passport(passportToApprove, _tgId, true, msg.sender, user_name_);  
        emit passportApproved(_tgId,passportToApprove,msg.sender);
   }

   /**
   *     @notice This function decline application end erase junk data
   *     @param passportToDecline address of user wallet
   */
   function DeclinePassport (address passportToDecline) public onlyOwner {
      int64 _tgId = passports[passportToDecline].tgId;
      string memory user_name_ = passports[passportToDecline].userName;
      require(passports[passportToDecline].valid == false, "already approved OR do not exists yet"); // it also means that record exists
      delete passports[passportToDecline];
      delete tgIdToAddress[_tgId];
      delete username_wallets[user_name_];
      emit passportDenied(_tgId,passportToDecline);
   }

   /**
    *  @dev This function is a service function which allow Owner to erase already approved passport
    *  and make clean state contract. NOT FOR USE IN PRODUCTION
    */
    function DeletePassport (address passportToDecline) public onlyOwner {
      int64 _tgId = passports[passportToDecline].tgId;
      string memory user_name_ = passports[passportToDecline].userName;
      uint chainID = block.chainid;
      require(chainID == uint(4), "this function work's only for testnet");
     // require(passports[passportToDecline].valid == false, "already approved OR do not exists yet"); // it also means that record exists
      delete passports[passportToDecline];
      delete tgIdToAddress[_tgId];
      delete username_wallets[user_name_];
      emit passportDenied(_tgId,passportToDecline);
   }  


      /**
       * 
       *  @dev this function is to show trust to other user
       */
      function ITrustTo(int64 from, int64 to)  public {
         address from_ = GetPassportWalletByID(from);
         Passport memory p_from = GetPassportByAddress(from_);
         address to_ = GetPassportWalletByID(to);
         Passport memory p_to = GetPassportByAddress(to_);
         
         
      }



    /**
     *  @dev setting fee for applying for passport
     */
    function SetPassportFee(uint passportFee_) public onlyOwner {
        _passportFee = passportFee_;
    }

    /**
     *  @dev getter to obtain how much user will pay for apply
     */
    function GetPassportFee() public view returns (uint) {
        return _passportFee;
    }

   

   function GetPassportWalletByID(int64 tgId_) public view returns(address){
      return tgIdToAddress[tgId_];
   }

   function GetPassportByAddress(address user_wallet) public view returns(Passport memory) {
      Passport memory p = passports[user_wallet];
      return p;
   }

   function GetWalletByNickName(string memory user_name_) public view returns (address) {
      return username_wallets[user_name_];
   }

   function GetPassportByNickName(string memory user_name_) public view returns (Passport memory) {
      address wallet_ = GetWalletByNickName(user_name_);
      Passport memory p = passports[wallet_];
      return p;
   }

   function GetOwner() public view returns(address) {
      return _owner;
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