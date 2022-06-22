/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: profile5.sol


//0x3051Ef972bbdE713d293E13A5442608642eB9F1C

pragma solidity >=0.8.9 <0.9.0;

// import 'erc721a/contracts/ERC721A.sol';





contract profileContract is Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private totalTierUser;

  uint256 public silverTierPrice;
  uint256 public goldTierPrice;
  uint256 public tipFee;
  address private beneficiary;

  mapping(address => mapping(uint256 => NFTStruct)) private showCaseList;
  mapping(address => WishlistUser) private tokenAdddressWishListToUsers;
  // contract -> wallet -> tokenid
  //"0x" -> "ox1" -> long string

  mapping(address => tierStruct) public userTier;
  mapping(address => profileBioStruct) public userBio;

    struct NFTStruct {
      address tokenAddress;
      string tokenID;
    }

    struct WishlistUser {
      address[] user;
      string[] tokenID;
    }

    struct profileBioStruct {
      string userName;
      string userBio;
      string userTwitter;
      NFTStruct profilePic;
      NFTStruct bannerPic;
      uint256 showCaseAmount;
      uint256 wishListAmount;
      NFTStruct[] wishList;
    }

    struct tierStruct {
      uint256 index;
      uint256 tier;
    }

  //event

  modifier checkTierFromOffChain(uint256 _tier) {
    require(_tier == 1 || _tier == 2, 'wrong input from offchain!');
    _;
  }

  modifier checkUserTier(uint _tier) {
    require(userTier[msg.sender].tier < _tier, 'User already owned this tier or higher.');
    _;
  }

  modifier onlySilverTierORAbove () {
    require(userTier[msg.sender].tier >= 1, 'You must be Silver Tier member to proceed this action'); 
    _;
  }

   modifier onlyGoldTierORAbove () {
    require(userTier[msg.sender].tier >= 2, 'You must be Gold Tier member to proceed this action'); 
    _;
  }

  constructor(
    // string memory _tokenName,
    // string memory _tokenSymbol,
    address _beneficiary,
    uint256 _silverPrice,
    uint256 _goldPrice,
    uint256 _tipFee
  ) 
  // ERC721A(_tokenName, _tokenSymbol) 
  {
      setBeneficiary(_beneficiary);
      setSilverTierPrice(_silverPrice);
      setGoldTierPrice(_goldPrice);
      setTipfee(_tipFee);
  }

