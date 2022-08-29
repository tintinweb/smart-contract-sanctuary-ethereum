// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './ERC721Copy/IMintable.sol';
import './ERC721Copy/IERC721Copy.sol';

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

/**
 * @dev the fee to be paid before minting / extending a copy token
 * 
 * @param tokenContract The contract address of the fee token, i.e. USDT token contract address
 * @param mintAmount The token amount that is required for minting a copy token
 * @param extendAmount The token amount that is required for extending a copy token
 */
struct FeeInfo {
    address tokenContract;
    uint256 mintAmount;
    uint256 extendAmount;
}

/**
 * @dev parameters of the to be minted/extended copy token
 * see {IMintable}
 */
struct MintData {
    bool transferable;
    bool updatable;
    bool revokable;
    bool extendable;
    uint64 duration;
    string statement;
}

/**
 * @dev States of the mintable rule
 *
 * @param NIL Rule not exists
 * @param EXIST Rule exists for minting and extending
 * @param PAUSED Rule paused for minting but available for extending
 */
enum State {
    NIL,
    EXIST,
    PAUSED
}

/**
 * @notice This contract is used to enable mintable and extending a token with a fee charged. The 
 * creator will need to setup rules for copier/collector to follow before a copy token is minted / 
 * extended. 
 * 
 */
