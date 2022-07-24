/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract IECWolves is Context, ERC165, IERC721, IERC721Metadata, Ownable {

    using Address for address;
    using SafeMath for uint256;

    // Token name
    string private constant _name = "IEC Wolves";

    // Token symbol
    string private constant _symbol = "IEC WOLVES";

    // total number of NFTs Minted
    uint256 public _totalSupply;

    // max supply cap
    uint256 public MAX_SUPPLY = 10_000;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from tokenID to excluded rewards
    mapping(uint256 => uint256) private totalExcluded;

    // total dividends percentage denominator
    uint256 private constant percentageDenom = 10000;

    // total rewards received
    uint256 public totalRewards;

    // precision factor
    uint256 private PRECISION = 10**18;

    /**
        Mapping From tokenID to Rank
        Rank 0 = Bronze
        Rank 1 = Silver
        Rank 2 = Gold
        Rank 3 = Executive
        Rank 4 = VIP
     */
    mapping ( uint256 => uint256 ) public getRank;

    // Ranks
    struct Rank {
        uint256 total;
        uint256 max;
        uint256 cost;
        uint256 dividends;
        uint256 dividendPercentage;
    }
    mapping ( uint256 => Rank ) public ranks;

    // Max rank
    uint256 public constant MAX_RANK = 4;

    // Payment Recipient
    address payable public paymentReceiver;

    // max holdings per wallet post mint
    uint256 private constant MAX_HOLDINGS = 25;

    // Merkle Proof Root For White list
    bytes32 public merkleRoot;

    // cost for minting NFT
    uint256 public cost = 10**18;

    // base URI
    string private baseURI = "https://opensea.mypinata.cloud/ipfs/Qma54XdskCs7yKRJPwZeAeJsRfC1eKHTkejTE9WFYBGjkr";
    string private ending = "";

    // Reward Token
    IERC20 public token;

    // Enable Trading
    bool public tradingEnabled = false;
    bool public massRankUpgradeEnabled = true;
    bool public whitelistEnabled = true;

    constructor(address payable paymentReceiver_){
        ranks[0] = Rank({
            total: 0,
            max: 10000,
            cost: 0,
            dividends: 0,
            dividendPercentage: 1250
        });
        ranks[1] = Rank({
            total: 0,
            max: 3000,
            cost: 10**17,
            dividends: 0,
            dividendPercentage: 1875
        });
        ranks[2] = Rank({
            total: 0,
            max: 1500,
            cost: 2 * 10**17,
            dividends: 0,
            dividendPercentage: 1875
        });
        ranks[3] = Rank({
            total: 0,
            max: 1000,
            cost: 4 * 10**17,
            dividends: 0,
            dividendPercentage: 2500
        });
        ranks[4] = Rank({
            total: 0,
            max: 500,
            cost: 8 * 10**17,
            dividends: 0,
            dividendPercentage: 2500
        });

        paymentReceiver = paymentReceiver_;
    }


    ////////////////////////////////////////////////
    ///////////   RESTRICTED FUNCTIONS   ///////////
    ////////////////////////////////////////////////

    function massUpgrade(uint256[] calldata tokenIds, uint256[] calldata newRanks) external onlyOwner {
        require(
            massRankUpgradeEnabled,
            'D'
        );
        
        uint length = tokenIds.length;
        require(length == newRanks.length, 'M');

        for (uint i = 0; i < length;) {
            require(
                getRank[tokenIds[i]] == 0 && newRanks[i] > 0,
                'F'
            );
            getRank[tokenIds[i]] = newRanks[i];
            ranks[newRanks[i]].total++;
            ranks[0].total--;
            totalExcluded[tokenIds[i]] = getCumulativeDividends(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function setRewardToken(address token_) external onlyOwner {
        token = IERC20(token_);
    }

    function disableMassRankUpgrades() external onlyOwner {
        massRankUpgradeEnabled = false;
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function disableTrading() external onlyOwner {
        tradingEnabled = false;
    }

    function disableWhitelist() external onlyOwner {
        whitelistEnabled = false;
    }

    function withdraw() external onlyOwner {
        (bool s,) = payable(paymentReceiver).call{value: address(this).balance}("");
        require(s);
    }

    function withdrawToken(address token_) external onlyOwner {
        require(token_ != address(token), 'Cannot withdraw IEC Tokens');
        IERC20(token_).transfer(msg.sender, IERC20(token_).balanceOf(address(this)));
    }

    function setCost(uint256 newCost) external onlyOwner {
        cost = newCost;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setURIExtention(string calldata newExtention) external onlyOwner {
        ending = newExtention;
    }

    function setPaymentReceiver(address payable newReceiver) external onlyOwner {
        paymentReceiver = newReceiver;
    }

    function setUpgradeCost(uint256 rank, uint256 newCost) external onlyOwner {
        require(
            rank < MAX_RANK,
            'Max rank'
        );
        ranks[rank].cost = newCost;
    }

    function setRewardDistribution(
        uint bronzeP,
        uint silverP,
        uint goldP,
        uint execP,
        uint vipP
    ) external onlyOwner {
        require(
            bronzeP + silverP + goldP + execP + vipP == percentageDenom,
            'Invalid Percentages'
        );
        ranks[0].dividendPercentage = bronzeP;
        ranks[1].dividendPercentage = silverP;
        ranks[2].dividendPercentage = goldP;
        ranks[3].dividendPercentage = execP;
        ranks[4].dividendPercentage = vipP;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function capCollectionAtSupply() external onlyOwner {
        MAX_SUPPLY = _totalSupply;
    }

    ////////////////////////////////////////////////
    ///////////     PUBLIC FUNCTIONS     ///////////
    ////////////////////////////////////////////////


    function upgrade(uint256 tokenId, uint256 newRank) external payable {
        require(
            !massRankUpgradeEnabled,
            'Mass Rank Upgrades Are Still Enabled'
        );
        require(
            _isApprovedOrOwner(_msgSender(), tokenId), 
            "Caller Not Owner Nor Approved"
        );
        require(
            newRank <= MAX_RANK,
            'Max Rank Exceeded'
        );
        // current token rank
        uint currentRank = getRank[tokenId];
        require(
            currentRank < newRank,
            'Cannot Rank Backwards'
        );
        require(
            ranks[newRank].total < ranks[newRank].max,
            'Max NFTs In Rank'
        );

        // calculate cost to upgrade
        uint costToUpgrade = 0;
        for (uint i = currentRank; i < newRank; i++) {
            costToUpgrade += ranks[i + 1].cost;
        }
        require(
            msg.value >= costToUpgrade,
            'Insufficient Value Sent'
        );

        // claim pending rewards for token ID
        _claimRewards(_msgSender(), tokenId);

        // decrement old rank total
        ranks[currentRank].total--;

        // increment new rank total
        ranks[newRank].total++;

        // increment tokenId Rank
        getRank[tokenId] = newRank;

        // reset total excluded for new rank
        totalExcluded[tokenId] = getCumulativeDividends(tokenId);
    }

    /** 
     * Mints `numberOfMints` NFTs To Caller
     */
    function mint(uint256 numberOfMints) external payable {
        require(
            tradingEnabled,
            'Trading Not Enabled'
        );
        require(
            !whitelistEnabled,
            'White list is enabled'
        );

        require(numberOfMints > 0, 'Invalid Input');
        require(cost * numberOfMints <= msg.value, 'Incorrect Value Sent');

        for (uint i = 0; i < numberOfMints; i++) {
            _safeMint(msg.sender, _totalSupply);
        }

        require(
            _balances[msg.sender] <= MAX_HOLDINGS,
            'Max Holdings Exceeded'
        );
    }

    /** 
     * Mints `numberOfMints` NFTs To Caller if Caller is whitelisted
     */
    function whitelistMint(uint256 numberOfMints, bytes32[] calldata proof) external payable {
        require(
            tradingEnabled,
            'Trading Not Enabled'
        );
        require(
            whitelistEnabled,
            'White list is disabled'
        );
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                toBytes32(_msgSender())
            ) == true,
            "User Is Not Whitelisted"
        );

        require(numberOfMints > 0, 'Invalid Input');
        require(cost * numberOfMints <= msg.value, 'Incorrect Value Sent');

        for (uint i = 0; i < numberOfMints; i++) {
            _safeMint(msg.sender, _totalSupply);
        }

        require(
            _balances[msg.sender] <= MAX_HOLDINGS,
            'Max Holdings Exceeded'
        );
        
    }

    function batchClaim(uint256[] calldata tokenIds) external {
        
        // define length prior to save gas
        uint length = tokenIds.length;
        require(
            length > 0,
            'Zero Length'
        );

        // save gas by declaring early
        uint totalPending = 0;
        uint currentID = 0;
        address sender = _msgSender();

        // loop through IDs, accruing pending rewards and resetting pending rewards
        for (uint i = 0; i < length;) {
            // current ID in list
            currentID = tokenIds[i];
            // require ID is owned by sender
            require(_isApprovedOrOwner(sender, currentID), "caller not owner nor approved");
            // add value to total pending
            totalPending += pendingRewards(currentID);
            // reset total excluded - resetting rewards
            totalExcluded[currentID] = getCumulativeDividends(currentID);
            // increment loop
            unchecked { ++i; }
        }

        // total available balance
        uint bal = token.balanceOf(address(this));

        // avoid round off error
        if (totalPending > bal) {
            totalPending = bal;
        }

        // return if no rewards
        if (totalPending == 0) {
            return;
        }

        // transfer reward to user
        require(
            token.transfer(sender, totalPending),
            'Failure On Token Transfer'
        );
    }

    function claimRewards(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller not owner nor approved");
        _claimRewards(_owners[tokenId], tokenId);
    }

    function giveRewards(uint amount) external {
        if (massRankUpgradeEnabled) {
            return;
        }

        // transfer in rewards
        uint before = token.balanceOf(address(this));
        require(
            token.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Failure On Token Transfer'
        );
        uint After = token.balanceOf(address(this));
        // ensure tokens were received
        require(
            After > before,
            'Zero Received'
        );
        uint received = After - before;

        // increment total rewards
        totalRewards += received;

        // fetch distributions
        (uint bp, uint sp, uint gp, uint ep, uint vp) = _fetchDistributionPercentages();

        // roll over if zero
        if (ranks[4].total == 0) {
            bp += vp / 4;
            sp += vp / 4;
            gp += vp / 4;
            ep += vp / 4;
            vp = 0;
        }
        if (ranks[3].total == 0) {
            bp += ep / 3;
            sp += ep / 3;
            gp += ep / 3;
            ep = 0;
        }
        if (ranks[2].total == 0) {
            bp += gp / 2;
            sp += gp / 2;
            gp = 0;
        }
        if (ranks[1].total == 0) {
            bp += sp;
            sp = 0;
        }

        // split up amounts for each sector
        uint forBronze = received.mul(bp).div(percentageDenom);
        uint forSilver = received.mul(sp).div(percentageDenom);
        uint forGold = received.mul(gp).div(percentageDenom);
        uint forExec = received.mul(ep).div(percentageDenom);
        uint forVIP = received.mul(vp).div(percentageDenom);

        // Increment Dividend Rewards
        if (ranks[4].total > 0) {
            ranks[4].dividends += forVIP.mul(PRECISION).div(ranks[4].total);
        }
        if (ranks[3].total > 0) {
            ranks[3].dividends += forExec.mul(PRECISION).div(ranks[3].total);
        }
        if (ranks[2].total > 0) {
            ranks[2].dividends += forGold.mul(PRECISION).div(ranks[2].total);
        }
        if (ranks[1].total > 0) {
            ranks[1].dividends += forSilver.mul(PRECISION).div(ranks[1].total);
        }
        if (ranks[0].total > 0) {
            ranks[0].dividends += forBronze.mul(PRECISION).div(ranks[0].total);
        }
        
    }

    function _fetchDistributionPercentages() internal view returns (uint, uint, uint, uint, uint) {
        return (
            ranks[0].dividendPercentage, 
            ranks[1].dividendPercentage, 
            ranks[2].dividendPercentage,
            ranks[3].dividendPercentage,
            ranks[4].dividendPercentage
        );
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    receive() external payable {}

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address wpowner = ownerOf(tokenId);
        require(to != wpowner, "ERC721: approval to current owner");

        require(
            _msgSender() == wpowner || isApprovedForAll(wpowner, _msgSender()),
            "ERC721: not approved or owner"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address _operator, bool approved) public override {
        _setApprovalForAll(_msgSender(), _operator, approved);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    ////////////////////////////////////////////////
    ///////////     READ FUNCTIONS       ///////////
    ////////////////////////////////////////////////

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function getIDsByOwner(address owner) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](balanceOf(owner));
        if (owner == address(0)) { return ids; }
        if (balanceOf(owner) == 0) { return ids; }
        uint256 count = 0;
        for (uint i = 0; i < _totalSupply;) {
            if (_owners[i] == owner) {
                ids[count] = i;
                count++;
            }
            unchecked { ++i; }
        }
        return ids;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address wpowner) public view override returns (uint256) {
        require(wpowner != address(0), "query for the zero address");
        return _balances[wpowner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address wpowner = _owners[tokenId];
        require(wpowner != address(0), "query for nonexistent token");
        return wpowner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");

        string memory fHalf = string.concat(baseURI, uint2str(getRank[tokenId]));
        string memory sHalf = string.concat(fHalf, '-');
        string memory tHalf = string.concat(sHalf, uint2str(tokenId));
        return string.concat(tHalf, ending);
    }

    /**
        Converts A Uint Into a String
    */
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address wpowner, address _operator) public view override returns (bool) {
        return _operatorApprovals[wpowner][_operator];
    }

    /**
        Pending IEC Rewards For `tokenId`
     */
    function pendingRewards(uint256 tokenId) public view returns (uint256) {

        uint256 tokenIDDividends = getCumulativeDividends(tokenId);
        uint256 tokenIDExcluded = totalExcluded[tokenId];

        if(tokenIDDividends <= tokenIDExcluded){ return 0; }

        return tokenIDDividends - tokenIDExcluded;
    }

    /**
        Cumulative Dividends For A Number Of Tokens
     */
    function getCumulativeDividends(uint256 tokenId) internal view returns (uint256) {
        return ranks[getRank[tokenId]].dividends.div(PRECISION);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        address wpowner = ownerOf(tokenId);
        return (spender == wpowner || getApproved(tokenId) == spender || isApprovedForAll(wpowner, spender));
    }

    ////////////////////////////////////////////////
    ///////////    INTERNAL FUNCTIONS    ///////////
    ////////////////////////////////////////////////


    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
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
    function _mint(address to, uint256 tokenId) internal {
        require(!_exists(tokenId), "ERC721: token already minted");
        require(_totalSupply < MAX_SUPPLY, 'All NFTs Have Been Minted');

        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply += 1;
        ranks[0].total++;
        totalExcluded[tokenId] = getCumulativeDividends(tokenId);

        emit Transfer(address(0), to, tokenId);
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
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: non ERC721Receiver implementer");
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
    ) internal {
        require(ownerOf(tokenId) == from, "Incorrect owner");
        require(to != address(0), "zero address");
        require(balanceOf(from) > 0, 'Zero Balance');

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        // claim rewards for tokenId
        _claimRewards(from, tokenId);

        // Allocate balances
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        // emit transfer
        emit Transfer(from, to, tokenId);
    }

    /**
        Claims IEC Reward For User
     */
    function _claimRewards(address owner, uint256 tokenId) internal {

        // fetch pending rewards
        uint pending = pendingRewards(tokenId);
        uint bal = token.balanceOf(address(this));

        // avoid round off error
        if (pending > bal) {
            pending = bal;
        }

        // return if no rewards
        if (pending == 0) {
            return;
        }
        
        // reset total rewards
        totalExcluded[tokenId] = getCumulativeDividends(tokenId);

        // transfer reward to user
        require(
            token.transfer(owner, pending),
            'Failure On Token Transfer'
        );
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address wpowner,
        address _operator,
        bool approved
    ) internal {
        require(wpowner != _operator, "ERC721: approve to caller");
        _operatorApprovals[wpowner][_operator] = approved;
        emit ApprovalForAll(wpowner, _operator, approved);
    }

    function onReceivedRetval() public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: non ERC721Receiver implementer");
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
}