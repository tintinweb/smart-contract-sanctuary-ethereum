/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

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

interface ERC721TokenReceiver {
    function onERC721Received(address operator,address from, uint256 id, bytes calldata data) external returns (bytes4);
}

/**
 * Built to optimize for lower gas during batch mints and transfers. 
 * A new locking mechanism has been added to protect users from all attempted scams.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 */
abstract contract ERC721slimBatch {
    using Address for address;
    using Strings for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct collectionData {
        string name;
        string symbol;
        uint256 index;
        uint256 burned;
    }

    address private _contractOwner;
    collectionData internal _collectionData;
    mapping(uint256 => address) internal _ownerships;
    mapping(address => uint256) internal _addressData;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) private  _operatorApprovals;

    constructor(string memory _name, string memory _symbol) {
        _collectionData.name = _name;
        _collectionData.symbol = _symbol;
        _transferOwnership(_msgSender());
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint` or `_safeMint`),
     */
    function _exists(uint256 tokenId) public view virtual returns (bool) {
        return tokenId < _collectionData.index;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        unchecked {
            if (tokenId < _collectionData.index) {
                address ownership = _ownerships[tokenId];
                if (ownership != address(0)) {
                    return ownership;
                }
                    while (true) {
                        tokenId--;
                        ownership = _ownerships[tokenId];

                        if (ownership != address(0)) {
                            return ownership;
                        }
                         
                    }
                }
            }

        revert ();
    }

    /**
     * @dev Returns the number of tokens in `_owner`'s account.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Address 0");
        return _addressData[_owner];
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        require(to != address(0), "Address 0");
        require(quantity > 0, "Quantity 0");

        unchecked {
            uint256 updatedIndex = _collectionData.index;
            _addressData[to] += quantity;
            _ownerships[updatedIndex] = to;
            
            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex++);
            }

            _collectionData.index = updatedIndex;
        }
    }

    /**
     * @dev See Below {ERC721L-_safeMint}.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {onERC721Received}, which is called for each safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 quantity, bytes memory _data) internal {
        require(to != address(0), "Address 0");
        require(quantity > 0, "Quantity 0");

        unchecked {
            uint256 updatedIndex = _collectionData.index;
            _addressData[to] += quantity;
            _ownerships[updatedIndex] = to;
            
            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                require(to.code.length == 0 ||
                        ERC721TokenReceiver(to).onERC721Received(_msgSender(), address(0), updatedIndex, _data) ==
                        ERC721TokenReceiver.onERC721Received.selector, "Unsafe Destination");
                updatedIndex++;
            }

            _collectionData.index = updatedIndex;
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - `from` must not have tokens locked.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        address currentOwner = ownerOf(tokenId);
        require((_msgSender() == currentOwner ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(currentOwner,_msgSender())), "Not Approved");
        require(currentOwner == from, "Not Owner");
        require(to != address(0), "Address 0");

        delete _tokenApprovals[tokenId]; 
        unchecked {
            _addressData[from] -= 1;
            _addressData[to] += 1;
            _ownerships[tokenId] = to;
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId] == address(0) && nextTokenId < _collectionData.index) {
                _ownerships[nextTokenId] = currentOwner;
            }
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See Below {ERC721L-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, '');
    }

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
     * - If `to` refers to a smart contract, it must implement {ERC721TokenReceiver}, which is called upon a safe transfer.
     * - `from` must not have tokens locked.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual {
        transferFrom(from, to, tokenId);
        require(to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(_msgSender(), address(0), tokenId, _data) ==
                ERC721TokenReceiver.onERC721Received.selector, "Unsafe Destination");
    }
    
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view returns (uint256) {
        unchecked {
            return _collectionData.index - _collectionData.burned;
        }
    }

    /**
     * @dev Returns the total amount of tokens created by the contract.
     */
    function totalCreated() public view returns (uint256) {
        return _collectionData.index;
    }

    /**
     * @dev Returns the total amount of tokens burned by the contract.
     */
    function totalBurned() public view returns (uint256) {
        return _collectionData.burned;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     * - Owner must not have tokens locked.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != _msgSender(), "Address is Owner");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `_owner` and tokens are unlocked for `_owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address _owner, address operator) public view returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

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
    function approve(address to, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(_msgSender() == tokenOwner || isApprovedForAll(tokenOwner, _msgSender()), "ERC721L: Not Approved");
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721L: Null ID");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view returns (string memory) {
        return _collectionData.name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view returns (string memory) {
        return _collectionData.symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "Non Existent");
        string memory _baseURI = baseURI();
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function baseURI() public view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Returns tokenIDs owned by `_owner`.
     */
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 totalOwned = _addressData[_owner];
        require(totalOwned > 0, "balance 0");
        uint256 supply = _collectionData.index;
        uint256[] memory tokenIDs = new uint256[](totalOwned);
        uint256 ownedIndex;
        address currentOwner;

        unchecked {
            for (uint256 i; i < supply; i++) {
                address currentAddress = _ownerships[i];
                if (currentAddress != address(0)) {
                    currentOwner = currentAddress;
                }
                if (currentOwner == _owner) {
                    tokenIDs[ownedIndex++] = i;
                    if (ownedIndex == totalOwned){
                        return tokenIDs;
                    }
                }
            }
        }

        revert();
    }

    function owner() public view returns (address) {
        return _contractOwner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Caller not owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _contractOwner;
        _contractOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Returns the token collection information.
     */
    function collectionInformation() public view returns (collectionData memory) {
        return _collectionData;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

}

interface IRocketPass {
    function balanceOf(address _address, uint256 id) external view returns (uint256);
}


contract HASHDroid is ERC721slimBatch {

    string private _baseURI = "ipfs://QmZov5NNjcx472daCYvD3unxgWXQ1UJwYsAPr6yMFiJT5a/";
    uint256 public constant maxPublicMinted = 2063;

    uint256 public publicMaxMint = 7;
    uint256 public priceDroid = .069 ether;
    uint256 public publicMinted;

    bool public depreciatedMint;
    bool public mintStatus;
    IRocketPass public rocketPass;

    mapping(address => uint256) public mintedRP;

  constructor(address _rocketPass) ERC721slimBatch("BMC Hashdroid", "HD") {
      rocketPass = IRocketPass(_rocketPass);
  }

  modifier callerIsUser() {
    require(tx.origin == _msgSender(), "Contract Caller");
    _;
  }

  function rpMint(uint256 _quantity) public callerIsUser() {
    require(mintStatus, "Public sale not active");
    require(rocketPass.balanceOf(_msgSender(), 1) - mintedRP[_msgSender()] >= _quantity, "Insufficient Rocket Passes remaining");

    mintedRP[_msgSender()] += _quantity;
    _mint(_msgSender(), _quantity);
  }

  function publicMint(uint256 _quantity) public payable callerIsUser() {
    require(mintStatus, "Public sale not active");
    require(_quantity <= publicMaxMint, "Invalid quantity");
    unchecked {
        require(publicMinted + _quantity <= maxPublicMinted, "Insufficient supply remaining");
        require(msg.value >= priceDroid * _quantity, "Insufficient payment");
    }
    publicMinted += _quantity;
    _mint(_msgSender(), _quantity);
  }

  function baseURI() public view override returns (string memory) {
    return _baseURI;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    _baseURI = newBaseURI;
  }

  function setRocketPass(address _address) external onlyOwner {
    require(!depreciatedMint, "Contract is depreciated.");
    rocketPass = IRocketPass(_address);
  }

  function setPublicState(bool _state) external onlyOwner {
    require(!depreciatedMint, "Contract is depreciated.");
    mintStatus = _state;
  }

  function setPublicMaxMint(uint256 _newLimit) external onlyOwner {
    require(!depreciatedMint, "Contract is already depreciated.");
    publicMaxMint = _newLimit;
  }

  function depreciateMint() external onlyOwner {
    require(!depreciatedMint, "Contract is already depreciated.");
    delete mintStatus;
    depreciatedMint = true;
    uint256 excess = 7777 - totalSupply();
    if (excess > 0){
        uint256 droidsToMint = excess > 60 ? 60 : excess; 
        _mint(_msgSender(), droidsToMint);
    }
    
  }

  function verifyRP(address _address) external view returns (bool){
    return (rocketPass.balanceOf(_address, 1) - mintedRP[_address]) > 0;
  }

  function withdrawFunding() external onlyOwner {
    uint256 currentBalance = address(this).balance;
    (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
    require(sent, "Transfer Error");    
  }

}