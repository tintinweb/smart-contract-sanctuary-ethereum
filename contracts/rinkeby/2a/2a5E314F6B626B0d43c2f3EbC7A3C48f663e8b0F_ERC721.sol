/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = '0123456789abcdef';

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return '0';
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

    function toString16(uint16 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return '0';
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
}

/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

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

contract AccessControl {
    address public creatorAddress;

    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress, 'You are not the creator');
        _;
    }

    // Constructor
    constructor() {
        creatorAddress = msg.sender;
    }

    function changeOwner(address payable _newOwner) public onlyCREATOR {
        creatorAddress = _newOwner;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );

        (bool success, ) = recipient.call{value: amount}('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, 'Address: low-level call failed');
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                'Address: low-level call with value failed'
            );
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
        require(
            address(this).balance >= value,
            'Address: insufficient balance for call'
        );
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                'Address: low-level static call failed'
            );
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
        require(isContract(target), 'Address: static call to non-contract');

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                'Address: low-level delegate call failed'
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), 'Address: delegate call to non-contract');

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract Enums {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_OWNER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }
}

abstract contract IAngelCardData is AccessControl, Enums {
    // write
    // mint function
    function setAngel(
        uint8 _angelCardSeriesId,
        address _owner,
        uint256 _price,
        uint16 _battlePower
    ) external virtual returns (uint64);

    function transferAngel(
        address _from,
        address _to,
        uint64 _angelId
    ) public virtual returns (ResultCode);

    // read
    function getAngel(uint64 _angelId)
        public
        virtual
        returns (
            uint64 angelId,
            uint8 angelCardSeriesId,
            uint16 battlePower,
            uint8 aura,
            uint16 experience,
            uint256 price,
            uint64 createdTime,
            uint64 lastBattleTime,
            uint64 lastVsBattleTime,
            uint16 lastBattleResult,
            address owner
        );

    function getAngelLockStatus(uint64 _angelId) public virtual returns (bool);

    function ownerAngelTransfer(address _to, uint64 _angelId) public virtual;
}

abstract contract IPetCardData is AccessControl, Enums {
    // write
    function setPet(
        uint8 _petCardSeriesId,
        address _owner,
        string memory _name,
        uint8 _luck,
        uint16 _auraRed,
        uint16 _auraYellow,
        uint16 _auraBlue
    ) external virtual returns (uint64);

    function transferPet(
        address _from,
        address _to,
        uint64 _petId
    ) public virtual returns (ResultCode);

    // read
    function getPet(uint256 _petId)
        public
        virtual
        returns (
            uint256 petId,
            uint8 petCardSeriesId,
            string memory name,
            uint8 luck,
            uint16 auraRed,
            uint16 auraBlue,
            uint16 auraYellow,
            uint64 lastTrainingTime,
            uint64 lastBreedingTime,
            address owner
        );
}

