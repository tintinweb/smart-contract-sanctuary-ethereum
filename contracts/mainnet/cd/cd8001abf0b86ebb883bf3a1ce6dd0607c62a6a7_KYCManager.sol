/**
 *Submitted for verification at Etherscan.io on 2022-09-17
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/KYCManagerV2.sol


pragma solidity ^0.8.0;


interface KYCNFTInterface {
    function awardItem(address player, string memory tokenURI)
        external
        returns (uint256);

    function updateExpirationTime(uint256 tokenId, uint256 timestamp) external;
}

/*
n, accumulator is bigNumber，(May be out of range of uint256)，so use string as the value type
*/
contract KYCManager is Ownable {
    struct UserData {
        uint256 NFTId;
        bytes32 merkleRoot;
    }

    KYCNFTInterface kycNFTContract;

    mapping(uint256 => address) private NFTIdToManager;
    mapping(address => UserData) private ManagerToUserData;
    mapping(uint256 => bool) private NFTIdToAvailable;

    //set this first!
    function setKYCNFTContractAddress(address _kycnftContractAddr)
        public
        onlyOwner
    {
        kycNFTContract = KYCNFTInterface(_kycnftContractAddr);
    }

    function createKYCNFT(
        string memory tokenUrl,
        address manager,
        uint256 expirationTime
    ) external onlyOwner {
        //owner of NFT is KYCManager Contract
        address kycnftmanager = (address)(this);
        uint256 NFTId = kycNFTContract.awardItem(kycnftmanager, tokenUrl);
        kycNFTContract.updateExpirationTime(NFTId, expirationTime);
        setAvailableOfNFTId(NFTId, true);
        initManagerAddr(NFTId, manager);
    }

    function setAvailableOfNFTId(uint256 NFTId, bool _available)
        public
        onlyOwner
    {
        NFTIdToAvailable[NFTId] = _available;
    }

    /*
    NFTIdToManager
   */
    function initManagerAddr(uint256 NFTId, address manager) public onlyOwner {
        NFTIdToManager[NFTId] = manager;
        ManagerToUserData[manager].NFTId = NFTId;
    }

    function modifyManagerAddr(address newManager) public {
        UserData memory userdata = ManagerToUserData[msg.sender];
        ManagerToUserData[newManager] = userdata;
        NFTIdToManager[userdata.NFTId] = newManager;
    }

    /*
    ManagerToUserData
  */
    function updateMerkleRoot(bytes32 newMerkleRoot) public {
        UserData storage userdata = ManagerToUserData[msg.sender];
        userdata.merkleRoot = newMerkleRoot;
    }

    /*
    Query Data
  */

    function managerOfNFTId(uint256 NFTId) public view returns (address) {
        address addr = NFTIdToManager[NFTId];
        return addr;
    }

    function userDataOfNFTId(uint256 NFTId)
        public
        view
        returns (UserData memory)
    {
        address addr = NFTIdToManager[NFTId];
        UserData memory userdata = ManagerToUserData[addr];
        return userdata;
    }

    function userDataOfManager(address managerAddr)
        public
        view
        returns (UserData memory)
    {
        UserData memory userdata = ManagerToUserData[managerAddr];
        return userdata;
    }

    function availableOfNFTId(uint256 NFTId) public view returns (bool) {
        return NFTIdToAvailable[NFTId];
    }

    function NFTIdOfManager(address managerAddr) public view returns (uint256) {
        UserData memory userdata = ManagerToUserData[managerAddr];
        return userdata.NFTId;
    }

    /*
  verify merkle proof
  */
    function verifyMerkleProof(
        bytes32 root,
        bytes32 leaf,
        bytes32[] calldata proof,
        uint256[] calldata positions
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (positions[i] == 1) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        return computedHash == root;
    }

    function verifyKYCAuthProof(
        bytes32 leaf,
        bytes32[] calldata proof,
        uint256[] calldata positions,
        uint256 NFTId
    )public view returns (bool) {
        address addr = NFTIdToManager[NFTId];
        UserData memory userdata = ManagerToUserData[addr];
        bool result = verifyMerkleProof(userdata.merkleRoot, leaf, proof, positions);
        return result;
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}