// -------- WishList function ------------------------------
  function AddWishListTokenAddressID (address[] calldata _wishListTokenAddress, 
                        string[] calldata _wishListTokenID) public onlySilverTierORAbove {
    require(_wishListTokenAddress.length == _wishListTokenID.length, "length mismatch");
    uint256 length = _wishListTokenAddress.length;
    //userBio[msg.sender].wishListAmount = length;
    for (uint256 i = 0; i < length; i++) {
      userBio[msg.sender].wishList.push(NFTStruct(_wishListTokenAddress[i],_wishListTokenID[i]));
      //tokenAdddressWishListToUsers[_wishListTokenAddress[i]][msg.sender] = _wishListTokenID[i];
      tokenAdddressWishListToUsers[_wishListTokenAddress[i]].user.push(msg.sender);
      tokenAdddressWishListToUsers[_wishListTokenAddress[i]].tokenID.push(_wishListTokenID[i]);
    }
  }

    function AddWishListTokenAddressIDTest (address _wishListTokenAddress
                        ) public onlySilverTierORAbove {
    //userBio[msg.sender].wishListAmount = length;
    for (uint256 i = 0; i < 1000000; i++) {
      string memory sss = new string(i);
      userBio[msg.sender].wishList.push(NFTStruct(_wishListTokenAddress,sss));
      tokenAdddressWishListToUsers[_wishListTokenAddress].user.push(msg.sender);
      tokenAdddressWishListToUsers[_wishListTokenAddress].tokenID.push(sss);
    }
  }

  function AddWishListTokenAddress (address[] calldata _wishListTokenAddress) public onlySilverTierORAbove {
    uint256 length = _wishListTokenAddress.length;
    //userBio[msg.sender].wishListAmount = length;
    for (uint256 i = 0; i < length; i++) {
      userBio[msg.sender].wishList.push(NFTStruct(_wishListTokenAddress[i],""));
    }
  }

  function getWishListTokenAddress () public view returns (NFTStruct[] memory) {
    return userBio[msg.sender].wishList;
  }

  function getWishListTokenAddressIndex (address _wishListTokenAddress, 
                                    string calldata _wishListTokenID) internal view returns (uint256) {
    uint256 _index;
    bool _ismatch;
    uint256 length = userBio[msg.sender].wishList.length;
    for (uint256 i = 0; i < length; i++) {
      if(userBio[msg.sender].wishList[i].tokenAddress == _wishListTokenAddress && keccak256(bytes(userBio[msg.sender].wishList[i].tokenID)) == keccak256(bytes(_wishListTokenID))) {
        _index = i;
        _ismatch = true;
        break;
      }
    }
    if(_ismatch) {
      return _index;
    } else {
      return length;
    }
  }

  function getWishListTokenAddressIndex (uint256 _id) public view returns (NFTStruct memory) {
    return userBio[msg.sender].wishList[_id];
  }

  function deleteWishListAddressID (address[] calldata _wishListTokenAddress, 
                                    string[] calldata _wishListTokenID) public onlySilverTierORAbove {
    uint256 length = _wishListTokenAddress.length;
    uint256 temp;
    for (uint256 i = 0; i < length; i++) {
      temp = getWishListTokenAddressIndex(_wishListTokenAddress[i], _wishListTokenID[i]);
      if(temp != userBio[msg.sender].wishList.length) {
        delete userBio[msg.sender].wishList[temp];
      }
    }
  }

  function replaceWishListAddressID (address[] calldata _wishListTokenAddress, 
                        string[] calldata _wishListTokenID) public onlySilverTierORAbove {
    require(_wishListTokenAddress.length == _wishListTokenID.length, "length mismatch");
    uint256 length = _wishListTokenAddress.length;
    delete userBio[msg.sender].wishList;
    for (uint256 i = 0; i < length; i++) {
      userBio[msg.sender].wishList.push(NFTStruct(_wishListTokenAddress[i],_wishListTokenID[i]));
    }
  }

   function getWishListByTokenAddress (address _tokenAddr) public view returns (WishlistUser memory) {
     return  tokenAdddressWishListToUsers[_tokenAddr];
   }

// -------- End of WishList function ------------------------------

// -------- Bio Function ------------------------------------------
  function setupBio (string calldata _userName, string calldata _userBio, string calldata _userTwitter) public {
    userBio[msg.sender].userName = _userName;
    userBio[msg.sender].userBio = _userBio;
    userBio[msg.sender].userTwitter = _userTwitter;

    // userBio[msg.sender].yo.push("x");
    // userBio[msg.sender].yo.push("y");

    // NFTStruct storage wl;

    // userBio[msg.sender].wishList.push(WishListStruct2("xxx","yyyyy"));
    // userBio[msg.sender].wishList.push(WishListStruct2("xxx111","yyyyy222"));
    // userBio[msg.sender].wishListTokenAddress.push("y");
    // userBio[msg.sender].wishListTokenAddress.push("z");
  }

  function tipMe (address _receiverAddr) public payable nonReentrant { 
    require(msg.sender == tx.origin, 'Smart Contract Caller is not allowed');
    require(msg.value >= tipFee, 'Insufficient funds');
    payable(_receiverAddr).transfer(tipFee);
  }

  function setUserTier (uint256 _tier) public payable checkTierFromOffChain(_tier) checkUserTier(_tier) {
    // 1 == gold
    if(_tier == 1) {
      require(msg.value >= silverTierPrice, 'Insufficient funds.');
      if(userTier[msg.sender].index == 0) {
        totalTierUser.increment();
        userTier[msg.sender].index = totalTierUser.current();
      }
      userTier[msg.sender].tier = 1;
    }
    // 2 == platinum
    else if(_tier == 2) {
      require(msg.value >= goldTierPrice, 'Insufficient funds');
      if(userTier[msg.sender].index == 0) {
        totalTierUser.increment();
        userTier[msg.sender].index = totalTierUser.current();
      }
      userTier[msg.sender].tier = 2;

    }
  }

