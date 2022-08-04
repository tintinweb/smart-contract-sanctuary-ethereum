/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

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

// File: mirage_minter_2.sol

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++WWWWWWWWWWWW+++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++WWWWWWWWWWWW+++++++++++++++++++++++++++++
+++++++++++++++++++##++++++++++++++++##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++WWWWWW  WWWWWWWW+++++++++++++++++++++++++++
+++++++++++++++++++##++++++++++++++++##+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++WWWWWW  WWWWWWWW+++++++++++++++++++++++++++
+++++++++++++++++++###++++++++++++++###+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++WWWWWWWWWW  WWWWWWWW+++++++++++++++++++++++++
+++++++++++++++++++###++++++++++++++###+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++WWWWWWWWWW  WWWWWWWW+++++++++++++++++++++++++
+++++++++++++++++++####++++++++++++####+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++WWWWWWWWWWWWWWWWWWWW+++++++++++++++++++++++++
++++++++++++++++++#####++++++++++++####+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++WWWWWWWWWWWWWWWWWWWW+++++++++++++++++++++++++
++++++++++++++++++######++++++++++#####*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++....................+++++++++++++++++++++++++
++++++++++++++++++######++++++++++######++++++++++++++++++++++++++++++++++++++++++++++++++++++++++....................+++++++++++++++++++++++++
++++++++++++++++++#######++++++++#######++++++++++++++++++++++++++++++++++++++++++++++++++++++++......::::......::::....+++++++++++++++++++++++
++++++++++++++++++##+####++++++++##+####++++++++++++++++++++++++++++++++++++++++++++++++++++++++......::::......::::....+++++++++++++++++++++++
++++++++++++++++++##+#####++++++###+####++++++++++++++++++++++++++++++++++++++++++++++++++++++++....::****::..::****....+++++++++++++++++++++++
+++++++++++++++++*##++####++++++##++####+########*++++++++++++++++++++++++++++++++++++++++++++++....::****::..::****....+++++++++++++++++++++++
+++++++++++++++++###++#####++++###+++###+############++++++++++++++++WW++WW+++++++++++++++++++....::::WW::::::::WW::......+++++++++++++++++++++
+++++++++++++++++###+++####++++##++++####++++++++####++++++++++++++++WW+#W++++++++++++++++++++....::::WW::::::::WW::......+++++++++++++++++++++
+++++++++++++++++##++++#####++###++#+####++++++++++##+++++++++++++++++WWWW++++++++++++++++++++......::::::::::::::::......+++++++++++++++++++++
+++++++++++++++++##+++++####++##++##+####+++++++++++#+++++++++++++++++*WW+++++++++++++++++++++......::::::::::::::::......+++++++++++++++++++++
+++++++++++++++++##+++++########+###+####+++++++++++#+++++++++++++++++WWW+++++++++++++++++++++......::::::::::::::::......+++++++++++++++++++++
+++++++++++++++++##++++++######++###+####+++++++++++#+++++++++++++++++W*WW++++++++++++++++++++......::::::::::::::::......+++++++++++++++++++++
++++++++++++++++###++++++######+####+####++++++++++++++++++++++++++++WW++W#+++++++++++++++++++......::::::::WW::::::......+++++++++++++++++++++
++++++++++++++++###+++++++####++####+####+++++++++++++++++++++++++++#W+++WW+++++++++++++++++++......::::::::WW::::::......+++++++++++++++++++++
++++++++++++++++###+++++++*###++####++####++++++++++++++++++++++++++++++++++++++++++++++++++++......::::::::::::::::......+++++++++++++++++++++
++++++++++++++++###++++++++##+++####++####++++++++++++++++++++++++++++++++++++++++++++++++++++......::::::::::::::::......+++++++++++++++++++++
++++++++++++++#######++++++++++#####+*#######+++++++++++++++++++++++++++++++++++++++++++++++++++....::::::WWWWWW::::....+++++++++++++++++++++++
+++++++++++++++++++++++++++++++*####++++++++++++#######+++++++++++++++++++++++++++++++++++++++++....::::::WWWWWW::::....+++++++++++++++++++++++
++++++++++++++++++++++++++++++++####+++++++++++++#####++++++++++++++++++++++++++++++++++++++++++......::::::::::::......+++++++++++++++++++++++
++++++++++++++++++++++++++++++++#####++++++++++++####*++++++++++++++++++++++++++++++++++++++++++......::::::::::::......+++++++++++++++++++++++
++++++++++++++++++++++++++++++++#####++++++++++++####*++++++++++++++++++++++++++++++++++++++++++++....::WW::::::WW....+++++++++++++++++++++++++
++++++++++++++++++++++++++++++++#####++++++++++++####+++++++++++++++++++++++++++++++++++++++++++++....::WW::::::WW....+++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++#####+++++++++++####+++++++++++++++++++++++++++++++++++++++++++++++WW::::WWWWWW+++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++#####++++++++++####+++++++++++++++++++++++++++++++++++++++++++++++WW::::WWWWWW+++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++######+++++++++####+++++++++++++++++++++++++++++++++++++++++++++++WW::::::WW+++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++######+++++++####+++++++++++++++++++++++++++++++++++++++++++++++WW::::::WW+++++++++++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++++++########+++#####+++++++++++++++++++++++++++++++++++++++++++++++WW::::::WW+++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++############++++++++++++++++++++++++++++++++++++++++++++++++WW::::::WW+++++++++++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++                                                                                                                                         
*/

