/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// File: IDelegationRegistry.sol


pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 *      from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
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

// File: curatedMinterV3.sol

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNOOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXO0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMk,'lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNo...cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc...lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMK:....cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc....:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMk,.....cKMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.....,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNd.......cKWMMMMMMMMMMMMMMMMMMMMMMMKkc.......oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMKc........cKMMMMMMMMMMMMMMMMMMMMMMKc'........cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMO,.........cKMMMMMMMMMMMMMMMMMMMMKc..........,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWd'..........cKWMMMMMMMMMMMMMMMMMKl............dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMXc...;;.......cKMMMMMMMMMMMMMMMMKc...'co,......cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMO;..,x0:.......cKMMMMMMMMMMMMMMKl...cxKKc......;OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWd'..;0W0:.......cKWMMMMMMMMMMMKc...cKWMNo......'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMXl...lXMW0:.......c0WMMMMMMMMMKl...cKMMMWx'......lXXkxxddddoddddxxxkO0KXXNWWWMMMMMMMMMMM
MMMMMMMMMMMM0;...dWMMW0:.......c0WMMMMMMMKl...cKMMMMMO;......;0k,.'''',,''.......'',;::cxXMMMMMMMMMM
MMMMMMMMMMMWx'..,kMMMMW0:.......c0WMMMMMKl...cKMMMMWWKc......'xXOO00KKKKK00Okdoc,'......cKMMMMMMMMMM
MMMMMMMMMMMXl...:0MMMMMW0:.......:0WMMMKl...cKMMWKkdxKd.......oNMMMMMMMMMMMMMMMWXOd:'...lXMMMMMMMMMM
MMMMMMMMMMM0:...lXMMMMMMWO:.......:0MMKl...cKMWKo,..;0k,......:KMMMMMMMMMMMMMMMMMMWNOc'.oNMMMMMMMMMM
MMMMMMMMMMWx'..'dWMMMMMMMW0:.......:0Kl...cKMNk;....,k0:......,kMMMMMMMMMMMMMMMMMMMMMXl'oNMMMMMMMMMM
MMMMMMMMMMNl...,OMMMMMMMMMW0:.......;;...cKWXo'......dKl.......oNMMMMMMMMMMMMMMMMMMMMM0:dWMMMMMMMMMM
MMMMMMMMMM0:...:KMMMMMMMMMMW0c..........lKMNo'.......oXd'......cKMMMMMMMMMMMMMMMMMMMMMNKXMMMMMMMMMMM
MMMMMMMMMWk,...lXMMMMMMMMMMMWKc........cKMWx,.......,kWk,......,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMNo...'dWMMMMMMMMMMMMMKl......lKMMK:........:KMK:.......dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMWO;...'xWMMMMMMMMMMMMMMXl'...lKMMWx'........lXMXl.......;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMNKOOd;.....;dkO0NMMMMMMMMMMMXo''lXMMMNo.........lNW0:........,lxkO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMN0kkkkkkkkkkxxkOXWMMMMMMMMMMMN0ONMMMMNo.........lXWXOkkkkxxxxxxxxxk0WMXOkkkkkkkkkkkkkkkkkOXMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.........:0MMMMMMMMMMMMMMMMMMMMN0OOxl,........,lxO0NMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'........'xWMMMMMMMMMMMMMMMMMMMMMMMMNd'......'dNMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:.........:KMMMMMMMMMMMMMMMMMMMMMMMMMk,......'xWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd'.........oXMMMMMMMMMMMMMMMMMMMMMMMMO,......'kWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.........'oXMMMMMMMMMMMMMMMMMMMMMMMO,......'kMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo'.........c0WMMMMMMMMMMMMMMMMMMMMMO,......'kMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.........,dXWMMMMMMMMMMMMMMMMMMMO,......'kMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo;'........;d0NMMMMMMMMMMMMMMMMMO,......'kWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxc'.......':dOKNWMMMMMMMMMMMWk,......'kWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xl;'.......,:ldxkO00KK00Od:.......;OMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdl:;''.......''''''....',;cox0NMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OkxxddddddddxxkkO0XNWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

// Contract authored by August Rosedale (@augustfr)
// https://miragegallery.ai
 
pragma solidity ^0.8.19;




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

contract curatedMinterV3 is Ownable {

    curatedContract public mirageContract;
    address private curatedAddress;
    membershipContracts public membershipContract;
    address private membershipAddress;
    IDelegationRegistry public immutable registry;

    mapping(uint256 => uint256) public maxPubMint; // per transaction per drop
    uint256 public maxPreMint = 1; //per intelligent membership
    uint256 public maxPreMintSentient = 1; //per sentient membership
    uint256 public maxSecondPhase = 1; //per transaction
    uint256 public curatedHolderReq = 5;

    mapping(uint256 => bool) public excluded;
    mapping(uint256 => mapping(uint256 => uint256)) public tokensMinted;

    mapping(uint256 => bool) public secondPresalePhase;

    struct intelAllotment {
        uint256 allotment;
    }

    mapping(uint256 => bool) public usingCoupons;

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    mapping(address => mapping(uint256 => intelAllotment)) public intelQuantity; // when using coupons, allotments are only needed to be set for members with more than 1 intel membership. When not using coupons, allotments are set for how many mints each address gets

    address private immutable adminSigner;

    constructor(address _curatedAddress, address _membershipAddress, address _registry, address _adminSigner) {
        mirageContract = curatedContract(_curatedAddress);
        membershipContract = membershipContracts(_membershipAddress);
        curatedAddress = _curatedAddress;
        membershipAddress = _membershipAddress;
        registry = IDelegationRegistry(_registry);
        adminSigner = _adminSigner;
        for (uint256 i = 0; i < 100; i++) {
            maxPubMint[i] = 10;
        }
    }

    function setLimits(uint256 _projectId, uint256 pubLimit, uint256 preLimit, uint256 preSentient) public onlyOwner {
        maxPubMint[_projectId] = pubLimit;
        maxPreMint = preLimit;
        maxPreMintSentient = preSentient;
    }

    function enableSecondPresalePhase(uint256 _projectId) public onlyOwner {
        secondPresalePhase[_projectId] = true;
    }

    function updateHolderReq(uint256 newLimit) public onlyOwner {
        curatedHolderReq = newLimit;
    }

    function updateContracts(address _curatedAddress, address _membershipAddress) public onlyOwner {
        mirageContract = curatedContract(_curatedAddress);
        membershipContract = membershipContracts(_membershipAddress);
    }

    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer == adminSigner;
    }

    function setIntelAllotment(uint256 _projectID, address[] memory _addresses, uint256[] memory allotments) public onlyOwner {
        for(uint i = 0; i < _addresses.length; i++) {
            intelQuantity[_addresses[i]][_projectID].allotment = allotments[i];
        }
    }

    function viewAllotment(address _address, uint256 _projectID) public view returns (uint256) {
        if (intelQuantity[_address][_projectID].allotment == 99) {
            return 0;
        } else {
            return intelQuantity[_address][_projectID].allotment;
        }
    }
    
    function purchase(uint256 _projectId, uint256 numberOfTokens) public payable {
        require(!excluded[_projectId], "Project cannot be minted through this contract");
        require(numberOfTokens <= maxPubMint[_projectId], "Can't mint this many in a single transaction");
        require(msg.value >= mirageContract.projectIdToPricePerTokenInWei(_projectId) * numberOfTokens, "Must send minimum value to mint!");
        require(msg.sender == tx.origin, "Reverting, Method can only be called directly by user.");

        _splitFundsETH(_projectId, numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++) {
            mirageContract.mint(msg.sender, _projectId, msg.sender);
        }
    }

    function earlySentientPurchase(uint256 _projectId, uint256 _membershipId, uint256 numberOfTokens, address _vault) public payable {
        require(!excluded[_projectId], "Project cannot be minted through this contract");
        require(_membershipId < 50, "Not a valid sentient ID");
        require(msg.value >= mirageContract.projectIdToPricePerTokenInWei(_projectId) * numberOfTokens, "Must send minimum value to mint!");
        require(msg.sender == tx.origin, "Reverting, Method can only be called directly by user.");

        address requester = msg.sender;
  
        if (_vault != msg.sender) { 
            bool isDelegateValid = registry.checkDelegateForContract(requester, _vault, membershipAddress);
            require(isDelegateValid, "invalid delegate-vault pairing");
            require(membershipContract.balanceOf(_vault,_membershipId) > 0, "No membership tokens in this wallet");
            requester = _vault;
        } else {
            require(membershipContract.balanceOf(requester,_membershipId) > 0, "No membership tokens in this wallet");
        }

        if (secondPresalePhase[_projectId]) {
            require(numberOfTokens <= maxSecondPhase, "Can't mint this many in one transaction");
        } else {
            require(tokensMinted[_projectId][_membershipId] + numberOfTokens <= maxPreMintSentient, "Would exceed mint allotment");
        }

        _splitFundsETH(_projectId, numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++) {
            tokensMinted[_projectId][_membershipId]++;
            mirageContract.earlyMint(requester, _projectId, msg.sender);
        }
    }

    function earlyCuratedHolderPurchase(uint256 _projectId, uint256 numberOfTokens, address _vault) public payable {
        require(!excluded[_projectId], "Project cannot be minted through this contract");
        require(secondPresalePhase[_projectId], "Not in second presale phase");
        require(mirageContract.balanceOf(_vault) >= curatedHolderReq, "Address does not hold enough curated artworks");
        require(msg.value >= mirageContract.projectIdToPricePerTokenInWei(_projectId) * numberOfTokens, "Must send minimum value to mint!");
        require(msg.sender == tx.origin, "Reverting, Method can only be called directly by user.");
        require(numberOfTokens <= maxSecondPhase, "Can't mint this many in one transaction");
        
        address requester = msg.sender;

        if (_vault != msg.sender) { 
            bool isDelegateValid = registry.checkDelegateForContract(requester, _vault, curatedAddress);
            require(isDelegateValid, "invalid delegate-vault pairing");
            requester = _vault;
        }

        _splitFundsETH(_projectId, numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++) {
            mirageContract.earlyMint(requester, _projectId, msg.sender);
        }
    }

    function enableCoupons(uint256 _projectId) public onlyOwner {
        usingCoupons[_projectId] = !usingCoupons[_projectId];
    }

    function earlyIntelligentPurchase(uint256 _projectId, uint256 numberOfTokens, address _vault) public payable {
        require(!excluded[_projectId], "Project cannot be minted through this contract");
        require(!usingCoupons[_projectId], "Not a valid minting function for this drop");
        require(msg.value >= mirageContract.projectIdToPricePerTokenInWei(_projectId) * numberOfTokens, "Must send minimum value to mint!");
        require(msg.sender == tx.origin, "Reverting, Method can only be called directly by user.");

        address requester = msg.sender;
    
        if (_vault != msg.sender) { 
            bool isDelegateValid = registry.checkDelegateForContract(requester, _vault, membershipAddress);
            require(isDelegateValid, "invalid delegate-vault pairing");
            requester = _vault;
        }

        uint256 allot = intelQuantity[requester][_projectId].allotment;
        require(allot > 0, "No available mints for this address");
        
        if (secondPresalePhase[_projectId]) {
            require(numberOfTokens <= maxSecondPhase, "Can't mint this many in one transaction");
        } else {
            require(numberOfTokens <= allot, "Would exceed mint allotment");
            require(allot != 99, "Already minted total allotment");
            uint256 updatedAllot = allot - numberOfTokens;
            intelQuantity[requester][_projectId].allotment = updatedAllot;
            if (updatedAllot == 0) {
                intelQuantity[requester][_projectId].allotment = 99;
            }
        }
        _splitFundsETH(_projectId, numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++) {
            mirageContract.earlyMint(requester, _projectId, msg.sender);
        }
    }

    function earlyIntelligentCouponPurchase(uint256 _projectId, Coupon memory coupon, address _vault, uint256 numberOfTokens) public payable {
        require(!excluded[_projectId], "Project cannot be minted through this contract");
        require(usingCoupons[_projectId], "Not a valid minting function for this drop");
        require(msg.value >= mirageContract.projectIdToPricePerTokenInWei(_projectId), "Must send minimum value to mint!");
        require(msg.sender == tx.origin, "Reverting, Method can only be called directly by user.");

        address requester = msg.sender;

        if (_vault != msg.sender) { 
            bool isDelegateValid = registry.checkDelegateForContract(requester, _vault, membershipAddress);
            require(isDelegateValid, "invalid delegate-vault pairing");
            requester = _vault;
        }

        bytes32 digest = keccak256(abi.encode(requester,"member"));
        require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");
    
        if (secondPresalePhase[_projectId]) {
            require(numberOfTokens <= maxSecondPhase, "Can't mint this many in one transaction");
        } else {
            uint256 allot = intelQuantity[msg.sender][_projectId].allotment;
            if (allot > 0) {
                require(numberOfTokens <= allot, "Would exceed mint allotment");
                require(allot != 99, "Already minted total allotment");
                uint256 updatedAllot = allot - numberOfTokens;
                intelQuantity[msg.sender][_projectId].allotment = updatedAllot;
                if (updatedAllot == 0) {
                    intelQuantity[msg.sender][_projectId].allotment = 99;
                }
            } else if (allot == 0) {
                require(numberOfTokens <= 1, "Would exceed mint allotment");
                intelQuantity[msg.sender][_projectId].allotment = 99;
            }
        }
        _splitFundsETH(_projectId, numberOfTokens);
        for(uint i = 0; i < numberOfTokens; i++) {
            mirageContract.earlyMint(requester, _projectId, msg.sender);
        }
    }

    function toggleProject(uint256 _projectId) public onlyOwner {
        excluded[_projectId] = !excluded[_projectId];
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