contract FeeMintable is IMintable {

    event SetupRule(
        address copyContract,
        uint256 creatorId,
        MintData[] mintData,
        FeeInfo[] feeInfo
    );

    // address => creatorId => RuleData[]
    // the address is the copy contract address, which is also the msg.sender to this contract
    // the creatorId, is the tokenId of the creator contract
    mapping(address => mapping(uint256 => bytes32[])) private _copyRules;
    mapping(bytes32 => State) private _states;

    /**
     * @dev The function for creator to setup a mintable rule. If this function is run more than once,
     * rules setup in the previous run will be set to PAUSED state, and the rules in the latest run will
     * be set to EXIST state.
     *
     * @param creatorId The creator token Id
     * @param ruleData The data for setting up the mintable rule. Here, it is composed of the serialized
     * struct arrays MintData[] and FeeInfo[], MintData specifies the type of Copy token, whereas FeeInfo
     * specifies the required fee for minting / extending a type of token.
     */
    function setupRule(uint256 creatorId, bytes calldata ruleData) external override {
        (MintData[] memory mintData, FeeInfo[] memory feeInfo) = abi.decode(
            ruleData,
            (MintData[], FeeInfo[])
        );

        // pause existing rules
        for (uint256 i = 0; i < _copyRules[msg.sender][creatorId].length; i++) {
            _states[_copyRules[msg.sender][creatorId][i]] = State.PAUSED;
        }
        delete _copyRules[msg.sender][creatorId];

        // setup new rules
        for (uint256 i = 0; i < mintData.length; i++) {
            bytes32 copyHash = _getHash(creatorId, mintData[i], feeInfo[i]);
            _copyRules[msg.sender][creatorId].push(copyHash);
            _states[copyHash] = State.EXIST;
        }

        emit SetupRule(msg.sender, creatorId, mintData, feeInfo);
    }

    /**
     * @dev Function for collecting fee before minting. The minter will need to supply information that
     * exactly match the rule specified by the creator. Only rules in EXIST state will be processed.
     *
     * @param to The address of the copy token receiver
     * @param mintInfo The rule information for minting
     */
    function isMintable(address to, MintInfo calldata mintInfo) external override {
        FeeInfo memory feeInfo = abi.decode(mintInfo.data, (FeeInfo));

        MintData memory mintData = MintData(
            mintInfo.transferable,
            mintInfo.updatable,
            mintInfo.revokable,
            mintInfo.extendable,
            mintInfo.duration,
            mintInfo.statement
        );

        bytes32 copyHash = _getHash(mintInfo.creatorId, mintData, feeInfo);
        // check if the condition supplied by the minter matches that specified by the creator
        require(_states[copyHash] == State.EXIST, 'FeeMintable: Invalid Parameters');

        // collect fee
        IERC20(feeInfo.tokenContract).transferFrom(
            to,
            IERC721(IERC721Copy(msg.sender).getCreatorContract()).ownerOf(mintInfo.creatorId),
            feeInfo.mintAmount
        );
    }

    /**
     * @dev Function for collecting fee before extending. The extender will need to supply information 
     * that exactly match the rule specified by the creator. Only rules in PAUSED or EXIST state will be 
     * processed.
     *
     * @param to The address of the copy token receiver
     * @param mintInfo The rule information for minting
     */
    function isExtendable(
        address to,
        uint64 expiry, // expiry is unused here, it could be used to reject extension on expired tokens
        MintInfo memory mintInfo
    ) external override {
        FeeInfo memory feeInfo = abi.decode(mintInfo.data, (FeeInfo));

        MintData memory mintData = MintData(
            mintInfo.transferable,
            mintInfo.updatable,
            mintInfo.revokable,
            mintInfo.extendable,
            mintInfo.duration,
            mintInfo.statement
        );

        bytes32 copyHash = _getHash(mintInfo.creatorId, mintData, feeInfo);
        // check if the condition supplied by the minter matches that specified by the creator
        require(_states[copyHash] == State.EXIST || _states[copyHash] == State.PAUSED, 'FeeMintable: Invalid Parameters');

        // collect fee
        IERC20(feeInfo.tokenContract).transferFrom(
            to,
            IERC721(IERC721Copy(msg.sender).getCreatorContract()).ownerOf(mintInfo.creatorId),
            feeInfo.extendAmount
        );
    }

    function _getHash(
        uint256 creatorId,
        MintData memory mintData,
        FeeInfo memory feeInfo
    ) internal view returns (bytes32) {
        // include msg sender to distinguish different contracts
        return
            keccak256(
                abi.encode(
                    msg.sender,
                    creatorId,
                    mintData.transferable,
                    mintData.revokable,
                    bytes(mintData.statement),
                    mintData.duration,
                    mintData.extendable,
                    mintData.updatable,
                    feeInfo.tokenContract,
                    feeInfo.mintAmount,
                    feeInfo.extendAmount
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IMintable {
    /**
     * @notice mintInfo struct that specifies the input to the minting function
     *
     * @param creatorId The tokenId of the creator NFT that produces the original content
     * @param duration The time duration that should add to the NFT token after mint
     * @param transferable Indicates whether the token is transferable
     * @param updatable Indicates whether the token is updatable.
     * @param revokable Indicataes whether the token is recovable by the creator token holder
     * @param extendable Indicates whether the token can be extended beyond the deadline
     * @param statement The copyright declaration by the creator token holder
     * @param data Addition data that is required by the Mintable rule to pass. Should deserialize into variables specified
     * in the abi.decode function in the app
     */
    struct MintInfo {
        uint256 creatorId;
        uint64 duration;
        bool transferable;
        bool updatable;
        bool revokable;
        bool extendable;
        string statement;
        bytes data;
    }

    /**
     * @notice Sets up the mintable rule by the creator NFT's tokenId and the ruleData. This function will
     * decode the ruleData back to the required parameters and sets up the mintable rule that decides who
     * can or cannot mint a copy of the creator's NFT content, with the corresponding parameters, such as
     * transferable, updatable etc. see {IMintable-MintInfo}
     *
     * @param creatorId The token Id of the creator NFT, i.e. the token which will get its contentUri copied
     * @param ruleData The data bytes for initialising the mintableRule. Parameters are encoded into bytes
     */
    function setupRule(uint256 creatorId, bytes calldata ruleData) external;

    /**
     * @notice Supply the data that will be used to passed the mintable rule setup by the creator. Different
     * rule has different requirement
     *
     * @param to the address that the NFT will be minted to
     * @param mintInfo the mint information as indicated in {IMintable-MintInfo}
     */
    function isMintable(address to, MintInfo calldata mintInfo) external;

    /**
     * @notice Supply the the expiry date of the NFT and data that will be used to passed the mintable rule setup
     * by the creator. Different rule has different requirement. Once pass the NFT expiry will be extended by the
     * specific duration
     *
     * @param to the token holder of the copy NFT
     * @param expiry the expiry timestamp of the token
     * @param mintInfo the mint information as indicated in {IMintable-MintInfo}
     */
    function isExtendable(
        address to,
        uint64 expiry,
        MintInfo memory mintInfo
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC721Copy {
    /**
     * @notice Struct containing the information of the minted copy NFT
     *
     * @param creatorId The tokenId of the creator NFT that produces the original content
     * @param extendAt The contract address that the user can go to when extending the expiration timestemp
     * @param expiredAt The expiration timestamp of the nft token
     * @param transferable Indicates whether the token is transferable
     * @param updatable Indicates whether the token is updatable.
     *  User can update the contentUri of the copy token (copyUri) to the latest contentUri state of the creator token
     * @param revokable Indicataes whether the token is recovable by the creator token holder
     * @param extendable Indicates whether the token can be extended beyond the deadline
     * @param copyURI Shows the contentUri copied from the creator token for collection purposes
     * @param statement The copyright declaration by the creator token holder. The declaration may include the rights that
     * the copy NFT owner will get, for instance, the right to create derivative work based on the creator NFT content
     */
    struct CopyInfo {
        uint256 creatorId;
        address extendAt;
        uint64 expireAt;
        bool transferable;
        bool updatable;
        bool revokable;
        bool extendable;
        string copyURI;
        string statement;
    }

    /**
     * @return address Returns the address of the creator NFT contract
     */
    function getCreatorContract() external view returns (address);

    /**
     * @return uint256 Returns the total number of minted copy NFT tokens
     */
    function getTokenCount() external view returns (uint256);

    /**
     * @param creatorId The creator NFT token Id
     *
     * @return uint256 Returns the total number of copy NFT tokens minted based on a particular creator NFT token
     */
    function getCopyCount(uint256 creatorId) external view returns (uint256);

    /**
     * @param creatorId The creator NFT token Id
     * @param index The index of the list of copy NFTs minted based on the creatorId, index starts from 1
     *
     * @return uint256 Returns the copy NFT tokenId of a particular creator NFT token
     */
    function getCopyByIndex(uint256 creatorId, uint256 index) external view returns (uint256);

    /**
     * @notice The copy NFT is transferable if its transferable parameter is true and it has not expired
     *
     * @param tokenId The copy NFT token Id
     *
     * @return bool Returns a boolean indicating whether the token is transferable
     */
    function isTransferable(uint256 tokenId) external view returns (bool);

    /**
     * @notice The copy NFT is updatable if its updatable parameter is true and it has not expired
     *
     * @param tokenId The copy NFT token Id
     *
     * @return bool Returns a boolean indicating whether the token is updatable
     */
    function isUpdatable(uint256 tokenId) external view returns (bool);

    /**
     * @notice The copy NFT is revokable if its revokable parameter is true or it has expired
     *
     * @param tokenId The copy NFT token Id
     *
     * @return bool Returns a boolean indicating whether the token is is revokable
     */
    function isRevokable(uint256 tokenId) external view returns (bool);

    /**
     * @notice The copy NFT is extendable if its extendable parameter is true
     *
     * @param tokenId The copy NFT token Id
     *
     * @return bool Returns a boolean indicating whether the token is is extendable
     */
    function isExtendable(uint256 tokenId) external view returns (bool);

    /**
     * @param tokenId The copy NFT token Id
     *
     * @return bool Returns a boolean indicating whether the token is is expired
     */
    function isExpired(uint256 tokenId) external view returns (bool);

    /**
     * @dev See {IERC721-ownerOf}.
     *
     * @notice This function calls the IERC721 ownerOf function. It returns the token owner regardless of whether
     * the token is currently expired.
     *
     * @param tokenId The copy NFT tokenId
     *
     * @return address Returns the address of the token holder
     */
    function holderOf(uint256 tokenId) external view returns (address);

    /**
     * @param tokenId The copy NFT tokenId
     *
     * @return uint256 Returns the creator NFT tokenId that the copy NFT is based on
     */
    function creatorOf(uint256 tokenId) external view returns (uint256);

    /**
     * @param creatorId The creator NFT tokenId
     *
     * @return address Returns of the mintable rule provided by the creator NFT token owner
     */
    function getMintableRule(uint256 creatorId) external view returns (address);

    /**
     * @param tokenId The copy NFT tokenId
     *
     * @return string Returns the content identifier of the copyright declaration that the creaetor provided
     */
    function getStatement(uint256 tokenId) external view returns (string memory);

    /**
     * @param tokenId The copy NFT tokenId
     *
     * @return string Returns the expiration timestamp of the token
     */
    function expireAt(uint256 tokenId) external view returns (uint64);
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