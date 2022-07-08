/**
 *Submitted for verification at Etherscan.io on 2022-07-08
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

// File: mirageminter.sol

/*
         M                                                 M
       M   M                                             M   M
      M  M  M                                           M  M  M
     M  M  M  M                                       M  M  M  M
    M  M  M  M  M                                    M  M  M  M  M
   M  M M  M  M  M                                 M  M  M  M  M  M
   M  M   M  M  M  M                              M  M     M  M  M  M
   M  M     M  M  M  M                           M  M      M  M   M  M
   M  M       M  M  M  M                        M  M       M  M   M  M       
   M  M         M  M  M  M                     M  M        M  M   M  M
   M  M           M  M  M  M                  M  M         M  M   M  M
   M  M             M  M  M  M               M  M          M  M   M  M   M  M  M  M  M  M  M
   M  M               M  M  M  M            M  M        M  M  M   M  M   M  M  M  M  M  M  M
   M  M                 M  M  M  M         M  M      M  M  M  M   M  M                  M  M
   M  M                   M  M  M  M      M  M    M  M  M  M  M   M  M                     M
   M  M                     M  M  M  M   M  M  M  M  M  M  M  M   M  M
   M  M                       M  M  M  M  M   M  M  M  M   M  M   M  M
   M  M                         M  M  M  M   M  M  M  M    M  M   M  M
   M  M                           M  M  M   M  M  M  M     M  M   M  M
   M  M                             M  M   M  M  M  M      M  M   M  M
M  M  M  M  M  M                         M   M  M  M  M   M  M  M  M  M  M  M  
                                          M  M  M  M
                                          M  M  M  M
                                          M  M  M  M
                                           M  M  M  M                        M  M  M  M  M  M
                                            M  M  M  M                          M  M  M  M
                                             M  M  M  M                         M  M  M  M
                                               M  M  M  M                       M  M  M  M
                                                 M  M  M  M                     M  M  M  M
                                                   M  M  M  M                   M  M  M  M
                                                      M  M  M  M                M  M  M  M
                                                         M  M  M  M             M  M  M  M
                                                             M  M  M  M   M  M  M  M  M  M
                                                                 M  M  M  M  M  M  M  M  M
                                                                                                                                                    
*/

// Contract authored by August Rosedale (@augustfr)
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

interface mirageContracts {
    function balanceOf(address owner, uint256 _id) external view returns (uint256);
}

contract curatedMinterV2 is Ownable {

    curatedContract public mirageContract;
    mirageContracts public membershipContract;

    uint256 public maxPubMint = 10;
    uint256 public maxPreMint = 3;

    mapping(uint256 => bool) public excluded;

    constructor(address _mirageAddress, address _membershipAddress) {
        mirageContract = curatedContract(_mirageAddress);
        membershipContract = mirageContracts(_membershipAddress);
    }
    
    function purchase(uint256 _projectId, uint256 numberOfTokens) public payable {
        require(!excluded[_projectId], "Project cannot be minted through this contract");
        require(numberOfTokens <= maxPubMint, "Can only mint 10 per transaction");
        require(msg.value >= mirageContract.projectIdToPricePerTokenInWei(_projectId) * numberOfTokens, "Must send minimum value to mint!");
        _splitFundsETH(_projectId, numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++) {
            mirageContract.mint(msg.sender, _projectId, msg.sender);  
        }
    }

    function earlyPurchase(uint256 _projectId, uint256 _membershipId, uint256 numberOfTokens) public payable {
        require(!excluded[_projectId], "Project cannot be minted through this contract");
        require(membershipContract.balanceOf(msg.sender,_membershipId) > 0, "No membership tokens in this wallet");
        require(numberOfTokens <= maxPreMint, "Can only mint 3 per transaction for presale minting");
        require(msg.value>=mirageContract.projectIdToPricePerTokenInWei(_projectId) * numberOfTokens, "Must send minimum value to mint!");
        _splitFundsETH(_projectId, numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++) {
            mirageContract.earlyMint(msg.sender, _projectId, msg.sender);
        }
    }

    function toggleProject(uint256 _projectId) public onlyOwner {
        excluded[_projectId] = !excluded[_projectId];
    }

    function updateMintLimits(uint256 _preMint, uint256 _pubMint) public onlyOwner { 
        maxPubMint = _pubMint;
        maxPreMint = _preMint;
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