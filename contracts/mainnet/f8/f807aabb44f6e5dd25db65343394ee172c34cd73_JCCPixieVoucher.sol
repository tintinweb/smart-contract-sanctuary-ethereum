/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: contracts/MerkleProof.sol



pragma solidity ^0.8.9;


/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */

    using Strings for uint256;

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(i.toString(), computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(i.toString(), proofElement, computedHash));
            }
        }
        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
    
}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        require(isContract(target), "Address: delegate call to non-contract");

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// File: contracts/PublicPrivateVoucherMinter.sol



pragma solidity ^0.8.9;






abstract contract PublicPrivateVoucherMinter is Ownable {    

    // event to log mint detail
    event MinterCreated(address _address);
    event PublicMint (address _address, uint256 _amount, uint256 _value);
    event PrivateMint(address _address, uint256 id, uint256 _amount, uint256 _value);
    event VoucherMint(address _address, uint256 id, uint256 _amount, uint256 _value);
    event ProjectMint(address _address, uint256 _amount, string _reason);


    struct MinterConfig {
        bool isPublicMintActive;       // can call publicMint only when isPublicMintActive is true
        bool isPrivateMintActive;      // can call privateMint only when isPrivateMintActive is true
        bool isVoucherMintActive;      // can call voucherMint only when isVoucherMintActive is true
        uint256 publicMintPrice;       // price for publicMint
        uint256 privateMintPrice;      // price for privateMint
        uint256 maxPublicMintAmount;   // maximum amount per publicMint transaction
        uint256 maxPrivateMintAmount;  // maximum amount per privateMint transaction    
        uint256 maxTotalSupply;        // maximum supply
        uint256 maxPrivateMintSupply;  // maximum supply for private round    
    }
              
    // Sale counter
    uint256 public totalPublicSold;
    uint256 public totalPrivateSold;    
    uint256 public totalVoucherClaimed;
    uint256 public totalVoucherIssued;
    uint256 public totalProjectMint;

    address public beneficiary;
    
    bytes32 private _merkleRoot;
    uint256 private _proofLength;
    
    // a mapping from voucher/whitelised Id to the amount used
    mapping(uint256 => uint256) private _amountUsed;  
    
    // Operator
    address private _operator; // address of operator who can set parameter of this contract
        
    MinterConfig public minterConfig;

    constructor (MinterConfig memory config, address payable _beneficiary) {
        setMinterConfig(config);
        setBeneficiary(_beneficiary);  
        setOperator(_msgSender());      
    }

    function setMinterConfig(MinterConfig memory config) public onlyOwner {        
        minterConfig = config;
    }

    /// @notice Recipient of revenues
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        require(_beneficiary != address(0), "Not the zero address");
        beneficiary = _beneficiary;
    }

    /** 
    @dev Called by after all limited have been put in place; must perform all contract-specific sale logic, e.g.
    ERC721 minting.
    @param to The recipient of the item(s).
    @param amount The number of items allowed to be purchased
    **/
    function _mintTo(address to, uint256 amount) internal virtual;

    function toggleZeroPublicMintActive() external onlyOwnerAndOperator {        
        minterConfig.isPublicMintActive = !minterConfig.isPublicMintActive;
    }

    function toggleZeroPrivateMintActive() external onlyOwnerAndOperator {        
        minterConfig.isPrivateMintActive = !minterConfig.isPrivateMintActive;
    }

    function togglePublicMintActive() external onlyOwnerAndOperator {
        require (minterConfig.publicMintPrice > 0, "Public Mint Price is zero");
        minterConfig.isPublicMintActive = !minterConfig.isPublicMintActive;
    }

    function togglePrivateMintActive() external onlyOwnerAndOperator {
        require (minterConfig.privateMintPrice > 0, "Private Mint Price is zero");
        minterConfig.isPrivateMintActive = !minterConfig.isPrivateMintActive;
    }

    function toggleVoucherMintActive() external onlyOwnerAndOperator {
        minterConfig.isVoucherMintActive = !minterConfig.isVoucherMintActive;
    }

    function totalSold() external view returns (uint256) {
        return totalPublicSold + totalPrivateSold + totalVoucherClaimed;
    }

    // set maxTotalSupply
    function setMaxTotalSupply(uint256 supply) external onlyOwnerAndOperator {
        minterConfig.maxTotalSupply = supply;
    }

    // set parameter for public mint 
    function setPublicMintDetail(uint256 price, uint256 amount) external onlyOwnerAndOperator {
        require(!minterConfig.isPublicMintActive, "Public mint is active");
        minterConfig.publicMintPrice = price;
        minterConfig.maxPublicMintAmount = amount;        
    }

    // set parameter for private mint
    function setPrivateMintDetail(uint256 price, uint256 amount, uint256 supply) external onlyOwnerAndOperator {
        require(!minterConfig.isPrivateMintActive, "Private mint is active");
        minterConfig.privateMintPrice = price;
        minterConfig.maxPrivateMintAmount = amount;
        minterConfig.maxPrivateMintSupply = supply;
    }

    // set parameter for voucher/private mint
    function setVoucherDetail(bytes32 merkleRoot, uint256 proofLength, uint256 voucherAmount) external onlyOwnerAndOperator {
        _merkleRoot = merkleRoot;
        _proofLength = proofLength;
        totalVoucherIssued = voucherAmount;
    }

    function publicMint(uint256 amount) public payable {
        require(minterConfig.isPublicMintActive,"Public mint is closed");
        require(amount > 0,"Amount is zero");
        require(amount <= minterConfig.maxPublicMintAmount,"Amount is greater than maximum");        
        require(totalProjectMint + totalPublicSold + totalPrivateSold + totalVoucherIssued + amount <= minterConfig.maxTotalSupply,"Exceed maxTotalSupply");
        require(minterConfig.publicMintPrice * amount <= msg.value, "Insufficient fund");
        
        address to = _msgSender();

        _mintTo(to, amount);        
        totalPublicSold += amount;        
        emit PublicMint(to, amount, msg.value);
    }

    function privateMint( uint256 amount,    
                          uint256 whitelistedId, uint256 whitelistedAmount, bytes32[] calldata proof ) public payable {

        require(minterConfig.isPrivateMintActive,"Private mint is closed");

        address to = _msgSender();
        bytes32 hash = keccak256(abi.encodePacked(whitelistedId, address(this), 'W',  to, whitelistedAmount));
        require(proof.length == _proofLength,"Invalid whitelisted detail");
        require(MerkleProof.verify(proof, _merkleRoot, hash),"Invalid whitelisted detail");
        require(_amountUsed[whitelistedId] == 0, "Whielisted has been used");                
        if (whitelistedAmount == 0) {            
            require(amount <= minterConfig.maxPrivateMintAmount,"Amount is greater than maximum");                            
        } else {
            require(amount <= whitelistedAmount,"Amount is greater than maximum");                            
        }
        require(amount > 0,"Amount is zero");
        require(totalPrivateSold + amount <= minterConfig.maxPrivateMintSupply,"Exceed maxPrivateMintSupply");
        require(minterConfig.privateMintPrice * amount <= msg.value, "Insufficient fund");

        _mintTo(to, amount);                

        _amountUsed[whitelistedId] = amount;
        totalPrivateSold += amount;  
        emit PrivateMint(to, whitelistedId, amount, msg.value);   
    }

    function voucherMint( uint256 amount,
                          uint256 voucherId, uint256 voucherAmount, uint256 voucherPrice, bytes32[] calldata proof) public payable {

        require(minterConfig.isVoucherMintActive,"Voucher mint is closed");

        address to = _msgSender();
        bytes32 hash = keccak256(abi.encodePacked(voucherId, address(this), 'V',  to, voucherAmount, voucherPrice));        
        require(proof.length == _proofLength,"Invalid whitelisted detail");
        require(MerkleProof.verify(proof, _merkleRoot, hash),"Invalid voucher detail");        
        require(_amountUsed[voucherId] + amount <= voucherAmount,"Ammount is greater than voucher");                                
        require(amount > 0,"Amount is zero");        
        require(voucherPrice * amount <= msg.value, "Insufficient fund");        

        _mintTo(to, amount);        

        _amountUsed[voucherId] += amount;        
        totalVoucherClaimed += amount;        
        emit VoucherMint(to, voucherId, amount, msg.value);       
    }

    function _projectMint(address to, uint256 amount, string memory reason) internal {
        _mintTo(to, amount);
        totalProjectMint += amount;
        emit ProjectMint(to, amount, reason);
    }    

    function getAmountUsed(uint256 voucherId) external view returns (uint256) {
        return _amountUsed[voucherId];
    }

    //////////////////////////////////////////////////////////////////////////////////////
    // Function to withdraw fund from contract
    /////
    function withdraw() external onlyOwner {        
        uint256 _balance = address(this).balance;        
        Address.sendValue(payable(beneficiary), _balance);
    }    

    function withdraw(uint256 balance) external onlyOwner {                    
        Address.sendValue(payable(beneficiary), balance);
    }    

    function transferERC20(IERC20 token) external onlyOwner {        
        uint256 balance = token.balanceOf(address(this));
        token.transfer(beneficiary, balance);        
    }        

    function transferERC20(IERC20 token, uint256 amount) external onlyOwner {        
        token.transfer(beneficiary, amount);        
    }        

    function donate() external payable {
        // thank you
    }

    // set Operator
    function setOperator(address operator) public onlyOwner {
        require(operator != address(0), "Not the zero address");
        _operator = operator;
    }

    function minterStatus() public view returns (
        bool isPublicMintActive_,
        bool isPrivateMintActive_,
        bool isVoucherMintActive_,      
        uint256 publicMintPrice_,      
        uint256 privateMintPrice_,
        uint256 maxPublicMintAmount_,
        uint256 maxPrivateMintAmount_,
        uint256 maxTotalSupply_,  
        uint256 maxPrivateMintSupply_,
        uint256 totalPublicSold_,
        uint256 totalPrivateSold_,
        uint256 totalVoucherClaimed_,
        uint256 totalVoucherIssued_,
        uint256 totalProjectMint_
    )
    {
        isPublicMintActive_   = minterConfig.isPublicMintActive;
        isPrivateMintActive_  = minterConfig.isPrivateMintActive;
        isVoucherMintActive_  = minterConfig.isVoucherMintActive;
        publicMintPrice_      = minterConfig.publicMintPrice;
        privateMintPrice_     = minterConfig.privateMintPrice;
        maxPublicMintAmount_  = minterConfig.maxPublicMintAmount;
        maxPrivateMintAmount_ = minterConfig.maxPrivateMintAmount;
        maxTotalSupply_       = minterConfig.maxTotalSupply;
        maxPrivateMintSupply_ = minterConfig.maxPrivateMintSupply;
        totalPublicSold_      = totalPublicSold;
        totalPrivateSold_     = totalPrivateSold;
        totalVoucherClaimed_  = totalVoucherClaimed;
        totalVoucherIssued_   = totalVoucherIssued;
        totalProjectMint_     = totalProjectMint;
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOwnerAndOperator() {
        require( _msgSender() == owner() || _msgSender() == _operator, "Caller is not the operator");
        _;
    }

}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/interfaces/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: contracts/ERC721S.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;









