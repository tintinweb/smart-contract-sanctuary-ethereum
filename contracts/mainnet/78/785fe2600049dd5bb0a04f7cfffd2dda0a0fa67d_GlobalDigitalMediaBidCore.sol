/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// File: SafeBoxInterface.sol



pragma solidity 0.8.16;

abstract contract SafeBoxInterface {
    function VERSION() public pure virtual returns (uint8);

    function typeOfContract() public pure virtual returns (bytes32);

    function singleTransfer(
        address _tokenContract,
        uint256 _tokenId,
        address _to
    ) external virtual;
}

// File: VaultCoreInterface.sol



pragma solidity 0.8.16;

abstract contract VaultCoreInterface {
    function VERSION() public pure virtual returns (uint8);

    function typeOfContract() public pure virtual returns (bytes32);

    function approveToken(uint256 _tokenId, address _tokenContractAddress)
        external
        virtual;
}

// File: RoyaltyRegistryInterface.sol



pragma solidity 0.8.16;

/**
 * Interface to the RoyaltyRegistry responsible for looking payout addresses
 */
abstract contract RoyaltyRegistryInterface {
    function getAddress(address custodial)
        external
        view
        virtual
        returns (address);

    function getMediaCustomPercentage(uint256 mediaId, address tokenAddress)
        external
        view
        virtual
        returns (uint16);

    function getExternalTokenPercentage(uint256 tokenId, address tokenAddress)
        external
        view
        virtual
        returns (uint16, uint16);

    function typeOfContract() public pure virtual returns (string calldata);

    function VERSION() public pure virtual returns (uint8);
}

// File: PaymentsBufferInterface.sol



pragma solidity 0.8.16;

/**
 * Interface to move funds to PaymentsBuffer for owner to claim it later.
 */
abstract contract PaymentsBufferInterface {
    function typeOfContract() public pure virtual returns (bytes32);

    function add(address _to) external payable virtual;

    function withdraw() external payable virtual;
}

// File: DigitalMediaBurnInterfaceV3.sol



pragma solidity 0.8.16;

/**
 * Interface to the DigitalMediaCore responsible for burning tokens
 */
abstract contract DigitalMediaBurnInterfaceV3 {
    struct PayoutInfo {
        address user;
        uint256 amount;
    }

    function burn(uint256 _tokenId) external virtual;

    function burnDigitalMedia(uint256 _digitalMedia) external virtual;

    function getDigitalMediaForSale(uint256 _digitalMediaId)
        external
        view
        virtual
        returns (
            address,
            bool,
            uint16
        );

    function getDigitalMediaRelease(uint256 _tokenId)
        external
        view
        virtual
        returns (uint32, uint256);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        returns (PayoutInfo[] memory);

    function saleInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        returns (PayoutInfo[] memory);
}

// File: DigitalMediaBurnInterfaceV2.sol



pragma solidity 0.8.16;

/**
 * Interface to the DigitalMediaCore responsible for burning tokens
 */
