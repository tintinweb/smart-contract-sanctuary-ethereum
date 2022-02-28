/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT

// File: contracts/IAwooClaiming.sol

pragma solidity 0.8.12;

interface IAwooClaiming{
    function overrideTokenAccrualBaseRate(address contractAddress, uint32 tokenId, uint256 newBaseRate) external;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: contracts/IAwooToken.sol

pragma solidity 0.8.12;

interface IAwooToken is IERC20 {
    function increaseVirtualBalance(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
    function balanceOfVirtual(address account) external view returns(uint256);
    function spendVirtualAwoo(bytes32 hash, bytes memory sig, string calldata nonce, address account, uint256 amount) external;
}

// File: contracts/AwooClaiming.sol

pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface ISupportedContract {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function exists(uint256 tokenId) external view returns (bool);
}

struct AccrualDetails{
    address ContractAddress;
    uint256[] TokenIds;
    uint256[] Accruals;
    uint256 TotalAccrued;
}

struct ClaimDetails{
    address ContractAddress;
    uint32[] TokenIds;
}

struct SupportedContractDetails{
    address ContractAddress;
    uint256 BaseRate;
    bool Active;
}

contract AwooClaiming is IAwooClaiming, Ownable, ReentrancyGuard {
    uint256 public accrualStart = 1646006400; //2022-02-28 00:00 UTC
	uint256 public accrualEnd;
	
    bool public claimingActive;

    /// @dev A collection of supported contracts. These are typically ERC-721, with the addition of the tokensOfOwner function.
    /// @dev These contracts can be deactivated but cannot be re-activated.  Reactivating can be done by adding the same
    /// contract through addSupportedContract
    SupportedContractDetails[] public supportedContracts;

    /// @dev Keeps track of the last time a claim was made for each tokenId within the supported contract collection
    mapping(address => mapping(uint256 => uint256)) public lastClaims;
    /// @dev Allows the base accrual rates to be overridden on a per-tokenId level to support things like upgrades
    mapping(address => mapping(uint256 => uint256)) public baseRateTokenOverrides;

    address[2] private _admins;    
    bool private _adminsSet;
    
    IAwooToken private _awooContract;    

    /// @dev Base accrual rates are set a per-day rate so we change them to per-minute to allow for more frequent claiming
    uint64 private _baseRateDivisor = 1440;

    /// @dev Faciliates the maintence and functionality related to supportedContracts
    uint8 private _activeSupportedContractCount;     
    mapping(address => uint8) private _supportedContractIds;
    
    /// @dev Keeps track of which contracts are explicitly allowed to override the base accrual rates
    mapping(address => bool) private _authorizedContracts;

    event TokensClaimed(address indexed claimedBy, uint256 qty);
    event ClaimingStatusChanged(bool newStatus, address changedBy);
    event AuthorizedContractAdded(address contractAddress, address addedBy);
    event AuthorizedContractRemoved(address contractAddress, address removedBy);

    constructor(uint256 accrualStartTimestamp) {
        require(accrualStartTimestamp > 0, "Invalid accrualStartTimestamp");
        accrualStart = accrualStartTimestamp;
    }

    /// @notice Determines the amount of accrued virtual AWOO for the specified address, based on the
    /// base accural rates for each supported contract and how long has elapsed (in minutes) since the
    /// last claim was made for a give supported contract tokenId
    /// @param owner The address of the owner/holder of tokens for a supported contract
    /// @return A collection of accrued virtual AWOO and the tokens it was accrued on for each supported contract, and the total AWOO accrued
    function getTotalAccruals(address owner) public view returns (AccrualDetails[] memory, uint256) {
        // Initialize the array length based on the number of _active_ supported contracts
        AccrualDetails[] memory totalAccruals = new AccrualDetails[](_activeSupportedContractCount);

        uint256 totalAccrued;
        uint8 contractCount; // Helps us keep track of the index to use when setting the values for totalAccruals
        for(uint8 i = 0; i < supportedContracts.length; i++) {
            SupportedContractDetails memory contractDetails = supportedContracts[i];

            if(contractDetails.Active){
                contractCount++;
                
                // Get an array of tokenIds held by the owner for the supported contract
                uint256[] memory tokenIds = ISupportedContract(contractDetails.ContractAddress).tokensOfOwner(owner);
                uint256[] memory accruals = new uint256[](tokenIds.length);
                
                uint256 totalAccruedByContract;

                for (uint16 x = 0; x < tokenIds.length; x++) {
                    uint32 tokenId = uint32(tokenIds[x]);
                    uint256 accrued = getContractTokenAccruals(contractDetails.ContractAddress, contractDetails.BaseRate, tokenId);

                    totalAccruedByContract+=accrued;
                    totalAccrued+=accrued;

                    tokenIds[x] = tokenId;
                    accruals[x] = accrued;
                }

                AccrualDetails memory accrual = AccrualDetails(contractDetails.ContractAddress, tokenIds, accruals, totalAccruedByContract);

                totalAccruals[contractCount-1] = accrual;
            }
        }
        return (totalAccruals, totalAccrued);
    }

    /// @notice Claims all virtual AWOO accrued by the message sender, assuming the sender holds any supported contracts tokenIds
    function claimAll() external nonReentrant {
        require(claimingActive, "Claiming is inactive");
        require(isValidHolder(), "No supported tokens held");

        (AccrualDetails[] memory accruals, uint256 totalAccrued) = getTotalAccruals(_msgSender());
        require(totalAccrued > 0, "No tokens have been accrued");
        
        for(uint8 i = 0; i < accruals.length; i++){
            AccrualDetails memory accrual = accruals[i];

            if(accrual.TotalAccrued > 0){
                for(uint16 x = 0; x < accrual.TokenIds.length;x++){
                    // Update the time that this token was last claimed
                    lastClaims[accrual.ContractAddress][accrual.TokenIds[x]] = block.timestamp;
                }
            }
        }
    
        // A holder's virtual AWOO balance is stored in the $AWOO ERC-20 contract
        _awooContract.increaseVirtualBalance(_msgSender(), totalAccrued);
        emit TokensClaimed(_msgSender(), totalAccrued);
    }

    /// @notice Claims the accrued virtual AWOO from the specified supported contract tokenIds
    /// @param requestedClaims A collection of supported contract addresses and the specific tokenIds to claim from
    function claim(ClaimDetails[] calldata requestedClaims) external nonReentrant {
        require(claimingActive, "Claiming is inactive");
        require(isValidHolder(), "No supported tokens held");

        uint256 totalClaimed;

        for(uint8 i = 0; i < requestedClaims.length; i++){
            ClaimDetails calldata requestedClaim = requestedClaims[i];

            uint8 contractId = _supportedContractIds[requestedClaim.ContractAddress];
            if(contractId == 0) revert("Unsupported contract");

            SupportedContractDetails memory contractDetails = supportedContracts[contractId-1];
            if(!contractDetails.Active) revert("Inactive contract");

            for(uint16 x = 0; x < requestedClaim.TokenIds.length; x++){
                uint32 tokenId = requestedClaim.TokenIds[x];

                address tokenOwner = ISupportedContract(address(contractDetails.ContractAddress)).ownerOf(tokenId);
                if(tokenOwner != _msgSender()) revert("Invalid owner claim attempt");

                uint256 claimableAmount = getContractTokenAccruals(contractDetails.ContractAddress, contractDetails.BaseRate, tokenId);

                if(claimableAmount > 0){
                    totalClaimed+=claimableAmount;

                    // Update the time that this token was last claimed
                    lastClaims[contractDetails.ContractAddress][tokenId] = block.timestamp;
                }
            }
        }

        if(totalClaimed > 0){
            _awooContract.increaseVirtualBalance(_msgSender(), totalClaimed);
            emit TokensClaimed(_msgSender(), totalClaimed);
        }
    }

    /// @dev Calculates the accrued amount of virtual AWOO for the specified supported contract and tokenId
    function getContractTokenAccruals(address contractAddress, uint256 contractBaseRate, uint32 tokenId) private view returns(uint256){
        uint256 lastClaimTime = lastClaims[contractAddress][tokenId];
        uint256 accruedUntil = accrualEnd == 0 || block.timestamp < accrualEnd 
            ? block.timestamp 
            : accrualEnd;
        
        uint256 baseRate = baseRateTokenOverrides[contractAddress][tokenId] > 0 
            ? baseRateTokenOverrides[contractAddress][tokenId] 
            : contractBaseRate;

        if (lastClaimTime > 0){
            return (baseRate*(accruedUntil-lastClaimTime))/60;
        } else {
             return (baseRate*(accruedUntil-accrualStart))/60;
        }
    }

    /// @notice Allows an authorized contract to increase the base accrual rate for particular NFTs
    /// when, for example, upgrades for that NFT were purchased
    /// @param contractAddress The address of the supported contract
    /// @param tokenId The id of the token from the supported contract whose base accrual rate will be updated
    /// @param newBaseRate The new accrual base rate
    function overrideTokenAccrualBaseRate(address contractAddress, uint32 tokenId, uint256 newBaseRate)
        external onlyAuthorizedContract isValidBaseRate(newBaseRate) {
            require(tokenId > 0, "Invalid tokenId");

            uint8 contractId = _supportedContractIds[contractAddress];
            require(contractId > 0, "Unsupported contract");
            require(supportedContracts[contractId-1].Active, "Inactive contract");

            baseRateTokenOverrides[contractAddress][tokenId] = (newBaseRate/_baseRateDivisor);
    }

    /// @notice Allows the owner or an admin to set a reference to the $AWOO ERC-20 contract
    /// @param awooToken An instance of IAwooToken
    function setAwooTokenContract(IAwooToken awooToken) external onlyOwnerOrAdmin {
        _awooContract = awooToken;
    }

    /// @notice Allows the owner or an admin to set the date and time at which virtual AWOO accruing will stop
    /// @notice This will only be used if absolutely necessary and any AWOO that accrued before the end date will still be claimable
    /// @param timestamp The Epoch time at which accrual should end
    function setAccrualEndTimestamp(uint256 timestamp) external onlyOwnerOrAdmin {
        accrualEnd = timestamp;
    }

    /// @notice Allows the owner or an admin to add a contract whose tokens are eligible to accrue virtual AWOO
    /// @param contractAddress The contract address of the collection (typically ERC-721, with the addition of the tokensOfOwner function)
    /// @param baseRate The base accrual rate in wei units
    function addSupportedContract(address contractAddress, uint256 baseRate) external onlyOwnerOrAdmin isValidBaseRate(baseRate) {
        require(isContract(contractAddress), "Invalid contractAddress");
        require(_supportedContractIds[contractAddress] == 0, "Contract already supported");

        supportedContracts.push(SupportedContractDetails(contractAddress, baseRate/_baseRateDivisor, true));
        _supportedContractIds[contractAddress] = uint8(supportedContracts.length);
        _activeSupportedContractCount++;
    }

    /// @notice Allows the owner or an admin to deactivate a supported contract so it no longer accrues virtual AWOO
    /// @param contractAddress The contract address that should be deactivated
    function deactivateSupportedContract(address contractAddress) external onlyOwnerOrAdmin {
        require(_supportedContractIds[contractAddress] > 0, "Unsupported contract");

        supportedContracts[_supportedContractIds[contractAddress]-1].Active = false;
        supportedContracts[_supportedContractIds[contractAddress]-1].BaseRate = 0;
        _supportedContractIds[contractAddress] = 0;
        _activeSupportedContractCount--;
    }

    /// @notice Allows the owner or an admin to authorize another contract to override token accruals on an individual token level
    /// @param contractAddress The authorized contract address
    function addAuthorizedContract(address contractAddress) external onlyOwnerOrAdmin {
        require(isContract(contractAddress), "Invalid contractAddress");
        _authorizedContracts[contractAddress] = true;
        emit AuthorizedContractAdded(contractAddress, _msgSender());
    }

    /// @notice Allows the owner or an admin to remove an authorized contract
    /// @param contractAddress The contract address which should have its authorization revoked
    function removeAuthorizedContract(address contractAddress) external onlyOwnerOrAdmin {
        _authorizedContracts[contractAddress] = false;
        emit AuthorizedContractRemoved(contractAddress, _msgSender());
    }

    /// @notice Allows the owner or an admin to set the base accrual rate for a support contract
    /// @param contractAddress The address of the supported contract
    /// @param baseRate The new base accrual rate in wei units
    function setBaseRate(address contractAddress, uint256 baseRate) external onlyOwnerOrAdmin isValidBaseRate(baseRate) {
        require(_supportedContractIds[contractAddress] > 0, "Unsupported contract");
        supportedContracts[_supportedContractIds[contractAddress]-1].BaseRate = baseRate/_baseRateDivisor;
    }

    /// @notice Allows the owner to specify two addresses allowed to administer this contract
    /// @param adminAddresses A 2 item array of addresses
    function setAdmins(address[2] calldata adminAddresses) external onlyOwner {
        require(adminAddresses[0] != address(0) && adminAddresses[1] != address(0), "Invalid admin address");

        _admins = adminAddresses;
        _adminsSet = true;
    }

    /// @notice Allows the owner or an admin to activate/deactivate claiming ability
    /// @param active The value specifiying whether or not claiming should be allowed
    function setClaimingActive(bool active) external onlyOwnerOrAdmin {
        claimingActive = active;
        emit ClaimingStatusChanged(active, _msgSender());
    }

    /// @dev Derived from @openzeppelin/contracts/utils/Address.sol
    function isContract(address account) private view returns (bool) {
        if(account == address(0)) return false;
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @notice Determines whether or not the caller holds tokens for any of the supported contracts
    function isValidHolder() private view returns(bool) {
        for(uint8 i = 0; i < supportedContracts.length; i++){
            SupportedContractDetails memory contractDetails = supportedContracts[i];
            if(contractDetails.Active){
                if(ISupportedContract(contractDetails.ContractAddress).balanceOf(_msgSender()) > 0) {
                    return true; // No need to continue checking other collections if the holder has any of the supported tokens
                } 
            }
        }
        return false;
    }

    modifier onlyAuthorizedContract() {
        require(_authorizedContracts[_msgSender()], "Sender is not authorized");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            _msgSender() == owner() || (
                _adminsSet && (
                    _msgSender() == _admins[0] || _msgSender() == _admins[1]
                )
            ), "Not an owner or admin");
        _;
    }

    /// @dev To minimize the amount of unit conversion we have to do for comparing $AWOO (ERC-20) to virtual AWOO, we store
    /// virtual AWOO with 18 implied decimal places, so this modifier prevents us from accidentally using the wrong unit
    /// for base rates.  For example, if holders of FangGang NFTs accrue at a rate of 1000 AWOO per fang, pre day, then
    /// the base rate should be 1000000000000000000000
    modifier isValidBaseRate(uint256 baseRate) {
        require(baseRate >= 1 ether, "Base rate must be in wei units");
        _;
    }
}