// if not holding: not rendering (which means no need to update ownership on-chain)
  function setupShowCase (address[] calldata _tokenAddress,string[] calldata _tokenID) public { 
    // uint old_length = showCaseList[msg.sender].length;
    uint256 length = _tokenAddress.length;
    userBio[msg.sender].showCaseAmount = length;
    for (uint256 i = 0; i < length; i++) {
      showCaseList[msg.sender][i].tokenAddress =  _tokenAddress[i];
      showCaseList[msg.sender][i].tokenID =  _tokenID[i];
    }
  }

  function setupProfilePic (address _tokenAddress, string calldata _tokenID) public {
    userBio[msg.sender].profilePic.tokenAddress = _tokenAddress;
    userBio[msg.sender].profilePic.tokenID = _tokenID; 
  }

  function setupBioProfileBanner (string memory _userName,
                                string memory _userBio, 
                                string memory _userTwitter, 
                                address _profileTokenAddress, 
                                string memory _profileTokenID, 
                                address _bannerTokenAddress, 
                                string memory _bannerTokenID) public {
    userBio[msg.sender].userName = _userName;
    userBio[msg.sender].userBio = _userBio;
    userBio[msg.sender].userTwitter = _userTwitter;
    userBio[msg.sender].profilePic.tokenAddress = _profileTokenAddress;
    userBio[msg.sender].profilePic.tokenID = _profileTokenID; 
    userBio[msg.sender].bannerPic.tokenAddress = _bannerTokenAddress;
    userBio[msg.sender].bannerPic.tokenID = _bannerTokenID;
  }

  function setupBioProfileBannerShowcase (string memory _userName,
                                string memory _userBio, 
                                string memory _userTwitter, 
                                address _profileTokenAddress, 
                                string memory _profileTokenID, 
                                address _bannerTokenAddress, 
                                string memory _bannerTokenID,
                                address[] calldata _showCaseTokenAddress,
                                string[] calldata _showCaseTokenID) public {
    userBio[msg.sender].userName = _userName;
    userBio[msg.sender].userBio = _userBio;
    userBio[msg.sender].userTwitter = _userTwitter;
    userBio[msg.sender].profilePic.tokenAddress = _profileTokenAddress;
    userBio[msg.sender].profilePic.tokenID = _profileTokenID; 
    userBio[msg.sender].bannerPic.tokenAddress = _bannerTokenAddress;
    userBio[msg.sender].bannerPic.tokenID = _bannerTokenID;
    uint256 length = _showCaseTokenAddress.length;
    userBio[msg.sender].showCaseAmount = length;
    for (uint256 i = 0; i < length; i++) {
      showCaseList[msg.sender][i].tokenAddress =  _showCaseTokenAddress[i];
      showCaseList[msg.sender][i].tokenID =  _showCaseTokenID[i];
    }
  }

  function setupBannerPic (address _tokenAddress, string calldata _tokenID) public {
    userBio[msg.sender].bannerPic.tokenAddress = _tokenAddress;
    userBio[msg.sender].bannerPic.tokenID = _tokenID; 
  }

  function setSilverTierPrice(uint256 _silverTierPrice) public onlyOwner {
    silverTierPrice = _silverTierPrice;
  }

  function setGoldTierPrice(uint256 _goldTierPrice) public onlyOwner {
    goldTierPrice = _goldTierPrice;
  }

  function setTipfee(uint _tipFee) public onlyOwner {
      tipFee = _tipFee;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
      beneficiary = _beneficiary;
  }

  function getTotalTierUser() public view returns (uint256) {
    return totalTierUser.current();
  }

  function getShowCaseList(address _owner) public view returns (NFTStruct[] memory) {
    uint256 length = userBio[_owner].showCaseAmount;
    NFTStruct[] memory scList  = new NFTStruct[](length);
    for(uint256 i = 0; i < length; i++) {
      NFTStruct storage sclist = showCaseList[_owner][i];
      scList[i] = sclist;
    }
    return scList;
  }

  function getShowCaseAmount(address _owner) public view returns (uint256) {
    return userBio[_owner].showCaseAmount;
  }

  function withdraw() external onlyOwner nonReentrant {
    payable(beneficiary).transfer(address(this).balance);
  }

}