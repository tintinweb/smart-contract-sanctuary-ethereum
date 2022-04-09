/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

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

// File: @openzeppelin/contracts/interfaces/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/proxy/Clones.sol


// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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

// File: contracts/PublicPrivateVoucherMinter.sol


//
// TODO: https://medium.com/@ItsCuzzo/using-merkle-trees-for-nft-whitelists-523b58ada3f9 
//     : Implement Markle Tree Voucher Mint
//     : struct {
//     :    id   : uint16
//     :    valid: uint8
//     :    maxAmount: uint16
//     :    price: uint256
//     :    address: address
//     : } 
// https://github.com/Tierion/pymerkletools
// https://ethereum.stackexchange.com/questions/30931/python-and-solidity-keccak256-function-gives-different-results
// https://cryptobook.nakov.com/cryptographic-hash-functions/hash-functions-examples
// https://github.com/ajsantander/uni-token-distribution/blob/master/contracts/TokenDistributor.sol
// https://ethereum.stackexchange.com/questions/96697/soliditys-keccak256-hash-doesnt-match-web3-keccak-hash
// ==================================================================================================================

pragma solidity ^0.8.0;






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
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

interface IMintTo {
    function mintTo(address to, uint256 amount) external; // to be implement by subclass
}


contract PublicPrivateVoucherMinter is Ownable {    

    // event to log mint detail
    event MinterCreated(address _address);
    event PublicMint (address _address, uint256 _amount, uint256 _value);
    event PrivateMint(address _address, uint256 id, uint256 _amount, uint256 _value);
    event VoucherMint(address _address, uint256 id, uint256 _amount, uint256 _value);

    bytes4 constant mintToInterface = bytes4(keccak256("mintTo(address,uint256)"));
    
    bool _initialize;
    
    // Sale active control
    bool public isPublicMintActive;       // can call publicMint only when isPublicMintActive is true
    bool public isPrivateMintActive;      // can call privateMint only when isPrivateMintActive is true
    bool public isVoucherMintActive;      // can call voucherMint only when isVoucherMintActive is true

    uint256 public publicMintPrice       = 0.555 ether;       // price for publicMint
    uint256 public privateMintPrice      = 0.555 ether;      // price for privateMint
    uint256 public maxPublicMintAmount   = 2;  // maximum amount per publicMint transaction
    uint256 public maxPrivateMintAmount  = 1;  // maximum amount per privateMint transaction
 
    uint256 public maxTotalSupply        = 555; // maximum supply for current public round
    uint256 public maxPrivateMintSupply  = 100; // maximum supply for current private round    
    
    // Sale counter
    uint256 public totalPublicSold;
    uint256 public totalPrivateSold;    
    uint256 public totalVoucherClaimed;
    uint256 public totalVoucherIssued;
    
    bytes32 private _merkleRoot;    

    // a mapping from voucher/whitelised Id to the amount used
    mapping(uint256 => uint256) private _amountUsed;  
    
    // Operator
    address private _operator; // address of operator who can set parameter of this contract
    address private _mintedAddress; // address of the contract to call mintTo
    address private _withdrawAddress; // address to withdraw the mintAmount

    constructor (address mintedAddress) {
        initialize(mintedAddress, _msgSender(), _msgSender());
    }

    function initialize(address mintedAddress, address owner, address operator) public {
        require(!_initialize,"Already initialize");        
        // require(IERC165(mintedAddress).supportsInterface(mintToInterface), "Contract must implement mintTo");
        _mintedAddress = mintedAddress;
        _withdrawAddress = owner;
        _operator = operator;
    }

    function status() external view returns (uint256[] memory) {
        uint256[] memory data = new uint256[](15);
        data[0]  = isPublicMintActive  ? 1 : 0;
        data[1]  = isPrivateMintActive ? 1 : 0;
        data[2]  = isVoucherMintActive ? 1 : 0;
        data[3]  = publicMintPrice;
        data[4]  = privateMintPrice;
        data[5]  = maxPublicMintAmount;
        data[6]  = maxPrivateMintAmount;
        data[7]  = maxTotalSupply;
        data[8]  = maxPrivateMintSupply;
        data[9]  = totalPublicSold;
        data[10] = totalPrivateSold;
        data[11] = totalVoucherClaimed;
        data[12] = totalVoucherIssued;
        return data;
    }

    function setMintedAddress(address mintedAddress) external onlyOwner {
        _mintedAddress = mintedAddress;
    }

    function togglePublicMintActive() external onlyOwnerAndOperator {
        require (publicMintPrice > 0, "Public Mint Price is zero");
        isPublicMintActive = !isPublicMintActive;
    }

    function togglePrivateMintActive() external onlyOwnerAndOperator {
        require (privateMintPrice > 0, "Private Mint Price is zero");
        isPrivateMintActive = !isPrivateMintActive;
    }

    function toggleVoucherMintActive() external onlyOwnerAndOperator {
        isVoucherMintActive = !isVoucherMintActive;
    }

    function totalSold() external view returns (uint256) {
        return totalPublicSold + totalPrivateSold + totalVoucherClaimed;
    }

    // set maxTotalSupply
    function setMaxTotalSupply(uint256 supply) external onlyOwnerAndOperator {
        maxTotalSupply = supply;
    }

    // set parameter for public mint 
    function setPublicMintDetail(uint256 price, uint256 amount) external onlyOwnerAndOperator {
        require(!isPublicMintActive, "Public mint is active");
        publicMintPrice = price;
        maxPublicMintAmount = amount;        
    }

    // set parameter for private mint
    function setPrivateMintDetail(uint256 price, uint256 amount, uint256 supply) external onlyOwnerAndOperator {
        require(!isPrivateMintActive, "Private mint is active");
        privateMintPrice = price;
        maxPrivateMintAmount = amount;
        maxPrivateMintSupply = supply;
    }

    // set parameter for voucher/private mint
    function setVoucherDetail(bytes32 merkleRoot, uint256 voucherAmount) external onlyOwnerAndOperator {
        _merkleRoot = merkleRoot;
        totalVoucherIssued = voucherAmount;
    }

    function publicMint(uint256 amount) public payable {
        require(isPublicMintActive,"Public mint is closed");
        require(amount > 0,"Amount is zero");
        require(amount <= maxPublicMintAmount,"Amount is greater than maximum");        
        require(totalPublicSold + totalPrivateSold + totalVoucherIssued + amount <= maxTotalSupply,"Exceed maxTotalSupply");
        require(publicMintPrice * amount <= msg.value, "Insufficient fund");
        
        address to = _msgSender();

        IMintTo(_mintedAddress).mintTo(to, amount);        
        totalPublicSold += amount;        
        emit PublicMint(to, amount, msg.value);
    }

    function privateMint( uint256 amount,    
                          uint256 whitelistedId, uint256 whitelistedAmount, bytes32[] calldata proof ) public payable {

        require(isPrivateMintActive,"Private mint is closed");

        address to = _msgSender();
        bytes32 hash = keccak256(abi.encodePacked(whitelistedId, address(this), 'W',  to, whitelistedAmount));
        require(MerkleProof.verify(proof, _merkleRoot, hash),"Invalid whitelisted detail");

        require(amount > 0,"Amount is zero");
        require(_amountUsed[whitelistedId] == 0, "Whielisted has been used");
        require(totalPrivateSold + amount <= maxPrivateMintSupply,"Exceed maxPrivateMintSupply");

        require(privateMintPrice * amount <= msg.value, "Insufficient fund");
        if (whitelistedAmount == 0) {            
            require(amount <= maxPrivateMintAmount,"Amount is greater than maximum");                            
        } else {
            require(amount <= whitelistedAmount,"Amount is greater than maximum");                            
        }
                
        _amountUsed[whitelistedId] = amount;

        IMintTo(_mintedAddress).mintTo(to, amount);                
        totalPrivateSold += amount;  
        emit PrivateMint(to, whitelistedId, amount, msg.value);   
    }

    function voucherMint( uint256 amount,
                          uint256 voucherId, uint256 voucherAmount, uint256 voucherPrice, bytes32[] calldata proof) public payable {

        require(isVoucherMintActive,"Voucher mint is closed");

        address to = _msgSender();
        bytes32 hash = keccak256(abi.encodePacked(voucherId, address(this), 'V',  to, voucherAmount, voucherPrice));
        require(MerkleProof.verify(proof, _merkleRoot, hash),"Invalid whitelisted detail");        

        require(amount > 0,"Amount is zero");
        require(amount <= voucherAmount,"Ammount is greater than voucher");                        
        require(voucherPrice * amount <= msg.value, "Insufficient fund");
        require(_amountUsed[voucherId] == 0, "Voucher has been used");

        _amountUsed[voucherId] = amount;

        IMintTo(_mintedAddress).mintTo(to, amount);        
        totalVoucherClaimed   += amount;        
        emit VoucherMint(to, voucherId, amount, msg.value);       
    }

    function getAmountUsed(uint256 voucherId) external view returns (uint256) {
        return _amountUsed[voucherId];
    }

    //////////////////////////////////////////////////////////////////////////////////////
    // Function to withdraw fund from contract
    /////
    function withdraw() external onlyOwner {        
        uint256 _balance = address(this).balance;        
        Address.sendValue(payable(_withdrawAddress), _balance);
    }    
    function withdraw(uint256 balance) external onlyOwner {                    
        Address.sendValue(payable(_withdrawAddress), balance);
    }    
    function setWithdrawAddress(address withdrawAddress) external onlyOwner {        
        _withdrawAddress = withdrawAddress;
    }
    function checkWithdrawAddress(address withdrawAddress) external view onlyOwner returns (bool) {
        return _withdrawAddress == withdrawAddress;
    }    

    // set Operator
    function setOperator(address operator) external onlyOwner {
        _operator = operator;
    }

    // Create a clone of current contract
    function createMinter(address mintedAddress) external returns (address) {
        address clone = Clones.clone(address(this));
        PublicPrivateVoucherMinter(clone).initialize(mintedAddress, _msgSender(), _msgSender());
        emit MinterCreated(clone);
        return clone;
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOwnerAndOperator() {
        require( _msgSender() == owner() || _msgSender() == _operator, "Caller is not the operator");
        _;
    }

}