abstract contract IAccessoryData is AccessControl, Enums {
    // write
    function setAccessory(uint8 _AccessorySeriesId, address _owner)
        external
        virtual
        returns (uint64);

    function transferAccessory(
        address _from,
        address _to,
        uint64 __accessoryId
    ) public virtual returns (ResultCode);

    // read
    function getAccessory(uint256 _accessoryId)
        public
        virtual
        returns (
            uint256 accessoryID,
            uint8 AccessorySeriesID,
            address owner
        );

    function getAccessoryLockStatus(uint64 _acessoryId)
        public
        virtual
        returns (bool);

    function ownerAccessoryTransfer(address _to, uint64 __accessoryId)
        public
        virtual;
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, AccessControl {
    using Address for address;
    using Strings for uint256;
    using Strings for uint64;
    using Strings for uint16;
    using Strings for uint8;

    // Token name
    string private _name = 'Angel Battles Historical Wrapper';

    // Token symbol
    string private _symbol = 'ABT';

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 public totalSupply = 0;

    //Mapping or which IDs each address owns
    mapping(address => uint256[]) public ownerABTokenCollection;

    //current and max numbers of issued tokens for each series
    uint32[100] public currentTokenNumbers;

    string public ipfsGateway = 'https://ipfs.io/ipfs/';

    address public angelCardDataAddress =
        //0x6D2E76213615925c5fc436565B5ee788Ee0E86DC;
        0x76177DCe92a8F69d7aDEACdf9aEda0F9a93a147d;
    address public petCardDataAddress =
        // 0xB340686da996b8B3d486b4D27E38E38500A9E926;
        0x1A5E2ee2c68f6492971313340b1593713006Cd33;
    address public accessoryCardDataAddress =
        //  0x466c44812835f57b736ef9F63582b8a6693A14D0;
        0x533879587F57b84Bf329F1eCc1896bAedB244023;

    address payable public paymentSplitter =
        payable(0x4f9cafBE6278e91c54d696CB3096B1d566dcF026);

    //  Main data structure for each token
    struct ABCard {
        uint256 tokenId;
        uint8 cardSeriesId;
        //This is 0 to 23 for angels, 24 to 42 for pets, 43 to 60 for accessories, 61 to 72 for medals

        uint16 power;
        //This number is luck for pets and battlepower for angels
        uint16 auraRed;
        uint16 auraYellow;
        uint16 auraBlue;
        string name;
        uint16 experience;
        uint64 lastBattleTime;
        uint16 oldId; // the id of the wrapped card
        uint64 createdTime;
    }

    struct AuraMapping {
        uint16 auraRed;
        uint16 auraYellow;
        uint16 auraBlue;
    }

    //Main mapping storing an ABCard for each token ID
    mapping(uint256 => ABCard) private ABTokenCollection;

    string[] cardNames = [
        // Angels
        'Berakiel',
        'Zadkiel',
        'Lucifer',
        'Michael',
        'Arel',
        'Raguel',
        'Lilith',
        'Furlac',
        'Azazel',
        'Eleleth',
        'Verin',
        'Ziwa',
        'Cimeriel',
        'Numinel',
        'Bat Gol',
        'Gabriel',
        'Metatron',
        'Rafael',
        'Melchezidek',
        'Semyaza',
        'Abbadon',
        'Baalzebub',
        'Ben Nez',
        'Jophiel',
        // Pets
        'Gecko',
        'Parakeet',
        'Kitten',
        'Horse',
        'Komodo',
        'Falcon',
        'Bobcat',
        'Unicorn',
        'Rock Dragon',
        'Archaeopteryx',
        'Sabertooth',
        'Pegasus',
        'Dire Dragon',
        'Phoeniz',
        'Liger',
        'Alicorn',
        'Fire Elemental',
        'Water Elemental',
        'Sun Elemental',
        // Accessories
        'Leather Bracers',
        'Metal Bracers',
        'Scholar Scroll',
        'Cosmic Scroll',
        '4 Leaf Clover',
        '7 Leaf Clover',
        'Red Collar',
        'Ruby Collar',
        'Yellow Collar',
        'Citrine Collar',
        'Blue Collar',
        'Sapphire Collar',
        'Carrots',
        'Cricket',
        'Bird Seed',
        'Cat Nip',
        'Lightning Rod',
        'Holy Light',
        // Medals
        '1 Ply Paper Towel',
        '2 Ply Paper Towel',
        'Cardboard',
        'Bronze',
        'Silver',
        'Gold',
        'Platinum',
        'Supid Fluffy Pink',
        'Orichalcum',
        'Diamond',
        'Titanium',
        'Zeronium'
    ];

    uint256[] public mintCostForCardSeries = [
        0, // Berakiel
        30000000000000000, // Zadkiel
        66600000000000000, // lucifer
        80000000000000000, // Michael
        3000000000000000, // Arel
        50000000000000000, // Raguel
        10000000000000000, // Lilith
        12500000000000000, // Furlac
        8000000000000000, // Azazel
        9000000000000000, // Eleleth
        7000000000000000, // Verin
        10000000000000000, // Ziwa
        12000000000000000, // Cimeriel
        14000000000000000, // Numinel
        20000000000000000, // Bat Gol
        25000000000000000, // Gabriel
        26500000000000000, // Metatron
        15000000000000000, // Rafael
        20000000000000000, // Melchezidek
        20000000000000000, // Semyaza
        30000000000000000, // Abbadon
        35000000000000000, // Baalzebub
        40000000000000000, // Ben Nez
        45000000000000000, // Jophiel
        0, // gecko
        0, // Parakeet
        5000000000000000, // Kitten
        5000000000000000, // Horse
        10000000000000000, // Komodo
        10000000000000000, // Falcon
        10000000000000000, // Bobcat
        10000000000000000, // Unicorn
        20000000000000000, // Rock Dragon
        20000000000000000, // Archaeopteryx
        20000000000000000, // Sabertooth
        20000000000000000, // Pegasus
        30000000000000000, // Dire Dragon
        30000000000000000, // Phoenix
        30000000000000000, // Liger
        30000000000000000, // Alicorn
        40000000000000000, // Fire Elemental
        40000000000000000, // Water Elemental
        40000000000000000, // Sun Elemental
        10000000000000000, // leather bracers
        20000000000000000, // Metal Bracers
        10000000000000000, // Scholars Scroll
        20000000000000000, // Cosmic Scroll
        10000000000000000, // 4 leaf clover
        20000000000000000, // 7 leaf clover
        10000000000000000, // Red Collar
        20000000000000000, // Ruby Collar
        10000000000000000, // Yellow Collar
        20000000000000000, // Citrine Collar
        10000000000000000, // Blue Collar
        20000000000000000, // Sapphire Collar
        10000000000000000, // Carrots
        10000000000000000, // Cricket
        10000000000000000, // Bird Seed
        10000000000000000, // Cat Nip
        10000000000000000, // Lightning Rod
        50000000000000000 // Holy Light
    ];

    uint16[] public remainingMintableSupplyForCardSeries = [
        56, // Berakiel -- ANGELS
        36, // zadkiel
        22, // lucifer
        22, // Michael
        42, // Arel
        38, // Raguel
        45, // Lilith
        44, // Furlac
        41, // Azazel
        39, // Eleleth
        44, // Verin
        44, // Ziwa
        57, // Cimeriel
        62, // Numinel
        30, // Bat Gol
        30, // Gabriel
        39, // Metatron
        31, // Rafael
        41, // Melchezidek
        37, // Semyaza
        40, // Abbadon
        41, // Baalzebub
        41, // Ben Nez
        39, // Jophiel
        132, // Gecko ---- PETS
        103, // Parakeet
        67, // Kitten
        68, // Horse
        140, // Komodo
        141, // Falcon
        144, // Bobcat
        124, // Unicorn
        144, // Rock Dragon
        105, // Archaeopteryx
        118, // Sabertooth
        102, // Pegasus
        68, // Dire Dragon
        75, // Phoenix
        56, // Liger
        68, // Alicorn
        49, // Fire Elemental
        50, // Water Elemental
        50, // Sun Elemental
        40, // Leather bracers ---- ACCESSORIES
        33, // Metal bracers
        62, // Scholar's scroll
        19, // Cosmic scroll
        75, // 4 leaf clover
        44, // 7 leaf clover
        75, // Red collar
        45, // Ruby collar
        74, // Yellow collar
        45, // Citrine collar
        75, // Blue collar
        43, // Sapphire collar
        74, // Carrots
        74, // Cricket
        74, // Bird Seed
        74, // Cat Nip
        72, // Lightning Rod
        30 // Holy Light
    ];

    constructor() {}

    function setIfpsGateway(string memory newGateway) public onlyCREATOR {
        ipfsGateway = newGateway;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            'ERC721: balance query for the zero address'
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            'ERC721: owner query for nonexistent token'
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                cardNames[
                                    ABTokenCollection[tokenId].cardSeriesId
                                ],
                                '", "description": "Angel Battles Card',
                                imageURI(tokenId),
                                getPower(tokenId),
                                getExp(tokenId),
                                getAura(tokenId),
                                getCreated(tokenId),
                                '"}]}'
                            )
                        )
                    )
                )
            );
    }

    function getPower(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '", "attributes": [{"trait_type": "Power", "value":"',
                    ABTokenCollection[tokenId].power.toString16()
                )
            );
    }

    function getExp(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"}, {"trait_type": "experience", "value":"',
                    ABTokenCollection[tokenId].experience.toString16()
                )
            );
    }

    function getAura(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"}, {"trait_type": "auraRed", "value":"',
                    ABTokenCollection[tokenId].auraRed.toString16(),
                    '"}, {"trait_type": "auraYellow", "value":"',
                    ABTokenCollection[tokenId].auraYellow.toString16(),
                    '"}, {"trait_type": "auraBlue", "value":"',
                    ABTokenCollection[tokenId].auraBlue.toString16()
                )
            );
    }

    function imageURI(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '", "image" :  "',
                    ipfsGateway,
                    'QmYHT1FKxYDfc1WUkWA4pkfjnh81SKESeMuSayot5MyEV7/',
                    ABTokenCollection[tokenId].cardSeriesId.toString16(),
                    '.png'
                )
            );
    }

    function getCreated(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"}, {"trait_type": "createdTime", "value":"',
                    ABTokenCollection[tokenId].createdTime.toString()
                )
            );
    }

    function buyCard(uint8 _cardSeries) public payable {
        require(
            msg.value >= mintCostForCardSeries[_cardSeries],
            'You must send at least the cost'
        );

        require(
            remainingMintableSupplyForCardSeries[_cardSeries] > 0,
            'That card is sold out'
        );

        remainingMintableSupplyForCardSeries[_cardSeries] -= 1;

        // Minting an angel
        if (_cardSeries < 24) {
            // mint the historical card. This contract will be the owner
            // ie, we are minting the wrapped version
            IAngelCardData AngelCardData = IAngelCardData(angelCardDataAddress);
            uint64 id = AngelCardData.setAngel(
                _cardSeries,
                address(this),
                msg.value,
                getAngelPower(_cardSeries)
            );

            uint8 aura;
            ABCard memory abCard;
            // Retrieve card information
            (
                ,
                abCard.cardSeriesId,
                abCard.power,
                aura,
                abCard.experience,
                ,
                abCard.createdTime,
                ,
                ,
                ,

            ) = AngelCardData.getAngel(id);

            // mint the 721 card
            AuraMapping memory auraMapping = getAngelAuraMapping(aura);

            // Mint a new card with the same stats
            mintABToken(
                msg.sender,
                abCard.cardSeriesId,
                abCard.power,
                auraMapping.auraRed,
                auraMapping.auraYellow,
                auraMapping.auraBlue,
                '',
                abCard.experience,
                uint16(id),
                abCard.createdTime
            );
        }

        if (_cardSeries > 23 && _cardSeries < 43) {
            // mint the historical card
            IPetCardData PetCardData = IPetCardData(petCardDataAddress);
            uint64 id = PetCardData.setPet(
                _cardSeries - 23,
                address(this),
                '',
                getPetPower(_cardSeries),
                1,
                1,
                1
            );

            // Mint a new card with the same stats for the owner
            mintABToken(
                msg.sender,
                _cardSeries,
                getPetPower(_cardSeries),
                1,
                1,
                1,
                '',
                0,
                uint16(id),
                0
            );
        }

        if (_cardSeries > 43) {
            // mint the wrapped historical card
            IAccessoryData AccessoryCardData = IAccessoryData(
                accessoryCardDataAddress
            );
            uint64 id = AccessoryCardData.setAccessory(
                _cardSeries - 43,
                address(this)
            );

            // mint the 721 card
            mintABToken(
                msg.sender,
                _cardSeries,
                0,
                0,
                0,
                0,
                '',
                0,
                uint16(id),
                0
            );
        }

        paymentSplitter.transfer(msg.value);
    }

    function getRandomNumber(
        uint16 maxRandom,
        uint8 min,
        address privateAddress
    ) public view returns (uint8) {
        uint256 genNum = uint256(
            keccak256(abi.encodePacked(block.timestamp, privateAddress))
        );
        return uint8((genNum % (maxRandom - min + 1)) + min);
    }

    function getPetPower(uint8 _petSeriesId) private view returns (uint8) {
        uint8 randomPower = getRandomNumber(10, 0, msg.sender);
        if (_petSeriesId < 28) {
            return (10 + randomPower);
        }
        if (_petSeriesId < 32) {
            return (20 + randomPower);
        }

        if (_petSeriesId < 36) {
            return (30 + randomPower);
        }

        if (_petSeriesId < 40) {
            return (40 + randomPower);
        }

        return (50 + randomPower);
    }

    function getAngelPower(uint8 _angelSeriesId) private view returns (uint16) {
        uint8 randomPower = getRandomNumber(10, 0, msg.sender);
        if (_angelSeriesId >= 4) {
            return
                uint16(100 + 10 * (uint16(_angelSeriesId) - 4) + randomPower);
        }
        if (_angelSeriesId == 0) {
            return (50 + randomPower);
        }
        if (_angelSeriesId == 1) {
            return (120 + randomPower);
        }
        if (_angelSeriesId == 2) {
            return (250 + randomPower);
        }
        if (_angelSeriesId == 3) {
            return (300 + randomPower);
        }
        return 1;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, 'ERC721: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721: approve caller is not owner nor approved for all'
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            'ERC721: approved query for nonexistent token'
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: transfer caller is not owner nor approved'
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: transfer caller is not owner nor approved'
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            'ERC721: operator query for nonexistent token'
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), 'ERC721: mint to the zero address');
        require(!_exists(tokenId), 'ERC721: token already minted');

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        addABTokenIdMapping(to, tokenId);
        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            'ERC721: transfer from incorrect owner'
        );
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        addABTokenIdMapping(to, tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, 'ERC721: approve to caller');
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        'ERC721: transfer to non ERC721Receiver implementer'
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    // Functions to wrap a historical NFT.
    // Only the owner of a card may wrap it
    // Wrapping does not destroy the original NFT
    // It can be unwrapped by the owner at any time.

    function wrapAngel(uint64 _angelId) public {
        ABCard memory abCard;
        address owner;

        uint8 aura;

        // Retrieve card information
        IAngelCardData AngelCardData = IAngelCardData(angelCardDataAddress);
        (
            ,
            abCard.cardSeriesId,
            abCard.power,
            aura,
            abCard.experience,
            ,
            abCard.createdTime,
            ,
            ,
            ,
            owner
        ) = AngelCardData.getAngel(_angelId);

        // make sure the msg.sender is the owner
        require(owner == msg.sender, 'Only the owner may wrap');

        // Make sure the card is unlocked
        require(
            AngelCardData.getAngelLockStatus(_angelId) == false,
            'The card must be unlocked first'
        );

        // Transfer ownership of the original card to this contract
        AngelCardData.transferAngel(msg.sender, address(this), _angelId);

        AuraMapping memory auraMapping = getAngelAuraMapping(aura);

        // Mint a new card with the same stats
        mintABToken(
            msg.sender,
            abCard.cardSeriesId,
            abCard.power,
            auraMapping.auraRed,
            auraMapping.auraYellow,
            auraMapping.auraBlue,
            '',
            abCard.experience,
            uint16(_angelId),
            abCard.createdTime
        );
    }

    function getAngelAuraMapping(uint8 aura)
        internal
        pure
        returns (AuraMapping memory auraMapping)
    {
        if (aura == 2 || aura == 3 || aura == 4) {
            auraMapping.auraRed = 1;
        }
        if (aura == 1 || aura == 3 || aura == 5) {
            auraMapping.auraYellow = 1;
        }
        if (aura == 0 || aura == 2 || aura == 5) {
            auraMapping.auraBlue = 1;
        }
    }

    function wrapPet(uint256 _petId) public {
        // Retrieve card information
        IPetCardData PetCardData = IPetCardData(petCardDataAddress);
        ABCard memory abCard;
        address owner;

        (
            ,
            abCard.cardSeriesId,
            ,
            abCard.power,
            abCard.auraRed,
            abCard.auraBlue,
            abCard.auraYellow,
            ,
            ,
            owner
        ) = PetCardData.getPet(_petId);

        // make sure the msg.sender is the owner
        require(owner == msg.sender, 'Only the owner may wrap');

        // Transfer ownership of the original card to this contract
        PetCardData.transferPet(msg.sender, address(this), uint16(_petId));

        // Mint a new card with the same stats
        mintABToken(
            owner,
            abCard.cardSeriesId + 23,
            abCard.power,
            abCard.auraRed,
            abCard.auraYellow,
            abCard.auraBlue,
            '',
            0,
            uint16(_petId),
            0
        );
    }

    function getPetCreatedTime(uint64 lastTrainingTime, uint64 lastBreedingTime)
        public
        pure
        returns (uint64)
    {
        // Pet cards do not have a createdTime recorded
        // Therefore, createdTime will be 0 if the pet has never trained or bred
        // Otherwise, it will be the earliest of last training time or last breeding time.

        if (lastTrainingTime < lastBreedingTime && lastTrainingTime > 0) {
            return lastTrainingTime;
        }

        if (lastBreedingTime < lastTrainingTime && lastBreedingTime > 0) {
            return lastTrainingTime;
        }
        return 0;
    }

    function wrapAccessory(uint256 _accessoryId) public {
        // Retrieve card information
        IAccessoryData AccessoryCardData = IAccessoryData(
            accessoryCardDataAddress
        );

        (, uint8 accessoryCardSeriesId, address owner) = AccessoryCardData
            .getAccessory(_accessoryId);

        // make sure the msg.sender is the owner
        require(owner == msg.sender, 'Only the owner may wrap');

        // Make sure the card is unlocked
        require(
            AccessoryCardData.getAccessoryLockStatus(uint64(_accessoryId)) ==
                false,
            'The card must be unlocked first'
        );

        // Transfer ownership of the original card to this contract
        AccessoryCardData.transferAccessory(
            msg.sender,
            address(this),
            uint64(_accessoryId)
        );

        // Mint a new card with the same stats
        mintABToken(
            msg.sender,
            accessoryCardSeriesId + 42,
            0,
            0,
            0,
            0,
            '',
            0,
            uint16(_accessoryId),
            0
        );
    }

    // Function to unwrap a historical NFT.
    // Only the owner of a card may unwrap it
    // unwrapping destroys the new nft and transfers the historical one
    // unwrapped cards may be re-wraped at any time

    // unwrapped angels and accessories have lockStatus = false. This means that they can only be
    // accessed by seraphim contracts. Users can lock their cards again if they wish.

    function unwrap(uint256 cardId) public {
        // make sure the msg.sender is the owner
        require(ownerOf(cardId) == msg.sender, 'Only the owner may unwrap');

        // destroy the current card
        _burn(cardId);
        // transfer ownership of the historical card back to msg.sender

        // Angel Card
        if (ABTokenCollection[cardId].cardSeriesId < 24) {
            IAngelCardData AngelCardData = IAngelCardData(angelCardDataAddress);

            AngelCardData.ownerAngelTransfer(
                msg.sender,
                ABTokenCollection[cardId].oldId
            );
        }
        // Pet Card
        else if (ABTokenCollection[cardId].cardSeriesId < 43) {
            IPetCardData PetCardData = IPetCardData(petCardDataAddress);
            PetCardData.transferPet(
                address(this),
                msg.sender,
                ABTokenCollection[cardId].oldId
            );
        }
        // Accessory Card
        else if (ABTokenCollection[cardId].cardSeriesId < 61) {
            IAccessoryData AccessoryCardData = IAccessoryData(
                accessoryCardDataAddress
            );
            AccessoryCardData.ownerAccessoryTransfer(
                msg.sender,
                ABTokenCollection[cardId].oldId
            );
        }
    }

    function mintABToken(
        address owner,
        uint8 _cardSeriesId,
        uint16 _power,
        uint16 _auraRed,
        uint16 _auraYellow,
        uint16 _auraBlue,
        string memory cardName,
        uint16 _experience,
        uint16 oldId,
        uint64 createdTime
    ) internal {
        ABCard storage abcard = ABTokenCollection[totalSupply];
        abcard.power = _power;
        abcard.cardSeriesId = _cardSeriesId;
        abcard.auraRed = _auraRed;
        abcard.auraYellow = _auraYellow;
        abcard.auraBlue = _auraBlue;
        abcard.name = cardName;
        abcard.experience = _experience;
        abcard.tokenId = totalSupply;
        abcard.createdTime = createdTime;
        abcard.oldId = oldId;
        _mint(owner, totalSupply);
        totalSupply = totalSupply + 1;
        currentTokenNumbers[_cardSeriesId]++;
    }

    // When minting a wrapped token, two tokens are minted, a historical and a wrapped one
    // the historical token is owned by this contract.

    function addABTokenIdMapping(address _owner, uint256 _tokenId) private {
        uint256[] storage owners = ownerABTokenCollection[_owner];
        owners.push(_tokenId);
    }

    function getCurrentTokenNumbers(uint8 _cardSeriesId)
        public
        view
        returns (uint32)
    {
        return currentTokenNumbers[_cardSeriesId];
    }

    function getABToken(uint256 tokenId)
        public
        view
        returns (
            uint8 cardSeriesId,
            uint16 power,
            uint16 auraRed,
            uint16 auraYellow,
            uint16 auraBlue,
            string memory cardName,
            uint16 experience,
            uint64 lastBattleTime,
            uint64 createdTime,
            address owner
        )
    {
        ABCard memory abcard = ABTokenCollection[tokenId];
        cardSeriesId = abcard.cardSeriesId;
        power = abcard.power;
        experience = abcard.experience;
        auraRed = abcard.auraRed;
        auraBlue = abcard.auraBlue;
        auraYellow = abcard.auraYellow;
        cardName = abcard.name;
        lastBattleTime = abcard.lastBattleTime;
        createdTime = abcard.createdTime;
        owner = ownerOf(tokenId);
    }

    function setName(uint256 tokenId, string memory namechange) public {
        ABCard storage abcard = ABTokenCollection[tokenId];
        if (msg.sender != ownerOf(tokenId)) {
            revert();
        }
        if (abcard.tokenId == tokenId) {
            abcard.name = namechange;
        }
    }

    function getABTokenByIndex(address _owner, uint64 _index)
        external
        view
        returns (uint256)
    {
        if (_index >= ownerABTokenCollection[_owner].length) {
            return 0;
        }
        return ownerABTokenCollection[_owner][_index];
    }
}