// Contract authored by August Rosedale (@augustfr)
// Originally writen for Mirage Gallery Curated drop with Claire Silver (@clairesilver12)
// https://miragegallery.ai

pragma solidity ^0.8.15;


interface curatedContract {
  function projectIdToArtistAddress(uint256 _projectId) external view returns (address payable);
  function projectIdToPricePerTokenInWei(uint256 _projectId) external view returns (uint256);
  function projectIdToAdditionalPayee(uint256 _projectId) external view returns (address payable);
  function projectIdToAdditionalPayeePercentage(uint256 _projectId) external view returns (uint256);
  function mirageAddress() external view returns (address payable);
  function miragePercentage() external view returns (uint256);
  function mint(address _to, uint256 _projectId, address _by) external returns (uint256 tokenId);
  function earlyMint(address _to, uint256 _projectId, address _by) external returns (uint256 _tokenId);
  function balanceOf(address owner) external view returns (uint256);
}

interface membershipContracts {
  function balanceOf(address owner, uint256 _id) external view returns (uint256);
}

contract mirageExclusiveMinter is Ownable {

  curatedContract public mirageContract;
  membershipContracts public membershipContract;

  mapping(uint256 => bool) public includedProjectId;
  mapping(uint256 => bool) public mintedID;
  mapping(address => bool) public mintedWalletStandard;
  mapping(address => bool) public mintedWalletSecondary;
  mapping(address => intelAllotment) intelQuantity;

  address private immutable adminSigner;

  struct intelAllotment {
    uint256 allotment;
  }

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  constructor(address _curatedAddress, address _membershipAddress, address _adminSigner) {
    mirageContract = curatedContract(_curatedAddress);
    membershipContract = membershipContracts(_membershipAddress);
    adminSigner = _adminSigner;
  }

  function purchase(uint256 _projectId) public payable {
    require(includedProjectId[_projectId], "This project cannot be minted through this contract");
    require(msg.value >= mirageContract.projectIdToPricePerTokenInWei(_projectId), "Must send minimum value to mint!");
    require(msg.sender == tx.origin, "Reverting, Method can only be called directly by user.");
    _splitFundsETH(_projectId, 1);
    mirageContract.mint(msg.sender, _projectId, msg.sender);
  }

  function toggleIncludedIds(uint256 _id) public onlyOwner {
    includedProjectId[_id] = !includedProjectId[_id];
  }

  function setIntelAllotment(address[] memory _addresses, uint256[] memory allotments) public onlyOwner {
    for(uint i = 0; i < _addresses.length; i++) {
      intelQuantity[_addresses[i]].allotment = allotments[i];
    }
  }

  function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), "ECDSA: invalid signature");
    return signer == adminSigner;
  }

  function viewAllotment(address _address) public view returns (uint256) {
    if (intelQuantity[_address].allotment == 99) {
      return 0;
    } else {
      return intelQuantity[_address].allotment;
    }
  }

  function sentientPurchase(uint256 _membershipId, uint256 _projectId) public payable {
    require(_membershipId < 50, "Enter a valid Sentient membership ID (0-49)");
    require(includedProjectId[_projectId], "This project cannot be minted through this contract");
    require(membershipContract.balanceOf(msg.sender,_membershipId) > 0, "No membership tokens in this wallet");
    require(msg.value >= mirageContract.projectIdToPricePerTokenInWei(_projectId), "Must send minimum value to mint!");
    require(!mintedID[_membershipId], "Already minted");
    mintedID[_membershipId] = true;
    _splitFundsETH(_projectId, 1);
    mirageContract.earlyMint(msg.sender, _projectId, msg.sender);
  }

  function intelligentPurchase(uint256 _projectId, Coupon memory coupon) public payable {
    require(includedProjectId[_projectId], "This project cannot be minted through this contract");
    require(msg.value >= mirageContract.projectIdToPricePerTokenInWei(_projectId), "Must send minimum value to mint!");
    require(msg.sender == tx.origin, "Reverting, Method can only be called directly by user.");
    uint256 allot = intelQuantity[msg.sender].allotment;
  
    bytes32 digest = keccak256(abi.encode(msg.sender,"member"));
      require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");
  
    if (allot > 0) {
      require(allot != 99, "Already minted total allotment");
      uint256 updatedAllot = allot - 1;
      intelQuantity[msg.sender].allotment = updatedAllot;
      if (updatedAllot == 0) {
        intelQuantity[msg.sender].allotment = 99;
      }
    } else if (allot == 0) {
      intelQuantity[msg.sender].allotment = 99;
    }
    _splitFundsETH(_projectId, 1);
    mirageContract.earlyMint(msg.sender, _projectId, msg.sender);
  }

  function standardPresalePurchase(Coupon memory coupon, uint256 _projectId) public payable {
    require(msg.value >= (mirageContract.projectIdToPricePerTokenInWei(_projectId)), "Must send minimum value to mint!");
    require(includedProjectId[_projectId], "This project cannot be minted through this contract");
    require(!mintedWalletStandard[msg.sender], "Already minted");
    require(msg.sender == tx.origin, "Reverting, Method can only be called directly by user.");
    bytes32 digest = keccak256(abi.encode(msg.sender,"standard"));
      require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");
    _splitFundsETH(_projectId, 1);
    mintedWalletStandard[msg.sender] = true;
    mirageContract.earlyMint(msg.sender, _projectId, msg.sender);
  }

  function secondaryPresalePurchase(Coupon memory coupon, uint256 _projectId) public payable {
    require(msg.value >= (mirageContract.projectIdToPricePerTokenInWei(_projectId)), "Must send minimum value to mint!");
    require(includedProjectId[_projectId], "This project cannot be minted through this contract");
    require(!mintedWalletSecondary[msg.sender], "Already minted");
    require(msg.sender == tx.origin, "Reverting, Method can only be called directly by user.");
    bytes32 digest = keccak256(abi.encode(msg.sender,"secondary"));
      require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");
    _splitFundsETH(_projectId, 1);
    mintedWalletSecondary[msg.sender] = true;
    mirageContract.earlyMint(msg.sender, _projectId, msg.sender);
  }

  function _splitFundsETH(uint256 _projectId, uint256 numberOfTokens) internal {
    if (msg.value > 0) {
      uint256 mintCost = mirageContract.projectIdToPricePerTokenInWei(_projectId) * numberOfTokens;
      uint256 refund = msg.value - (mirageContract.projectIdToPricePerTokenInWei(_projectId) * numberOfTokens);
      if (refund > 0) {
        payable(msg.sender).transfer(refund);
      }
      uint256 mirageAmount = mintCost / 100 * mirageContract.miragePercentage();
      if (mirageAmount > 0) {
        payable(mirageContract.mirageAddress()).transfer(mirageAmount);
      }
      uint256 projectFunds = mintCost - mirageAmount;
      uint256 additionalPayeeAmount;
      if (mirageContract.projectIdToAdditionalPayeePercentage(_projectId) > 0) {
        additionalPayeeAmount = projectFunds / 100 * mirageContract.projectIdToAdditionalPayeePercentage(_projectId);
        if (additionalPayeeAmount > 0) {
          payable(mirageContract.projectIdToAdditionalPayee(_projectId)).transfer(additionalPayeeAmount);
        }
      }
      uint256 creatorFunds = projectFunds - additionalPayeeAmount;
      if (creatorFunds > 0) {
        payable(mirageContract.projectIdToArtistAddress(_projectId)).transfer(creatorFunds);
      }
    }
  }
}