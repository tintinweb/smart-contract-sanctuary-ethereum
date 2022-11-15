/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// File: interfaces/IS7NSBox.sol


pragma solidity ^0.8.0;

interface IS7NSBox {

	/**
       	@notice Mint Boxes to `_beneficiary`
       	@dev  Caller must have MINTER_ROLE
		@param	_beneficiary			Address of Beneficiary
		@param	_fromID					Start of TokenID
		@param	_amount					Amount of Boxes to be minted
    */
	function produce(address _beneficiary, uint256 _fromID, uint256 _amount) external;

	/**
       	@notice Burn Boxes from `msg.sender`
       	@dev  Caller can be ANY
		@param	_ids				A list of `tokenIds` to be burned
		
		Note: MINTER_ROLE is granted a privilege to burn Boxes
    */
	function destroy(uint256[] calldata _ids) external;
}

// File: interfaces/IS7NSManagement.sol


pragma solidity ^0.8.0;

/**
   @title IS7NSManagement contract
   @dev Provide interfaces that allow interaction to S7NSManagement contract
*/
interface IS7NSManagement {
    function treasury() external view returns (address);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function paymentTokens(address _token) external view returns (bool);
    function halted() external view returns (bool);
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

// File: SpecialEvent.sol


pragma solidity ^0.8.0;




contract SpecialEvent {

	uint256 private constant START_TIME = 1668528000;		//	Nov 15th, 2022 16:00 PM (UTC)
	bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
	
	IS7NSManagement public immutable management;
    address public immutable gAvatar;
    address public immutable box;
    uint256 public endTime;
    uint256 public counter;

    //  A list of `gAvatarId` has been claimed
    mapping(uint256 => bool) public claimed;

	modifier onlyManager() {
		require(
			management.hasRole(MANAGER_ROLE, msg.sender), "OnlyManager"
		);
        _;
    }

    event Claimed(address indexed caller, uint256[] avatarIds);

	constructor(
		IS7NSManagement _management,
        address _gAvatar,
		address _box,
        uint256 _endTime
	) {
		management = _management;
        gAvatar = _gAvatar;
		box = _box;
        endTime = _endTime;
	}

    /**
       	@notice Update `endTime` of special event
       	@dev  Caller must have MANAGER_ROLE
		@param	_endTime			New ending time
    */
    function updateTime(uint256 _endTime) external onlyManager {
        endTime = _endTime;
    }

    /**
       	@notice Update new value of `counter`
       	@dev  Caller must have MANAGER_ROLE
		@param	_counter			New value of `counter`
    */
    function setCounter(uint256 _counter) external onlyManager {
        counter = _counter;
    }

    /**
       	@notice Claim Box
       	@dev  Caller must own Genesis Avatar
        - 1 Genesis Avatar = 1 Box
		@param	_gAvatarIds			A list of the Genesis Avatar ID
    */
    function claim(uint256[] calldata _gAvatarIds) external {
        //  If a claim is requested before or after a schedule event -> revert
        uint256 _currentTime = block.timestamp;
        require(
            START_TIME <= _currentTime && _currentTime <= endTime, "NotAvailable"
        );

        //  1 `gAvatarId` = 1 Box. Thus, check ownership of `_gAvatarIds`
        //  and also check whether they have been used to claim before
        uint256 _amount = _gAvatarIds.length;
        address _caller = msg.sender;
        IERC721 _gAvatar = IERC721(gAvatar);
        uint256 _id;
        for (uint256 i; i < _amount; i++) {
            _id = _gAvatarIds[i];
            require(
                _gAvatar.ownerOf(_id) == _caller && !claimed[_id],
                "InvalidRequest"
            );
            claimed[_id] = true;
        }

        //  Mint Boxes to `_caller`
        IS7NSBox(box).produce(_caller, counter, _amount);
        counter += _amount;

        emit Claimed(_caller, _gAvatarIds);
    }
}