/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
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

// File: testnetz contract.sol

//SPDX-License-Identifier: MIT

pragma solidity^0.8.10;

//just a test

interface IERC165{
       function supportsInterface(bytes4) external view returns(bool); 
}

interface IERC721 is IERC165{

        event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
 
        event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


        function balanceOf(address owner) external view returns (uint256 balance);

        function ownerOf(uint256 tokenId) external view returns (address owner);

        function safeTransferFrom(address from, address to, uint256 tokenId) external;

        function transferFrom(address from, address to, uint256 tokenId) external;

        function approve(address to, uint256 tokenId) external;

        function getApproved(uint256 tokenId) external view returns (address operator);
    
        function setApprovalForAll(address operator, bool _approved) external;

        function isApprovedForAll(address owner, address operator) external view returns (bool);

        function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Metadata is IERC721{


        function name() external view returns(string memory);

        function symbol() external view returns(string memory);

        function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721{

        function totalSupply() external view returns (uint256);
    
        function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

        function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver{

        function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}




library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

abstract contract GSNCodeErgaenzung{
     function _msgSender() internal view virtual returns (address payable) {
        return payable (msg.sender);
    }
    
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is GSNCodeErgaenzung{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ERC165 is IERC165,GSNCodeErgaenzung{

        bytes4 private constant _Interface_ID_165 = 0x01ffc9a7;

        mapping(bytes4 => bool) _supportedInterfaces; 

        constructor() internal {

            _registerInterface(_Interface_ID_165);
        }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual{
        require(interfaceId !=0xffffffff,"ERC165: Invalid Interface ID");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract ERC721 is ERC165, Ownable, IERC721{
    using Address for address;
    using Strings for uint256;

    string internal _name;

    string internal _symbol;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    bytes4 internal constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    mapping (address=>uint256) _balances;

    mapping (uint256 => address) _owners;

    mapping (uint256 => address) private _tokenApprovals;

    mapping (address => mapping (address => bool)) private _operatorApprovals;
    

constructor(string memory name_, string memory symbol_) {

    _name = name_;
    _symbol = symbol_;


    _registerInterface(_INTERFACE_ID_ERC721);

}


    function balanceOf(address owner) public view virtual override returns(uint256){
        require(owner!=address(0),"ERC721: balance query for the zero address");
        
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns(address){
        address owner = _owners[tokenId];
        require(owner != address(0),"ERC721: owner query for nonexistent token");
        
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to!= owner,"ERC721: approval to current owner");

        require(_msgSender()== owner || isApprovedForAll(owner,_msgSender()),
        "ERC721: approve caller is not owner nor approved for all");

        _approve(to,tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns(address){
        require(_exists(tokenId),"ERC721: approved query for nonexistent token");
        
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override{
        _setApprovalForAll(_msgSender(),operator,approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns(bool){

        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(),tokenId),"ERC721: transfer caller is not owner nor approved");

        _transfer(from,to,tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)public virtual override{
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override{
        require(_isApprovedOrOwner(_msgSender(),tokenId),"ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    function _safeTransferFrom(address from,address to, uint256 tokenId, bytes memory _data) internal virtual{
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data),"ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns(bool){
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool){
        require(_exists(tokenId),"ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return(spender == owner|| getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to,tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data),"ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0),"ERC721: mint to the zero address");
        require(!_exists(tokenId),"ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual{
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0),tokenId);
        _balances[owner] -=1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);

    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual{
        require(ERC721.ownerOf(tokenId)== from,"ERC721: transfer from incorrect owner");
        require(to != address(0),"ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0),tokenId);

        _balances[from] -=1;
        _balances[to] +=1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual{
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual{
        require(owner != operator,"ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool){
        if (to.isContract()){
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)returns (bytes4 retval){
                return retval == IERC721Receiver.onERC721Received.selector;
            }
            catch(bytes memory reason){
                if (reason.length == 0){
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                else{
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        else{
            return true;
        }
    }

    function _beforeTokenTransfer(address from,address to, uint256 tokenId)internal virtual{
    }

    function _afterTokenTransfer(address from,address to, uint256 tokenId)internal virtual{
    }

}

contract ERC721Metadata is ERC721, IERC721Metadata{

using Strings for uint256;

string internal _baseURI;

constructor(string memory _name, string memory _symbol)ERC721(_name, _symbol) public{
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
}

    function name() public view virtual override returns(string memory){
        return _name;
    }

    function symbol()public view virtual override returns(string memory){
        return _symbol;
    }

    function tokenURI(uint256 tokenId)public view virtual override returns(string memory){
        require(_exists(tokenId),"ERC721: URI query for nonexistent token");

        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())): "baseURI not yet set";
    }


    function _beforeTokenTransfer(address from,address to, uint256 tokenId)internal virtual override{
        super._beforeTokenTransfer(from,to,tokenId);
    }

    function _afterTokenTransfer(address from,address to, uint256 tokenId)internal virtual override{
        super._afterTokenTransfer(from,to,tokenId);
    }
}

//@dev see 
//"https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol"
contract ERC721Enumerable is ERC721Metadata, IERC721Enumerable{

constructor(string memory _name, string memory _symbol)ERC721Metadata(_name, _symbol)public {
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
}

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;


    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex; 
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex; 

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

contract VNFT is ERC721Enumerable{

    address public immutable MAINWALLET;

    uint256 private _totalSupply;

constructor (string memory _name, string memory _symbol)ERC721Enumerable(_name,_symbol){
    MAINWALLET=msg.sender;
}
    uint256 public constant MAX_SUPPLY = 6666;

    uint256 public constant PRESALE_SUPPLY = 1000;

    uint256 public constant FOUNDERS_SUPPLY = 66;
    
    uint256 public FOUNDER_AMOUNT_MINTED;


    uint256 public preSalePrice = 50000000000000000 wei; // Änderungsmöglichkeit
    mapping(address => uint256) public whitelistAmountClaimed;
    bytes32 private merkleRoot;
    uint256 public preSaleAmountMinted;
    bool public isPreSaleLive;
    uint256 private PRE_SALE_MINT_LIMIT = 2; // ÄnderungsMöglichkeit


    uint256 public publicSaleAmountMinted;
    mapping(address => uint256) public publicSaleClaimed;
    uint256 public PUBLIC_SALE_MINT_LIMIT = 2; //ÄnderungsMöglichkeit
    bool public isPublicSaleLive;
    uint256 public publicSalePrice = 60000000000000000 wei; //Änderungsmöglichkeit

    function changePreSalePrice(uint256 _newPreSalePrice)public onlyOwner{
        preSalePrice = _newPreSalePrice;
    }

    function changePreSaleMintQuantity(uint256 _newAllowedPreSaleMintQuantity) public onlyOwner{
        PRE_SALE_MINT_LIMIT = _newAllowedPreSaleMintQuantity;
    }

    function changePublicSalePrice(uint256 _newPublicSalePrice) public onlyOwner{
        publicSalePrice = _newPublicSalePrice;
    }

    function changePublicSaleMntQuantity(uint256 _newAllowedPublicSaleMintQuantity) public onlyOwner{
        PUBLIC_SALE_MINT_LIMIT = _newAllowedPublicSaleMintQuantity;
    }

    function setBaseURI(string memory BaseURI) public onlyOwner{
        _baseURI = BaseURI;
    }

    modifier callerIsUser(){
        if(tx.origin != msg.sender)
            revert("ERC721: mint from contract not allowed");
        _;
    }

    function remainingSupply() public view returns(uint256){
        return MAX_SUPPLY- _totalSupply;
    }

    function preSaleBuy(bytes32[] memory _merkleproof, uint256 _mintAmount) external payable callerIsUser{
        if (!isPreSaleLive || isPublicSaleLive)
            revert("Presale inactive");

        if(preSaleAmountMinted + _mintAmount > PRESALE_SUPPLY)
            revert("Mint query exceeds presale supply");

        if(whitelistAmountClaimed[msg.sender] + _mintAmount > PRE_SALE_MINT_LIMIT)
            revert("Mint query exceeds allocated presaleamount");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleproof, merkleRoot, leaf))
            revert("Mint query from non whitelist member");

        if(msg.value < preSalePrice * _mintAmount)
            revert("Insufficient ETH sent");

        unchecked{
            preSaleAmountMinted += _mintAmount;
            whitelistAmountClaimed[msg.sender] += _mintAmount;
        }

        for(uint i; i < _mintAmount;){
            _totalSupply += 1;
            _mint(msg.sender, _totalSupply);
            unchecked{
                ++i;
            }
        }

    }

    function publicSaleBuy(uint256 _mintAmount) external payable callerIsUser {
        if(!isPublicSaleLive)
            revert("Publicsale inactive");
        
        if(_totalSupply +_mintAmount > MAX_SUPPLY)
            revert("Mint query exceeds max supply");
        
        if(publicSaleClaimed[msg.sender] + _mintAmount > PUBLIC_SALE_MINT_LIMIT)
            revert("Mint query exceeds publicsale mint limit");

        if(msg.value < publicSalePrice * _mintAmount)
            revert("Insufficient ETH sent");

        unchecked{
            publicSaleAmountMinted += _mintAmount;
            publicSaleClaimed[msg.sender] += _mintAmount;
        }

        for(uint i; i < _mintAmount;){
            _totalSupply += 1;
            _mint(msg.sender, _totalSupply);
            unchecked{
                ++i;
            }
        }
    }

    function foundersMint (address founderAddress,uint256 _Amount) external onlyOwner{
        if(FOUNDER_AMOUNT_MINTED + _Amount > FOUNDERS_SUPPLY)
            revert("Mint query exceeds founder supply");

        for(uint i; i < _Amount;){
            _totalSupply += 1;
            _mint(founderAddress, _totalSupply);
            unchecked{
                ++i;
            }
        }

        unchecked{
            FOUNDER_AMOUNT_MINTED += _Amount;
        }
    }

    function withdraw() external onlyOwner{
        (bool succes, ) = payable(MAINWALLET).call{
            value: address(this).balance
        }("");
        if(!succes)
            revert("Withdrawl failed");
    }

    function setPreSaleStatus(bool active) external onlyOwner{
        isPreSaleLive = active;
    }

    function setPublicSaleStatus(bool active) external onlyOwner{
        isPublicSaleLive = active;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

//nur für testnetz
    function selfdestruction(bool mustbetrue) external onlyOwner{
        require(mustbetrue == true,"bool value must be true");
        selfdestruct(payable(msg.sender));
    }
}


/**

  IERC165        GSN
       |     /      |
     ERC165   Ownable    IERC721
        |        |         |
                ERC721            IERC721Metadata
                   |                |
                         ERC721Metadata                     IERC721Enumerable
                                |                               |
                                        ERC721Enumerable
                                                |
                                            Vengeful
*/