/**
 * A modification of openzeppelin ERC721 for a small, sequential mint, non-burnable collection
 * that implement IERC721, IERC721Metadata, and IERCEnumberable.
 * The assumption for this contract are:
 *  - Token will be mint in sequential order
 *  - The total number of token can be pack in 2**32-1
 */

contract ERC721S is Context, ERC165, IERC721, IERC721Metadata {

    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenDetail {
        // The address of the owner.
        address owner;              
        // Mapping from TokenID to index in _allToken list
        uint32  allTokensIndex;     
        // Mapping from TokenID to index in _ownedTokens list
        uint32  ownedTokensIndex;   
        // Reserved for other used;
        uint32  reserved;    
    }
    
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to token Detail 
    mapping(uint256 => TokenDetail) private _tokenDetail;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint32[]) private _ownedTokens;

    // Array with all token ids, used for enumeration
    uint32[] private _allTokens;

    // Id of the fist token minted
    uint32 private _currentIndex;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint32) {
        return 1;
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens burned in the contract.
     */
    function _totalBurned() internal view returns (uint256) {
        unchecked {
            return _totalMinted() - _allTokens.length;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _ownedTokens[owner].length;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _tokenDetail[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721S.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _tokenDetail[tokenId].owner != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721S.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints new token and transfers it to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to) internal virtual {
        _safeMint(to, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, bytes memory _data) internal virtual {
        uint256 tokenId = uint256(_currentIndex);
        _mint(to);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
    function _mint(address to) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        
        uint32 tokenId = _currentIndex;

        _beforeTokenTransfer(address(0), to, tokenId);

        uint32[] storage toTokenList = _ownedTokens[to];
        TokenDetail storage tokenDetail = _tokenDetail[tokenId];

        tokenDetail.owner = to;        
        tokenDetail.ownedTokensIndex = uint32(toTokenList.length);
        tokenDetail.allTokensIndex = uint32(_allTokens.length);

        toTokenList.push(tokenId);
        _allTokens.push(tokenId);        
        
        _currentIndex += 1;

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
        address owner = ERC721S.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        TokenDetail storage tokenDetail = _tokenDetail[tokenId];
        uint32[] storage fromTokenList = _ownedTokens[owner];
        
        // _removeTokenFromOwnerEnumeration(owner, tokenId);        
        uint32 tokenIndex = tokenDetail.ownedTokensIndex;
        uint32 lastToken = fromTokenList[fromTokenList.length - 1];
        if (lastToken != uint32(tokenId)) {
            fromTokenList[tokenIndex] = lastToken;
            _tokenDetail[lastToken].ownedTokensIndex = tokenIndex;
        }
        fromTokenList.pop();

        // _removeTokenFromALLTokensEnumeration
        uint32 lastAllToken = _allTokens[_allTokens.length - 1];
        uint32 allTokensIndex = tokenDetail.allTokensIndex;
        _allTokens[allTokensIndex] = lastAllToken;
        _tokenDetail[lastAllToken].allTokensIndex = allTokensIndex;

        tokenDetail.owner  = address(0);       
        tokenDetail.allTokensIndex = 0;
        tokenDetail.ownedTokensIndex = 0;
        
        _allTokens.pop();
        
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721S.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _tokenDetail[tokenId].owner = to;
    
        // _removeTokenFromOwnerEnumeration(from, tokenId);        
        uint32[] storage fromTokenList = _ownedTokens[from];
        TokenDetail storage tokenDetail = _tokenDetail[tokenId];
        uint32 tokenIndex = tokenDetail.ownedTokensIndex;
        uint32 lastToken = fromTokenList[fromTokenList.length - 1];
        fromTokenList[tokenIndex] = lastToken;
        _tokenDetail[lastToken].ownedTokensIndex = tokenIndex;
        fromTokenList.pop();

        // _addTokenToOwnerEnumeration(to, tokenId);
        uint32[] storage toTokenList = _ownedTokens[to];
        tokenDetail.ownedTokensIndex = uint32(toTokenList.length);
        toTokenList.push(uint32(tokenId));
        
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
        emit Approval(ERC721S.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < ERC721S.balanceOf(owner), "Owner index out of bounds");
        return uint256(_ownedTokens[owner][index]);
    }

    function ownedBy(address owner) external view returns (uint256[] memory) {        
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        uint32[] storage ownedTokens = _ownedTokens[owner];

        for (uint256 i; i < balance; i++) {
            tokens[i] = uint256(ownedTokens[i]);
        }
               
        return tokens;
    }


    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual  returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual  returns (uint256) {
        require(index < ERC721S.totalSupply(), "Global index out of bounds");
        return uint256(_allTokens[index]);
    }    

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
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}


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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

}
// File: contracts/JCCPixieVoucher.sol


pragma solidity >=0.8.10 <0.9.0;






contract JCCPixieVoucher is
    ERC721S,
    PublicPrivateVoucherMinter,    
    Pausable
{    
    using Strings for uint256;

    // Variable
    uint256 public maxSupply = 999;
    
    string public baseURI;
    string public notRevealedURI = "https://assets.jokercharlie.com/jccpixie/default.json";        
    string public baseExtension  = ".json";

    bool public revealed;    
    
    constructor (address payable beneficiary)
        ERC721S("JCCPixie Voucher", "JCCPIX")            
        PublicPrivateVoucherMinter(
            PublicPrivateVoucherMinter.MinterConfig({
                isPublicMintActive : false,      // can call publicMint only when isPublicMintActive is true
                isPrivateMintActive: true,       // can call privateMint only when isPrivateMintActive is true
                isVoucherMintActive: false,      // can call voucherMint only when isVoucherMintActive is true
                publicMintPrice: 0 ether,        // price for publicMint
                privateMintPrice: 0 ether,       // price for privateMint
                maxPublicMintAmount:  1,         // maximum amount per publicMint transaction
                maxPrivateMintAmount: 1,         // default maximum amount per privateMint transaction    
                maxTotalSupply: 999,             // maximum supply 
                maxPrivateMintSupply: 999        // maximum supply for previate mint
            }),
            beneficiary
        )
    {
        require(beneficiary != address(0), "Not the zero address");
    }

    function reveal() 
        external
        onlyOwner
    {
        revealed = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }    

    function _mintTo(address to, uint256 amount) internal override
    {        
        // require(!paused(), "Mint is paused"); // Already checks in _beforeTokenTransfer
        require(totalSupply() + amount <= maxSupply, "Max supply limit exceed");
        for (uint256 i; i < amount; i++) {
            _safeMint(to);
        }
    }

    // TokenURI related functions    

    function setBaseTokenURI(string calldata uri)
        external
        onlyOwner
    {
        baseURI = uri;
    }

    function setNotRevealedURI(string calldata uri) 
        external
        onlyOwner
    {
        notRevealedURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function baseTokenURI(uint256 tokenId) public view returns (string memory) {
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return notRevealedURI;
        } else {
            return baseTokenURI(tokenId);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        require(!paused(), "Contract is paused");
        super._beforeTokenTransfer(from, to, tokenId);        
    }
    
}