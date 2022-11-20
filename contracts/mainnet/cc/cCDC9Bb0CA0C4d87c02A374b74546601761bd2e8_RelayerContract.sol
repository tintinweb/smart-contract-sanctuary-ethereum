//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./structs/ApprovalsStruct.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IProtocolDirectory.sol";

// Errors
error RelayerOnly(); // Only Relayer is authorized to perform this function

/**
 * @title RelayerContract
 *
 * Logic for communicatiing with the relayer and contract state
 *
 */

contract RelayerContract is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @dev address of the relayer account
    address public relayerAddress;

    /// @dev address ProtocolDirectory location
    address public directoryContract;

    /**
     * @notice onlyRelayer
     * modifier to ensure only the relayer account can make changes
     *
     */
    modifier onlyRelayer() {
        if (msg.sender != relayerAddress) {
            revert RelayerOnly();
        }
        _;
    }

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of the directory contract
     *
     */
    function initialize(address _directoryContract) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();

        directoryContract = _directoryContract;
    }

    /**
     * @dev Set Approval Active for a Specific UID
     * @param _uid string identifier of a user on the dApp
     * This function is called by the predetermined relayer account
     * to trigger that a user's will claim period is now active
     *
     */
    function setApprovalActiveForUID(string memory _uid) external onlyRelayer {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_uid);
        IAssetStore(usersAssetStoreAddress).setApprovalActive(_uid);
    }

    /**
     * @dev transferUnclaimedAssets
     * @param _userUID string identifier of a user across the dApp
     * Triggered by the relayer once it is too late for the beneficiaries to claim
     *
     */
    function transferUnclaimedAssets(string memory _userUID)
        external
        onlyRelayer
    {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_userUID);

        IAssetStore(usersAssetStoreAddress).transferUnclaimedAssets(_userUID);
    }

    /**
     * @dev setRelayerAddress
     * @param _relayerAddress the new address of the relayerAccount
     * Update the relayerAccount by the owner as needed
     *
     */
    function setRelayerAddress(address _relayerAddress) external onlyOwner {
        relayerAddress = _relayerAddress;
    }

    /**
     * @dev triggerAssetsForCharity
     * since charities cannot claim assets, the relayer will
     * call this function which will allocate assets per the user's
     * will
     * @param _userUID of the user on the dApp
     *
     */
    function triggerAssetsForCharity(string memory _userUID)
        external
        onlyRelayer
    {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_userUID);

        Approvals[] memory userApprovals = IAssetStore(usersAssetStoreAddress)
            .getApprovals(_userUID);

        for (uint256 i = 0; i < userApprovals.length; i++) {
            if (userApprovals[i].beneficiary.isCharity) {
                IAssetStore(usersAssetStoreAddress).sendAssetsToCharity(
                    userApprovals[i].beneficiary.beneficiaryAddress,
                    _userUID
                );
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/MembershipPlansStruct.sol";

/**
 * @title IMembershipFactory
 * @dev Interface to interact with Membership Factory
 *
 */
interface IAssetStoreFactory {
    /**
     * @dev Function to deployAssetStore for each user
     * @param _uid string identifier of the user across the dApp
     * @param _user address of the user deploying the AssetStore
     *
     */
    function deployAssetStore(string memory _uid, address _user) external;

    /**
     * @dev Function to return assetStore Address of a specific user
     * @param _uid string identifier for the user across the dApp
     * @return address of the AssetStore for given user
     *
     */
    function getAssetStoreAddress(string memory _uid)
        external
        view
        returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/ApprovalsStruct.sol";

/**
 *  @title IAssetStore
 *  @dev Interface for IAssetStore to interact with AssetStore Contracts
 *
 */
interface IAssetStore {
    /**
     * @notice storeAssetsApprovals - Function to store All Types Approvals by the user
     * @dev All of the arrays passed in need to be IN ORDER
     * they will be accessed in a loop together
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _memberUID string of the dApp identifier for the user
     *
     */
    function storeAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] memory _tokenIds,
        address[] calldata _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        uint256[] memory _tokenAmount,
        string[] memory _tokenTypes,
        string memory _memberUID
    ) external;

    /**
     * @notice getApproval - Function to get a specific token Approval for the user passing in UID and ApprovalID
     * @dev searches state for a match by uid and approvalId for a given user
     *
     * @param uid string of the dApp identifier for the user
     * @param approvalId number of the individual approval to lookup
     *
     * @return approval_ struct storing information for an Approval
     */
    function getApproval(string memory uid, uint256 approvalId)
        external
        view
        returns (Approvals memory approval_);

    /**
     * @notice getBeneficiaryApproval - Function to get a token Approval for the beneficiaries - Admin function
     * @param _benAddress address to lookup a specific list of approvals for given beneficiary address
     * @return approval_ a list of approval structs for a specific address
     */
    function getBeneficiaryApproval(address _benAddress)
        external
        view
        returns (Approvals[] memory approval_);

    /**
     * @notice getApprovals - Function to get all token Approvals for the user
     * @param uid string of the dApp identifier for the user
     * @return Approvals[] a list of all the approval structs associated with a user
     */
    function getApprovals(string memory uid)
        external
        view
        returns (Approvals[] memory);

    /**
     *  @notice setApprovalActive called by external actor to mark claiming period
     *  is active and ready
     *  @param uid string of the dApp identifier for the user
     *
     */
    function setApprovalActive(string memory uid) external;

    /**
     * @dev claimAsset - Function to claim Asset from a specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId_ uint256 id of the specific approval being claimed
     *
     */
    function claimAsset(string memory uid, uint256 approvalId_) external;

    /**
     * @dev getClaimableAssets allows users to get all claimable assets for a specific user.
     * @return return a list of assets being protected by this contract
     */
    function getClaimableAssets() external view returns (Token[] memory);

    /**
     * @dev deleteApprooval - Deletes the approval of the specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 id of the approval struct to be deleted
     *
     */
    function deleteApproval(string memory uid, uint256 approvalId) external;

    /**
     * @dev editApproval - Edits the token information of the approval
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 ID of the approval struct to modify
     * @param _contractAddress address being set for the approval
     * @param _tokenId uint256 tokenId being set of the approval
     * @param _tokenAmount uint256 amount of tokens in the approval
     * @param _tokenType string (ERC20 | ERC1155 | ERC721)
     *
     */
    function editApproval(
        string memory uid,
        uint256 approvalId,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        string memory _tokenType
    ) external;

    /**
     * @notice Function to store All Types of Approvals and Backups by the user in one function
     * @dev storeAssetsAndBackUpApprovals calls
     *  storeBackupAssetsApprovals & storeAssetsApprovals
     * 
     * sent to storeAssetsApprovals:
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     
     * sent to storeBackupAssetsApprovals:
     * @param _backUpTokenIds uint256[] Ordered list of tokenIds to be in a backup plan
     * @param _backupTokenAmount uint256[] Ordered list representing a magnitube of tokens to be in a backupPlan
     * @param _backUpWallets address[] Ordered list of destination wallets for the backupPlan
     * @param _backUpAddresses address[] Ordered list of contract addresses of assets for the backupPlan
     * @param _backupTokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param uid string of the dApp identifier for the user
     * 
     * 
     */
    function storeAssetsAndBackUpApprovals(
        address[] calldata _contractAddress,
        address[] calldata _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        string[] memory _tokenTypes,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenAmount,
        uint256[] memory _backUpTokenIds,
        uint256[] memory _backupTokenAmount,
        address[] calldata _backUpWallets,
        address[] calldata _backUpAddresses,
        string[] memory _backupTokenTypes,
        string memory uid
    ) external;

    /**
     * @notice transferUnclaimedAsset - Function to claim Unclaimed Assets passed the claimable expiry time
     * @param uid string of the dApp identifier for the user
     */
    function transferUnclaimedAssets(string memory uid) external;

    /**
     * @dev sendAssetsToCharity
     * @param _charityBeneficiaryAddress address of the charity beneficiary
     * @param _uid the uid stored for the user
     *
     * Send assets to the charity beneficiary if they exist;
     *
     */
    function sendAssetsToCharity(
        address _charityBeneficiaryAddress,
        string memory _uid
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/MemberStruct.sol";
import "../structs/BackupApprovalStruct.sol";

/**
 * @title Interface for IMember
 * @dev to interact with Member Contracts
 *
 */
interface IMember {
    /**
     * @dev createMember
     * @param  uid centrally stored id for user
     * @param _walletAddress walletAddress to add wallet and check blacklist
     *
     * Allows to create a member onChain with a unique UID passed.
     * Will revert if the _walletAddress passed in is blacklisted
     *
     */
    function createMember(string calldata uid, address _walletAddress) external;

    /**
     * @dev getMember
     * @param uid string for centrally located identifier
     * Allows to get member information stored onChain with a unique UID passed.
     * @return member struct for a given uid
     *
     */
    function getMember(string memory uid) external view returns (member memory);

    /**
     * @dev getAllMembers
     * Allows to get all member information stored onChain
     * @return allMembers a list of member structs
     *
     */
    function getAllMembers() external view returns (member[] memory);

    /**
     * @dev addWallet - Allows to add Wallet to the user
     * @param uid string for dApp user identifier
     * @param _wallet address wallet being added for given user
     * @param _primary bool whether or not this new wallet is the primary wallet
     *
     *
     */
    function addWallet(
        string calldata uid,
        address _wallet,
        bool _primary
    ) external;

    /**
     * @dev getWallets
     * Allows to get all wallets of the user
     * @param uid string for dApp user identifier
     * @return address[] list of wallets
     *
     */
    function getWallets(string calldata uid)
        external
        view
        returns (address[] memory);

    /**
     * @dev deleteWallet - Allows to delete  wallets of a specific user
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function deleteWallet(string calldata uid, uint256 _walletIndex) external;

    /**
     * @dev getPrimaryWallets
     * Allows to get primary wallet of the user
     * @param uid string for dApp user identifier
     * @return address of the primary wallet per user
     *
     */
    function getPrimaryWallet(string memory uid)
        external
        view
        returns (address);

    /**
     * @dev setPrimaryWallet
     * Allows to set a specific wallet as the primary wallet
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function setPrimaryWallet(string calldata uid, uint256 _walletIndex)
        external;

    /**
     * @notice Function to check if wallet exists in the UID
     * @param _uid string of dApp identifier for a user
     * @param _user address of the user checking exists
     * Fails if not owner uid and user address do not return a wallet
     *
     */
    function checkUIDofSender(string memory _uid, address _user) external view;

    /**
     * @dev checkIfUIDExists
     * Check if user exists for specific wallet address already internal function
     * @param _walletAddress wallet address of the user
     * @return _exists - A boolean if user exists or not
     *
     */
    function checkIfUIDExists(address _walletAddress)
        external
        view
        returns (bool _exists);

    /**
     * @dev getUID
     * Allows user to pass walletAddress and return UID
     * @param _walletAddress get the UID of the user's if their wallet address is present
     * @return string of the ID used in the dApp to identify they user
     *
     */
    function getUID(address _walletAddress)
        external
        view
        returns (string memory);

    /**
     * @dev getBackupApprovals - function to return all backupapprovals for a specific UID
     * @param uid string of identifier for user in dApp
     * @return BackUpApprovals[] list of BackUpApprovals struct
     *
     */
    function getBackupApprovals(string memory uid)
        external
        view
        returns (BackUpApprovals[] memory);

    /**
     * @dev storeBackupAssetsApprovals - Function to store All Types Approvals by the user for backup
     *
     * @param _contractAddress address[] Ordered list of contract addresses for assets
     * @param _tokenIds uint256[] Ordered list of tokenIds associated with contract addresses
     * @param _backUpWallets address[] Ordered list of wallet addresses to backup assets
     * @param _tokenAmount uint256[] Ordered list of amounts per asset contract and token id to protext
     * @param _tokenTypes string[] Ordered list of strings i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string for dApp user identifier
     *
     */
    function storeBackupAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID
    ) external;

    /**
     * @dev executePanic - Public function to transfer assets from one user to another
     * @param _backUpWallet wallet to panic send assets to
     * @param _memberUID uid of the user's assets being moved
     *
     */
    function executePanic(address _backUpWallet, string memory _memberUID)
        external;

    /**
     * @dev editBackup - Function to edit individual backup approvals
     * @param approvalId_ uint256 id to lookup Approval and edit
     * @param _contractAddress address contractAddress of asset to save
     * @param _tokenIds uint256 tokenId of asset
     * @param _tokenAmount uint256 amount of specific token
     * @param _tokenType string type of the token i.e. ERC20 | ERC721 | ERC1155
     * @param _uid string of identifier for user in dApp
     *
     */
    function editBackUp(
        uint256 approvalId_,
        address _contractAddress,
        uint256 _tokenIds,
        uint256 _tokenAmount,
        string calldata _tokenType,
        string memory _uid
    ) external;

    /**
     * @dev editAllBackUp - Function to delete and add new approvals for backup
     * @param _contractAddress address[] Ordered list of addresses for asset contracts
     * @param _tokenIds uint256[] Ordered list of tokenIds to backup
     * @param _backUpWallets address[] Ordered list of wallets that can be backups
     * @param _tokenAmount uint256[] Ordered list of amounts of tokens to backup
     * @param _tokenTypes string[] Ordered list of string tokenTypes i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string of identifier for user in dApp
     *
     *
     */
    function editAllBackUp(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID
    ) external;

    /**
     * @dev deleteAllBackUp - Function to delete all backup approvals
     * @param _uid string of identifier for user in dApp
     *
     */
    function deleteAllBackUp(string memory _uid) external;

    /**
     * @notice checkUserHasMembership - Function to check if user has membership
     * @param _uid string of identifier for user in dApp
     * @param _user address of the user of the dApp
     *
     */
    function checkUserHasMembership(string memory _uid, address _user)
        external
        view;

    /**
     * @dev Function set MembershipAddress for a Uid
     * @param _uid string of identifier for user in dApp
     * @param _Membership address of the user's associated membership contract
     *
     */
    function setIMembershipAddress(string memory _uid, address _Membership)
        external;

    /**
     * @dev Function to get MembershipAddress for a given Uid
     * @param _uid string of identifier for user in dApp
     *
     */
    function getIMembershipAddress(string memory _uid)
        external
        view
        returns (address);

    /**
     * @notice checkIfWalletHasNFT
     * verify if the user has specific nft 1155 or 721
     * @param _contractAddress address of asset contract
     * @param _NFTType string i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId checking for ownership
     * @param userAddress address address to verify ownership of
     * Fails if not owner
     */
    function checkIfWalletHasNFT(
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        address userAddress
    ) external view;

    /**
     * @dev addBackUpWallet - Allows to add backUp Wallets to the user
     * @param uid string for dApp user identifier
     * @param _wallets addresses of wallets being added for given user
     *
     *
     */
    function addBackupWallet(string calldata uid, address[] memory _wallets)
        external;

    /**
     * @dev getBackupWallets - Returns backup Wallets for the specific UID
     * @param uid string for dApp user identifier
     *
     */
    function getBackupWallets(string calldata uid)
        external
        view
        returns (address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MemberStruct.sol";
import "./TokenStruct.sol";
import "./BeneficiaryStruct.sol";

/**
 * @dev Approvals Struct
 * @param Member member struct with information on the user
 * @param approvedWallet address of wallet approved
 * @param beneficiary Beneficiary struct holding recipient info
 * @param token Token struct holding specific info on the asset
 * @param dateApproved uint256 timestamp of the approval creation
 * @param claimed bool representing status if asset was claimed
 * @param active bool representing if the claim period has begun
 * @param approvalId uint256 id of the specific approval in the assetstore
 * @param claimExpiryTime uint256 timestamp of when claim period ends
 * @param approvedTokenAmount uint256 magnitude of tokens to claim by this approval
 *
 */
struct Approvals {
    Beneficiary beneficiary;
    Token token;
    uint256 dateApproved;
    address approvedWallet;
    bool claimed;
    bool active;
    uint88 approvalId;
    uint256 claimExpiryTime;
    uint256 approvedTokenAmount;
    string _uid;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Protocol Directory interface
 *
 * Use this interface in any contract that needs to find
 * the contract location for commonly used Webacy contracts
 *
 */

interface IProtocolDirectory {
    /**
     * @notice event for recording changes of contracts
     *
     */
    event AddressSet(bytes32 contractName, address indexed newContractAddress);

    /**
     * @notice get the address by a bytes32 location id
     * @param _contractName a bytes32 string
     *
     */
    function getAddress(bytes32 _contractName) external returns (address);

    /**
     * @notice setAddress
     * @param _contractName a bytes32 string
     * @param _contractLocation an address of to entrypoint of protocol contract
     *
     */
    function setAddress(bytes32 _contractName, address _contractLocation)
        external
        returns (address);

    /**
     * @notice ssetStoreFactory
     * @return address of protocol contract matching ASSET_STORE_FACTORY value
     *
     */
    function getAssetStoreFactory() external view returns (address);

    /**
     * @notice getMembershipFactory
     * @return address of protocol contract matching MEMBERSHIP_FACTORY value
     *
     */
    function getMembershipFactory() external view returns (address);

    /**
     * @notice getRelayerContract
     * @return address of protocol contract matching RELAYER_CONTRACT value
     *
     */
    function getRelayerContract() external view returns (address);

    /**
     * @notice getMemberContract
     * @return address of protocol contract matching MEMBER_CONTRACT value
     *
     */
    function getMemberContract() external view returns (address);

    /**
     * @notice getBlacklistContract
     * @return address of protocol contract matching BLACKLIST_CONTRACT value
     *
     */
    function getBlacklistContract() external view returns (address);

    /**
     * @notice getWhitelistContract
     * @return address of protocol contract matching WHITELIST_CONTRACT value
     *
     */
    function getWhitelistContract() external view returns (address);

    /**
     * @notice getTransferPool
     * @return address of protocol contract matching TRANSFER_POOL value
     *
     */
    function getTransferPool() external view returns (address);

    /**
     * @dev setAssetStoreFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setAssetStoreFactory(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setMembershipFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setMembershipFactory(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setRelayerContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setRelayerContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setMemberContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setMemberContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setBlacklistContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setBlacklistContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setWhitelistContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setWhitelistContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setTransferPool
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setTransferPool(address _contractLocation)
        external
        returns (address);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev membershipPlan struct
 *
 * @param membershipDuration uint256 length of time membership is good for
 * @param costOfMembership uint256 cost in wei of gaining membership
 * @param updatesPerYear uint256 how many updates can the membership be updated in a year by user
 * @param nftCollection address pass as null address if it is not for creating specific
 * membership plan for a specific NFT Collection
 * @param membershipId uint256 id for the new membership to lookup by
 * @param active bool status if the membership can be used to create new contracts
 */
struct membershipPlan {
    uint256 membershipDuration;
    uint256 costOfMembership;
    uint40 updatesPerYear;
    uint48 membershipId;
    address nftCollection;
    bool active;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Member Structure stores all member information
 * @param uid string For storing UID that cross references UID from DB for loading off-chain data
 * @param dateCreated uint256 timestamp of creation of User
 * @param wallets address[] Maintains an array of backUpWallets of the User
 * @param primaryWallet uint256 index of where in the wallets array the primary wallet exists
 */
struct member {
    uint256 dateCreated;
    address[] wallets;
    address[] backUpWallets;
    uint256 primaryWallet;
    string uid;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Token struct
 *
 * @param tokenId uint256 specific tokenId for the asset
 * @param tokenAddress address of the contract for this asset
 * @param tokenType string representing asset type i.e. ERC721 | ERC20 | ERC1155
 * @param tokensAllocated uint256 number representing how many tokens as a %'s to
 * attach to a given approval or other directive
 */
struct Token {
    address tokenAddress;
    uint256 tokenId;
    uint256 tokensAllocated;
    string tokenType;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Structure to store different types of Beneficiary
 * (ERC721, ERC1155, ERC20)
 * @param beneficiaryAddress address for assets to go to
 * @param beneficiaryName name of entity recieveing the assets
 * @param isCharity boolean representing if Beneficiary is a charity
 * because charities will be a recieve only address and cannot be
 * expected to call a function to claim assets
 *
 */
struct Beneficiary {
    address beneficiaryAddress;
    bool isCharity;
    string beneficiaryName;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MemberStruct.sol";
import "./TokenStruct.sol";
import "./BeneficiaryStruct.sol";

/**
 * @dev BackUpApprovals struct
 *
 * @param Member member struct of information for the user
 * @param approvedWallet address wallet approving the assets
 * @param backUpWallet address[] wallet approved to recieve assets
 * @param token Token struct with information about the asset backed up
 * @param dateApproved uint256 timestamp of when the approval came in
 * @param claimed bool status of the approval if it was claimed
 * @param approvalId uint256 id of the specific approval for this asset
 */
struct BackUpApprovals {
    address[] backUpWallet;
    address approvedWallet;
    bool claimed;
    uint88 approvalId;
    Token token;
    uint256 dateApproved;
    string _uid;
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