abstract contract DigitalMediaBurnInterfaceV2 {
    function burn(uint256 _tokenId) external virtual;

    function burnToken(uint256 _tokenId) external virtual;

    function burnDigitalMedia(uint256 _digitalMedia) external virtual;

    function getDigitalMedia(uint256 _digitalMediaId)
        external
        view
        virtual
        returns (
            uint256,
            uint32,
            uint32,
            uint256,
            address,
            string calldata
        );

    function getDigitalMediaRelease(uint256 _tokenId)
        external
        view
        virtual
        returns (
            uint256,
            uint32,
            uint256
        );
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: WithdrawFundsControl.sol



pragma solidity 0.8.16;



contract WithdrawFundsControl is Ownable, Pausable {
    // List of approved on withdraw addresses
    mapping(address => uint256) public approvedWithdrawAddresses;
    bool public isInitialWithdrawAddressAdded = false;

    // Full week wait period before an approved withdraw address becomes active
    uint256 public constant withdrawApprovalWaitPeriod = 1 days;

    event WithdrawAddressAdded(address withdrawAddress);
    event WithdrawAddressRemoved(address widthdrawAddress);

    /**
     * Add a new approved on behalf of user address.
     */
    function addApprovedWithdrawAddress(address _withdrawAddress)
        external
        onlyOwner
    {
        approvedWithdrawAddresses[_withdrawAddress] = block.timestamp;
        emit WithdrawAddressAdded(_withdrawAddress);
    }

    /*
     * Add new withdrawAddress for immediate use. This is an internal only Fn that is called
     * only when the contract is deployed.
     */
    function addApprovedWithdrawAddressImmediately(address _withdrawAddress)
        internal
        onlyOwner
    {
        if (_withdrawAddress != address(0)) {
            // set the date to one in past so that address is active immediately.
            approvedWithdrawAddresses[_withdrawAddress] =
                block.timestamp -
                withdrawApprovalWaitPeriod -
                1;
            emit WithdrawAddressAdded(_withdrawAddress);
        }
    }

    /**
     * Removes an approved on bhealf of user address.
     */
    function removeApprovedWithdrawAddress(address _withdrawAddress)
        external
        onlyOwner
    {
        delete approvedWithdrawAddresses[_withdrawAddress];
        emit WithdrawAddressRemoved(_withdrawAddress);
    }

    function addApprovedWithdrawAddressAfterDeploy(address _withdrawAddress)
        external
        onlyOwner
    {
        require(
            isInitialWithdrawAddressAdded == false,
            "Initial withdraw address already added"
        );
        addApprovedWithdrawAddressImmediately(_withdrawAddress);
        isInitialWithdrawAddressAdded = true;
    }

    /**
     * Checks that a given withdraw address ia approved and is past it's required
     * wait time.
     */
    function isApprovedWithdrawAddress(address _withdrawAddress)
        internal
        view
        returns (bool)
    {
        uint256 approvalTime = approvedWithdrawAddresses[_withdrawAddress];
        require(approvalTime > 0, "withdraw address is not registered");
        return block.timestamp - approvalTime > withdrawApprovalWaitPeriod;
    }
}

// File: OBOControl.sol



pragma solidity 0.8.16;


contract OBOControl is Ownable {
    address public oboAdmin;
    uint256 public constant newAddressWaitPeriod = 1 days;
    bool public canAddOBOImmediately = true;

    // List of approved on behalf of users.
    mapping(address => uint256) public approvedOBOs;

    event NewOBOAddressEvent(address OBOAddress, bool action);

    event NewOBOAdminAddressEvent(address oboAdminAddress);

    modifier onlyOBOAdmin() {
        require(
            owner() == _msgSender() || oboAdmin == _msgSender(),
            "not oboAdmin"
        );
        _;
    }

    function setOBOAdmin(address _oboAdmin) external onlyOwner {
        oboAdmin = _oboAdmin;
        emit NewOBOAdminAddressEvent(_oboAdmin);
    }

    /**
     * Add a new approvedOBO address. The address can be used after wait period.
     */
    function addApprovedOBO(address _oboAddress) external onlyOBOAdmin {
        require(_oboAddress != address(0), "cant set to 0x");
        require(approvedOBOs[_oboAddress] == 0, "already added");
        approvedOBOs[_oboAddress] = block.timestamp;
        emit NewOBOAddressEvent(_oboAddress, true);
    }

    /**
     * Removes an approvedOBO immediately.
     */
    function removeApprovedOBO(address _oboAddress) external onlyOBOAdmin {
        delete approvedOBOs[_oboAddress];
        emit NewOBOAddressEvent(_oboAddress, false);
    }

    /*
     * Add OBOAddress for immediate use. This is an internal only Fn that is called
     * only when the contract is deployed.
     */
    function addApprovedOBOImmediately(address _oboAddress) internal {
        require(_oboAddress != address(0), "addr(0)");
        // set the date to one in past so that address is active immediately.
        approvedOBOs[_oboAddress] = block.timestamp - newAddressWaitPeriod - 1;
        emit NewOBOAddressEvent(_oboAddress, true);
    }

    function addApprovedOBOAfterDeploy(address _oboAddress)
        external
        onlyOBOAdmin
    {
        require(canAddOBOImmediately == true, "disabled");
        addApprovedOBOImmediately(_oboAddress);
    }

    function blockImmediateOBO() external onlyOBOAdmin {
        canAddOBOImmediately = false;
    }

    /*
     * Helper function to verify is a given address is a valid approvedOBO address.
     */
    function isValidApprovedOBO(address _oboAddress)
        public
        view
        returns (bool)
    {
        uint256 createdAt = approvedOBOs[_oboAddress];
        if (createdAt == 0) {
            return false;
        }
        return block.timestamp - createdAt > newAddressWaitPeriod;
    }

    /**
     * @dev Modifier to make the obo calls only callable by approved addressess
     */
    modifier isApprovedOBO() {
        require(isValidApprovedOBO(msg.sender), "unauthorized OBO user");
        _;
    }
}

// File: DigitalMediaSaleBase.sol



pragma solidity 0.8.16;






contract DigitalMediaSaleBase is OBOControl, Pausable {
    uint16 public royaltyPercentage = 1000;
    // reserving 0 with BadContract so that we can verify membership of a mapping.
    enum ContractType {
        BadContract,
        MakersPlaceV2,
        MakersPlaceV3
    }
    // Mapping of token contract address to bool indicated approval.
    mapping(address => ContractType) public approvedTokenContracts;
    error InvalidTokenAddress(address tokenAddress);

    /**
     * Adds a new token contract address to be approved to be called.
     */
    function addApprovedTokenContract(
        address _tokenContractAddress,
        ContractType _contractType
    ) external onlyOwner {
        approvedTokenContracts[_tokenContractAddress] = _contractType;
    }

    /**
     * Remove an approved token contract address from the list of approved addresses.
     */
    function removeApprovedTokenContract(address _tokenContractAddress)
        external
        onlyOwner
    {
        delete approvedTokenContracts[_tokenContractAddress];
    }

    /**
     * Checks that a particular token contract address is a valid MP token contract.
     */
    function _isValidTokenContract(address _tokenContractAddress)
        internal
        view
        returns (bool)
    {
        return
            approvedTokenContracts[_tokenContractAddress] !=
            ContractType.BadContract;
    }

    /**
     * Returns an ERC721 instance of a token contract address.  Throws otherwise.
     * Only valid and approved token contracts are allowed to be interacted with.
     */
    function _getTokenContract(address _tokenContractAddress)
        internal
        pure
        returns (IERC721)
    {
        // require(_isValidTokenContract(_tokenContractAddress), "Invalid tcontract");
        return IERC721(_tokenContractAddress);
    }

    /**
     * Checks with the ERC-721 token contract the owner of the a token
     */
    function _ownerOf(uint256 _tokenId, address _tokenContractAddress)
        internal
        view
        returns (address)
    {
        IERC721 tokenContract = _getTokenContract(_tokenContractAddress);
        return tokenContract.ownerOf(_tokenId);
    }

    /**
     * Checks to ensure that the token owner has approved the escrow contract,
     * or escrowAddress owns the token.
     */
    function _approvedForEscrow(
        address _seller,
        uint256 _tokenId,
        address _tokenContractAddress,
        address _escrowAddress
    ) internal view returns (bool) {
        IERC721 tokenContract = _getTokenContract(_tokenContractAddress);
        // seller is the owner of the token, so checking that first
        return (_seller == _escrowAddress ||
            tokenContract.isApprovedForAll(_seller, _escrowAddress) ||
            tokenContract.getApproved(_tokenId) == _escrowAddress);
    }

    /**
     * Transfer an ERC-721 token from seller to the buyer.  This is to be called after a purchase is
     * completed.
     */
    function _transferFromTo(
        address _seller,
        address _receiver,
        uint256 _tokenId,
        address _tokenContractAddress
    ) internal {
        IERC721 tokenContract = _getTokenContract(_tokenContractAddress);
        tokenContract.safeTransferFrom(_seller, _receiver, _tokenId);
    }

    function getDigitalMedia(uint256 _digitalMediaId, address _tokenAddress)
        internal
        view
        returns (
            address creator,
            bool collaborated,
            uint16 royalty
        )
    {
        ContractType cType = approvedTokenContracts[_tokenAddress];
        if (cType == ContractType.MakersPlaceV2) {
            DigitalMediaBurnInterfaceV2 tokenContract = DigitalMediaBurnInterfaceV2(
                    _tokenAddress
                );
            (, , , , creator, ) = tokenContract.getDigitalMedia(
                _digitalMediaId
            );
            collaborated = false;
            royalty = royaltyPercentage;
        } else if (cType == ContractType.MakersPlaceV3) {
            DigitalMediaBurnInterfaceV3 tokenContract = DigitalMediaBurnInterfaceV3(
                    _tokenAddress
                );
            (creator, collaborated, royalty) = tokenContract
                .getDigitalMediaForSale(_digitalMediaId);
        } else {
            revert InvalidTokenAddress({tokenAddress: _tokenAddress});
        }
    }

    function getReleaseMedia(uint256 _tokenId, address _tokenAddress)
        internal
        view
        returns (uint256 mediaId)
    {
        ContractType cType = approvedTokenContracts[_tokenAddress];
        if (cType == ContractType.MakersPlaceV2) {
            DigitalMediaBurnInterfaceV2 tokenContract = DigitalMediaBurnInterfaceV2(
                    _tokenAddress
                );
            (, , mediaId) = tokenContract.getDigitalMediaRelease(_tokenId);
        } else if (cType == ContractType.MakersPlaceV3) {
            DigitalMediaBurnInterfaceV3 tokenContract = DigitalMediaBurnInterfaceV3(
                    _tokenAddress
                );
            (, mediaId) = tokenContract.getDigitalMediaRelease(_tokenId);
        } else {
            revert InvalidTokenAddress({tokenAddress: _tokenAddress});
        }
    }
}

// File: CommissionControl.sol



pragma solidity 0.8.16;



contract CommissionControl is OBOControl, Pausable {
    enum CommissionType {
        InvalidType,
        saleType,
        reSaleType,
        externalType
    }
    event CommissionPercentageChanged(
        CommissionType commissionType,
        uint16 percentage,
        bool committed
    );

    // 3 days wait period before new percentage is in effect
    uint256 public constant commissionAddressWaitPeriod = 3 days;

    struct CommissionStruct {
        uint16 percentage;
        uint16 intermediatePercentage;
        uint256 createdAt;
    }

    CommissionStruct public saleCommission = CommissionStruct(1500, 0, 0);
    CommissionStruct public reSaleCommission = CommissionStruct(250, 0, 0);
    CommissionStruct public externalSaleCommission = CommissionStruct(0, 0, 0);
    uint256 internal constant HUNDREDPERCENT = 10000;

    function _getCommisssionStruct(CommissionType _cType)
        internal
        view
        returns (CommissionStruct storage)
    {
        CommissionStruct storage x;
        if (_cType == CommissionType.saleType) {
            x = saleCommission;
        } else if (_cType == CommissionType.reSaleType) {
            x = reSaleCommission;
        } else {
            x = externalSaleCommission;
        }
        return x;
    }

    /*
     * Change commission percentage for contract. Usually in the range of 80-90%.
     * This change is stored in mapping untill committed. You can only commit
     * after the wait period.
     */
    function changeCommissionPercentage(
        uint16 _percentage,
        CommissionType _cType
    ) external whenNotPaused onlyOwner {
        require(
            _percentage > 0 && _percentage <= HUNDREDPERCENT,
            "Invalid percentage"
        );
        CommissionStruct storage commission = _getCommisssionStruct(_cType);
        require(
            commission.intermediatePercentage == 0,
            "commissionChange exists"
        );
        commission.intermediatePercentage = _percentage;
        commission.createdAt = block.timestamp;
        emit CommissionPercentageChanged({
            commissionType: _cType,
            percentage: _percentage,
            committed: false
        });
    }

    function deleteCommissionChange(CommissionType _cType)
        external
        whenNotPaused
        onlyOwner
    {
        CommissionStruct storage commission = _getCommisssionStruct(_cType);
        commission.intermediatePercentage = 0;
        commission.createdAt = 0;
    }

    /*
     * Commit a commission percentage change that has already been submitted for change.
     */
    function commitCommissionChange(CommissionType _cType)
        external
        whenNotPaused
        onlyOwner
    {
        CommissionStruct storage commission = _getCommisssionStruct(_cType);
        require(
            commission.intermediatePercentage > 0,
            "commissionChange exists"
        );
        require(
            block.timestamp - commission.createdAt >
                commissionAddressWaitPeriod,
            "under wait period"
        );
        commission.percentage = commission.intermediatePercentage;
        commission.intermediatePercentage = 0;
        commission.createdAt = 0;
        emit CommissionPercentageChanged({
            commissionType: _cType,
            percentage: commission.percentage,
            committed: true
        });
    }

    /*
     * Calculates payout for a given sale / bid price by doing the percentage math.
     */
    function _computePayoutForPrice(
        uint256 salePrice,
        uint256 thisCommissionPercentage
    ) internal pure returns (uint256) {
        return
            (salePrice * ((HUNDREDPERCENT - thisCommissionPercentage))) /
            (HUNDREDPERCENT);
    }
}

// File: DigitalMediaFixedSale.sol



pragma solidity 0.8.16;








contract DigitalMediaFixedSale is
    DigitalMediaSaleBase,
    CommissionControl,
    WithdrawFundsControl
{
    // constants (no storage used)
    uint256 internal constant changeContractWaitPeriod = 2 days;

    // storage
    bool public canRoyaltyRegistryChange = true;

    address internal newSafeBoxAddress;
    uint256 internal newSafeBoxCreatedAt;
    address internal newVaultAddress;
    uint256 internal newVaultCreatedAt;

    // Keep track of all the bids so that we dont withdraw current bids from this contract.
    // When a bid is accepted we can subtract the bid value from this totalBidAmount.
    // Initializaing variable to zero costs extra gas. by default its zero.
    uint256 public totalBidAmount;

    /** EVENTS **/
    event SaleCreatedEvent(
        uint256 tokenId,
        address tokenContractAddress,
        bool acceptFiat,
        uint256 priceInWei
    );

    event SaleSuccessfulEvent(
        uint256 tokenId,
        address tokenContractAddress,
        address buyer,
        address payoutAddress,
        uint256 payoutAmount,
        uint256 priceInWei
    );

    event OBOSaleEvent(
        uint256 tokenId,
        address tokenContractAddress,
        address buyer,
        uint256 priceInWei
    );

    event SaleCanceledEvent(uint256 tokenId, address tokenContractAddress);

    event NewSafeBoxRegistered(address newSafeBoxAddress);
    event NewVaultRegistered(address newVaultAddress);
    event NewVaultInEffect(address newVaultAddress);
    event NewSafeBoxInEffect(address newSafeBoxAddress);

    struct DigitalMediaSale {
        bool acceptFiat;
        address seller;
        uint256 priceInWei;
        // if commissionPercentage is set its a non-custodial sale.
        // createSaleOBO will set commissionPercentage to zero.
        uint256 commissionPercentage;
    }

    // Mapping of token contract address to ID to Digital Media Sale object.
    mapping(address => mapping(uint256 => DigitalMediaSale)) public tokenToSale;
    PaymentsBufferInterface public paymentInterface;
    RoyaltyRegistryInterface public royaltyStore;
    SafeBoxInterface public safebox;
    VaultCoreInterface public vaultInterface;

    constructor(
        address _royaltyRegistryAddress,
        address _safebox,
        address _vaultAddress
    ) {
        setRoyaltyRegistryStore(_royaltyRegistryAddress);
        safebox = _validateSafeBoxAddress(_safebox);
        vaultInterface = _validateVaultAddress(_vaultAddress);
    }

    function _validateVaultAddress(address _vaultAddress)
        internal
        pure
        returns (VaultCoreInterface)
    {
        require(_vaultAddress != address(0), "vault can't be 0x");
        bytes32 vault_type = 0x6d707661756c7400000000000000000000000000000000000000000000000000;

        VaultCoreInterface vault = VaultCoreInterface(_vaultAddress);
        require(vault.typeOfContract() == vault_type, "not vault");
        return vault;
    }

    function _validateSafeBoxAddress(address _safebox)
        internal
        pure
        returns (SafeBoxInterface)
    {
        // bytes32 safebox_type = bytes32(bytes("safebox"));
        bytes32 safebox_type = 0x73616665426f7800000000000000000000000000000000000000000000000000;

        SafeBoxInterface sb = SafeBoxInterface(_safebox);
        require(sb.typeOfContract() == safebox_type, "not safebox");
        return sb;
    }

    /*
     * Need to register the new vault address first. Then call setVaultAddress after
     * wait period to set it for good.
     */
    function registerNewVaultAddress(address _vaultAddress) external onlyOwner {
        _validateVaultAddress(_vaultAddress);
        newVaultAddress = _vaultAddress;
        newVaultCreatedAt = block.timestamp;
        emit NewVaultRegistered(_vaultAddress);
    }

    /*
     * Need to register the new safebox address first. Then call setSafeboxddress after
     * wait period to set it for good.
     */
    function registerNewSafeBoxAddress(address _safebox)
        external
        whenNotPaused
        onlyOwner
    {
        newSafeBoxAddress = address(_validateSafeBoxAddress(_safebox));
        newSafeBoxCreatedAt = block.timestamp;
        emit NewSafeBoxRegistered(_safebox);
    }

    /* set the vault for this sale contract. All custodial token owners grant approveAll
     * permission to the vault. The sale contract get approve permission for each token
     * from the vault and transfers it to the final destination in case of sale / bid accept.
     */
    function setVaultAddress(address _vaultAddress) external onlyOwner {
        VaultCoreInterface vault = _validateVaultAddress(_vaultAddress);
        // If we are changing vault address make sure it passes the conditions
        if (address(vaultInterface) != address(0)) {
            // store vault address
            require(_vaultAddress == newVaultAddress, "_vault != newVault");
            require(
                block.timestamp - newVaultCreatedAt > changeContractWaitPeriod,
                "wait"
            );
        }
        vaultInterface = vault;
        emit NewVaultInEffect(_vaultAddress);
    }

    function setSafeboxAddress(address _safebox)
        external
        whenNotPaused
        onlyOwner
    {
        require(_safebox == newSafeBoxAddress, "_safebox != newSafebox");
        require(
            block.timestamp - newSafeBoxCreatedAt > changeContractWaitPeriod,
            "wait"
        );
        safebox = _validateSafeBoxAddress(_safebox);
        emit NewSafeBoxInEffect(_safebox);
    }

    function setRoyaltyPercentage(uint16 _newPercentage)
        external
        whenNotPaused
        onlyOwner
    {
        // Royalty can be 30% max
        require(
            _newPercentage >= 0 && _newPercentage <= 3000,
            "Invalid Royalty"
        );
        royaltyPercentage = _newPercentage;
    }

    function setRoyaltyRegistryStore(address _royaltyStore)
        public
        whenNotPaused
        onlyOBOAdmin
    {
        require(canRoyaltyRegistryChange == true, "no");
        RoyaltyRegistryInterface candidateRoyaltyStore = RoyaltyRegistryInterface(
                _royaltyStore
            );
        require(candidateRoyaltyStore.VERSION() == 1, "roylty v!= 1");
        bytes32 contractType = keccak256(
            abi.encodePacked(candidateRoyaltyStore.typeOfContract())
        );
        // keccak256(abi.encodePacked("royaltyRegistry")) = 0xb590ff355bf2d720a7e957392d3b76fd1adda1832940640bf5d5a7c387fed323
        require(
            contractType ==
                0xb590ff355bf2d720a7e957392d3b76fd1adda1832940640bf5d5a7c387fed323,
            "not royalty"
        );
        royaltyStore = candidateRoyaltyStore;
    }

    function setRoyaltyRegistryForever() external whenNotPaused onlyOwner {
        canRoyaltyRegistryChange = false;
    }

    /**
     * Removes the sale object and emits SaleCanceledEvent.
     */
    function _cancelSale(uint256 _tokenId, address _tokenContractAddress)
        internal
    {
        _removeSale(_tokenId, _tokenContractAddress);
        emit SaleCanceledEvent(_tokenId, _tokenContractAddress);
    }

    /**
     * Removes a token from storage.
     */
    function _removeSale(uint256 _tokenId, address _tokenContractAddress)
        internal
    {
        delete tokenToSale[_tokenContractAddress][_tokenId];
    }

    /**
     * Returns true whether a particular DigitalMediaSale instance is on sale.
     */
    function _isOnSale(DigitalMediaSale storage _sale)
        internal
        view
        returns (bool)
    {
        return (_sale.priceInWei > 0);
    }

    /**
     * Cancel sale if sale exists for a token. Safe to call even if sale does not exist.
     */
    function _cancelSaleIfSaleExists(
        uint256 _tokenId,
        address _tokenContractAddress
    ) internal {
        DigitalMediaSale storage sale = tokenToSale[_tokenContractAddress][
            _tokenId
        ];
        if (_isOnSale(sale)) {
            _cancelSale(_tokenId, _tokenContractAddress);
        }
    }

    /**
     * Handles the purchase logic of a token.  Checks that only tokens on sale are actually
     * purchaseable, ensures that right amount of ether is sent and also sends back any
     * excess payment to the buyer.
     *
     * This function only handles the purchase capability not the actual transfer
     * of the token itself or emitting event related to purchase.
     *
     * The proceeds remains on the smart contract until ready for withdrawl from the CFO account.
     */
    function _purchase(
        uint256 _tokenId,
        address _tokenContractAddress,
        DigitalMediaSale storage sale,
        uint256 _paymentAmount
    ) internal returns (uint256) {
        // Check that the bid is greater than or equal to the current price
        uint256 price = sale.priceInWei;
        require(_paymentAmount >= price, "< price");
        // Remove the token from being on sale before transferring funds to avoid replay
        _removeSale(_tokenId, _tokenContractAddress);
        uint256 excessPayment = _paymentAmount - price;

        if (excessPayment > 0) {
            payable(msg.sender).call{value: excessPayment, gas: 5000};
        }
        return price;
    }

    /* Set PaymentsBuffer interface */
    function registerPaymentsBufferAddress(address _bufferAddress)
        external
        onlyOwner
    {
        require(address(paymentInterface) == address(0), "already set");
        PaymentsBufferInterface paymentsBuffer = PaymentsBufferInterface(
            _bufferAddress
        );
        require(
            paymentsBuffer.typeOfContract() ==
                0x6d707061796d656e747362756666657200000000000000000000000000000000,
            "not buffer"
        );
        paymentInterface = paymentsBuffer;
    }

    /*
     * Transfer money to an address. If the transfer fails move the funds to
     * PaymentsBuffer contract where the owner of the funds can come and claim it.
     */
    function transferFunds(address _toAddress, uint256 amount) internal {
        (bool sent, ) = _toAddress.call{value: amount, gas: 5000}("");
        if (!sent) {
            require(
                address(paymentInterface) != address(0),
                "paymentInterface should be set"
            );
            paymentInterface.add{value: amount}(_toAddress);
        }
    }

    /**
     * Withdraws all the funds to a specified non-zero address.
     */
    function withdrawFunds(address payable _withdrawAddress)
        external
        isApprovedOBO
    {
        require(
            isApprovedWithdrawAddress(_withdrawAddress),
            "unapproved withdrawAddress"
        );
        uint256 contractBalance = address(this).balance;
        // We can withdraw all successful sale related funds but not pending bids
        uint256 deductibleBalance = contractBalance - totalBidAmount;
        _withdrawAddress.transfer(deductibleBalance);
    }

    /**
     * Validate tokenId, tokenAddress and escrow permission for msg.sender
     */
    function validateTokenForEscrow(
        uint256 _tokenId,
        address _tokenContractAddress
    ) internal view returns (address) {
        address seller = _ownerOf(_tokenId, _tokenContractAddress);
        require(msg.sender == seller, "msg.sender != seller");
        require(
            _approvedForEscrow(
                msg.sender,
                _tokenId,
                _tokenContractAddress,
                address(this)
            ),
            "approve/All missing"
        );
        return seller;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// File: GlobalDigitalMediaBidCore.sol



pragma solidity 0.8.16;




/**
 * This contract facilitates bidding to NFT holders. An NFT holder can choose to accept an offer.
 * Global meaning bidding accross one media. One media can have several editions
 * The seller can be custodial or non-custodial. If seller is custodial, then they're paid off-chain
 * A new bidder replaces the previous bid.
 * Custodial is On Behalf Of (OBO) the seller.
 * CONTRACTS
 * ---------------------------------------------------------------------------------
 * VaultCore      - holds the custodial seller's NFT in escrow
 * RoyaltyRegistry- used to get commision to pay creator/collaborators. Handles non MP contracts
 *                  non-EIP standard.. https://royaltyregistry.xyz/lookup
 * TransferCore   - not used
 * PaymentBuffer  - Send/withdraw ether
 */
contract GlobalDigitalMediaBidCore is DigitalMediaFixedSale, ReentrancyGuard {
    using Counters for Counters.Counter;

    // constants
    uint8 public constant VERSION = 1;
    bytes32 private constant safeboxType =
        0x73616665426f7800000000000000000000000000000000000000000000000000;

    // storage slots
    Counters.Counter private _bidCounter;
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public mediaIdToPartialBidId;
    // bidIdToTokenBid[2] = TokenBid(bidder, price)
    mapping(uint256 => TokenBid) public bidIdToTokenBid;

    struct TokenBid {
        address bidder;
        uint256 price;
    }

    struct OBOAcceptBidStruct {
        uint256 tokenId;
        uint256 bidId;
        address tokenAddress;
        bool useSafebox;
    }

    struct CancelBidStruct {
        uint256 tokenId;
        address tokenAddress;
        address bidder;
    }

    event MediaBidCreatedEvent(
        uint256 mediaId,
        address tokenAddress,
        uint256 bidId,
        uint256 bidPrice,
        uint256 partialPrice,
        address bidder
    );

    event MediaBidRemovedEvent(
        uint256 mediaId,
        address tokenAddress,
        address bidderAddress,
        uint256 bidId,
        uint256 price
    );

    event MediaBidAcceptedEvent(
        uint256 tokenId,
        address tokenAddress,
        uint256 bidId,
        uint256 bidPrice,
        address bidder,
        address payoutAddress,
        address seller,
        uint256 payoutAmount
    );

    constructor(
        address _royaltyRegistryAddress,
        address _safebox,
        address _vault
    ) DigitalMediaFixedSale(_royaltyRegistryAddress, _safebox, _vault) {}

    /**
     * Compute commission percentage for a given token. Checks if token creator is seller
     * to determine if its a sale or a resale.
     */
    function _getCommissionPercentageForToken(
        address _seller,
        uint256 _tokenId,
        address _tokenContractAddress
    ) internal view returns (uint256) {
        // if the tokenContractAddress is of external type return external sale commission
        if (_isValidTokenContract(_tokenContractAddress) == false) {
            (uint16 customCommission, uint16 customRoyalty) = royaltyStore
                .getExternalTokenPercentage(_tokenId, _tokenContractAddress);
            return
                customCommission + customRoyalty > 0
                    ? customCommission + customRoyalty
                    : externalSaleCommission.percentage;
        }
        uint256 digitalMediaId = getReleaseMedia(
            _tokenId,
            _tokenContractAddress
        );
        (address creator, bool collaborated, uint16 royalty) = getDigitalMedia(
            digitalMediaId,
            _tokenContractAddress
        );
        uint256 commissionPercentage;
        if (creator == _seller) {
            // if this media is a collaborated piece dont do payout on chain
            if (collaborated == true) {
                commissionPercentage = 0;
            } else {
                uint16 customPercentage = royaltyStore.getMediaCustomPercentage(
                    digitalMediaId,
                    _tokenContractAddress
                );
                commissionPercentage = customPercentage > 0
                    ? customPercentage
                    : saleCommission.percentage;
            }
        } else {
            // for secondary sales charge commission + royalty
            commissionPercentage = reSaleCommission.percentage + royalty;
        }
        return commissionPercentage;
    }

    /**********************
     *     GLOBAL BIDDING  *
     **********************/

    /**
     * Function to put a bid on an approved ERC721 contract media. This function
     * stores only the current bid and the bid value in the contract. Any one can
     * bid on any media. Make sure you are bidding over the current bid price.
     * Global meaning bidding accross one media. One media can have several editions
     */
    function globalBidOnToken(
        uint256 _digitalMediaId,
        address _tokenContractAddress
    ) external payable whenNotPaused {
        uint256 bidPrice = msg.value;
        require(bidPrice > 0, "send msg.value");
        (address creator, , ) = getDigitalMedia(
            _digitalMediaId,
            _tokenContractAddress
        );
        require(creator != address(0), "no media");
        // Check if a current bid id exists for this mediaId + msg.sender
        uint256 currentBidId = mediaIdToPartialBidId[_tokenContractAddress][
            _digitalMediaId
        ][msg.sender];
        TokenBid memory currentBid = bidIdToTokenBid[currentBidId];
        if (currentBidId != 0) {
            currentBid.price = currentBid.price + bidPrice;
        } else {
            currentBid.bidder = msg.sender;
            currentBid.price = bidPrice;
            _bidCounter.increment();
            currentBidId = _bidCounter.current();
            mediaIdToPartialBidId[_tokenContractAddress][_digitalMediaId][
                msg.sender
            ] = currentBidId;
        }
        bidIdToTokenBid[currentBidId] = currentBid;
        totalBidAmount = totalBidAmount + bidPrice;
        // msg.value is automatically transferred to the contract.
        // No need to explicity move the money
        // https://programtheblockchain.com/posts/2017/12/15/writing-a-contract-that-handles-ether/
        emit MediaBidCreatedEvent(
            _digitalMediaId,
            _tokenContractAddress,
            currentBidId,
            currentBid.price,
            bidPrice,
            msg.sender
        );
    }

    function _getAndDeleteCurrentBid(
        uint256 _tokenId,
        address _tokenContractAddress,
        uint256 _bidId
    ) internal returns (address bidder, uint256 bidPrice) {
        // make sure that this tokenId's mediaId matches the one on bid object
        uint256 mediaId = getReleaseMedia(_tokenId, _tokenContractAddress);
        TokenBid storage currentBid = bidIdToTokenBid[_bidId];
        bidder = currentBid.bidder;
        bidPrice = currentBid.price;
        require(bidder != address(0), "no bid");
        uint256 userBidId = mediaIdToPartialBidId[_tokenContractAddress][
            mediaId
        ][bidder];
        require(userBidId != 0, "No bid");
        require(userBidId == _bidId, "bidId not current");

        // Delete the bid to avoid re-entrancy attack
        delete mediaIdToPartialBidId[_tokenContractAddress][mediaId][bidder];
        delete bidIdToTokenBid[_bidId];
        totalBidAmount = totalBidAmount - bidPrice;

        _cancelSaleIfSaleExists(_tokenId, _tokenContractAddress);
        return (bidder, bidPrice);
    }

    /**
     * Seller accepts the current bid on a digital media (only they can call this).
     * Token is sent to the buyer and seller gets onchain payout
     * Global meaning bidding accross one media. One media can have several editions
     */
    function acceptGlobalBid(
        uint256 _tokenId,
        address _tokenContractAddress,
        uint256 _bidId
    ) external whenNotPaused nonReentrant {
        address seller = validateTokenForEscrow(
            _tokenId,
            _tokenContractAddress
        );
        (address currentBidder, uint256 bidPrice) = _getAndDeleteCurrentBid(
            _tokenId,
            _tokenContractAddress,
            _bidId
        );
        _transferFromTo(seller, currentBidder, _tokenId, _tokenContractAddress);
        uint256 commissionPercentage = _getCommissionPercentageForToken(
            seller,
            _tokenId,
            _tokenContractAddress
        );
        // Perform payout since seller is not a custodial account and can accept payment
        // This endpoint is called only by the tokenOwner. We decided if the token owner
        // took the pain to call this endpoint we will charge a commission based
        // on if its sold by creator or other.
        uint256 payoutAmount = 0;
        if (commissionPercentage > 0) {
            payoutAmount = _computePayoutForPrice(
                bidPrice,
                commissionPercentage
            );
            if (payoutAmount > 0) {
                transferFunds(seller, payoutAmount);
            }
        }
        emit MediaBidAcceptedEvent({
            tokenId: _tokenId,
            tokenAddress: _tokenContractAddress,
            bidId: _bidId,
            bidPrice: bidPrice,
            bidder: currentBidder,
            payoutAddress: seller,
            seller: seller,
            payoutAmount: payoutAmount
        });
    }

    /**
     * Accept eth bids in exchange for the custodial NFTs
     * - Seller's custodial NFT is escrowed in the vault.
     * - Buyer's eth bid is held onchain here.
     * Move the vault escrowed NFT to the buyer. Seller is paid off-chain
     * OBO is on behalf of, meaning we are the custodial middle men (OBO the seller). Seller doesn't have a wallet.
     * Global meaning bidding accross one media. One media can have several editions
     */
    function acceptGlobalBidsOBO(OBOAcceptBidStruct[] memory _requests)
        external
        whenNotPaused
        isApprovedOBO
    {
        for (uint256 i = 0; i < _requests.length; i++) {
            address tokenAddress = _requests[i].tokenAddress;
            uint256 tokenId = _requests[i].tokenId;
            uint256 bidId = _requests[i].bidId;
            bool useSafebox = _requests[i].useSafebox;
            address seller = _ownerOf(tokenId, tokenAddress);

            (address currentBidder, uint256 bidPrice) = _getAndDeleteCurrentBid(
                tokenId,
                tokenAddress,
                bidId
            );
            if (useSafebox) {
                safebox.singleTransfer(tokenAddress, tokenId, currentBidder);
            } else {
                vaultInterface.approveToken(tokenId, tokenAddress);
                _transferFromTo(seller, currentBidder, tokenId, tokenAddress);
            }

            emit MediaBidAcceptedEvent({
                tokenId: tokenId,
                tokenAddress: tokenAddress,
                bidId: bidId,
                bidPrice: bidPrice,
                bidder: currentBidder,
                payoutAddress: address(0),
                seller: seller,
                payoutAmount: 0
            });
        }
    }

    function _cancelMediaBid(
        uint256 _mediaId,
        address _tokenContractAddress,
        TokenBid memory partialBid,
        uint256 partialBidId
    ) internal {
        uint256 price = partialBid.price;
        delete mediaIdToPartialBidId[_tokenContractAddress][_mediaId][
            partialBid.bidder
        ];
        delete bidIdToTokenBid[partialBidId];
        totalBidAmount = totalBidAmount - price;
        transferFunds(partialBid.bidder, price);
        emit MediaBidRemovedEvent(
            _mediaId,
            _tokenContractAddress,
            partialBid.bidder,
            partialBidId,
            price
        );
    }

    /**
     * Cancel the current global bid for a digital media. Only the current bidder
     * can call this function. Cancelling the bid will move the
     * funds back to the bidder.
     * Global meaning bidding accross one media. One media can have several editions
     */
    function cancelGlobalBid(
        uint256 _mediaId,
        address _tokenContractAddress,
        uint256 _bidId
    ) external nonReentrant {
        uint256 currentBidId = mediaIdToPartialBidId[_tokenContractAddress][
            _mediaId
        ][msg.sender];
        require(currentBidId != 0, "No bid");
        require(currentBidId == _bidId, "not ur bid");
        TokenBid storage currentBid = bidIdToTokenBid[currentBidId];
        require(currentBid.bidder == msg.sender, "msg.sender!=bidder");
        _cancelMediaBid(_mediaId, _tokenContractAddress, currentBid, _bidId);
    }

    /**
     * Cancel many global bids for many medias. Only approved OBO address can call this.
     * Global meaning bidding accross one media. One media can have several editions
     */
    function cancelGlobalBidsOBO(CancelBidStruct[] memory requests)
        external
        whenNotPaused
        isApprovedOBO
    {
        for (uint32 i = 0; i < requests.length; i++) {
            CancelBidStruct memory request = requests[i];
            uint256 partialBidId = mediaIdToPartialBidId[request.tokenAddress][
                request.tokenId
            ][request.bidder];
            if (partialBidId != 0) {
                TokenBid storage partialBid = bidIdToTokenBid[partialBidId];
                _cancelMediaBid(
                    request.tokenId,
                    request.tokenAddress,
                    partialBid,
                    partialBidId
                );
            }
        }
    }

    /**
     * For a given approved ERC721 media, get the current bid
     * Global meaning bidding accross one media. One media can have several editions
     */
    function getGlobalBidForMedia(
        uint256 _mediaId,
        address _tokenContractAddress,
        address _bidderAddress
    ) external view returns (uint256 bidId, uint256 price) {
        uint256 globalBidId = mediaIdToPartialBidId[_tokenContractAddress][
            _mediaId
        ][_bidderAddress];
        if (globalBidId == 0) {
            return (0, 0);
        } else {
            TokenBid storage currentBid = bidIdToTokenBid[globalBidId];
            return (globalBidId, currentBid.price);
        }
    }

    // pause (idempotent)
    function pause() external onlyOwner {
        if (!paused()) {
            _pause();
        }
    }

    // unpause (idempotent)
    function unpause() external onlyOwner {
        if (paused()) {
            _unpause();
        }
    }

    function renounceOwnership() public view override onlyOwner {
        revert("no");
    }
}