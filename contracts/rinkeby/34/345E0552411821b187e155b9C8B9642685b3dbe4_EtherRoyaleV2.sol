// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Shamelessly Stolen from Inu - this is a modified version of the MTM migration contract.
// Every single method is modified and has custom "passive" migration proxy logic.

abstract contract Ownable {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Ownable: NO"); _; }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        owner = newOwner_; 
    }
}

interface iRoyale {
    // Views
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address address_) external view returns (uint256);
    function getApproved(uint256 tokenId_) external view returns (address);
    function isApprovedForAll(address owner_, address operator_) external view returns (bool);
}

// ERC721I Functions, but we modified it for passive migration method
// ERC721IMigrator uses local state storage for gas savings.
// It is like ERC721IStorage and ERC721IOperator combined into one.
contract ERC721IMigrator is Ownable {

    // Interface the MTM Characters Main V1
    iRoyale public Royale;
    function setRoyale(address address_) external onlyOwner {
        Royale = iRoyale(address_);
    }

    // Name and Symbol Stuff
    string public name; string public symbol;
    constructor(string memory name_, string memory symbol_) {
        name = name_; symbol = symbol_;
    }

    // We turned these to _ prefix so we can use a override function
    // To display custom proxy and passive migration logic
    uint256 public totalSupply;
    mapping(uint256 => address) public _ownerOf;
    mapping(address => uint256) public _balanceOf;

    // Here we have to keep track of a initialized balanceOf to prevent any view issues
    mapping(address => bool) public _balanceOfInitialized;

    
    // We disregard the previous contract's approvals
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // // TotalSupply Setter
    // Here, we set the totalSupply to equal the previous
    function setTotalSupply(uint256 totalSupply_) external onlyOwner {
        totalSupply = totalSupply_; 
    }

    // // Initializer
    // This is a custom Transfer emitter for the initialize of this contract only
    function initialize(uint256[] calldata tokenIds_, address[] calldata owners_) external onlyOwner {
        require(tokenIds_.length == owners_.length,
            "initialize(): array length mismatch!");
        
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            emit Transfer(address(0x0), owners_[i], tokenIds_[i]);
        }
    }

    // OwnerOf (Proxy View)
    function ownerOf(uint256 tokenId_) public view returns (address) {
        // Find out of the _ownerOf slot has been initialized.
        // We hardcode the tokenId_ to save gas.
        if (tokenId_ <= 1538 && _ownerOf[tokenId_] == address(0x0)) {
            // _ownerOf[tokenId_] is not initialized yet, so return the Royale V1 value.
            return Royale.ownerOf(tokenId_);
        } else {
            // If it is already initialized, or is higher than migration Id
            // return local state storage instead.
            return _ownerOf[tokenId_];
        }
    }

    // BalanceOf (Proxy View)
    function balanceOf(address address_) public view returns (uint256) {
        // Proxy the balance function
        // We have a tracker of initialization of _balanceOf to track the differences
        // If initialized, we use the state storage. Otherwise, we use Royale V1 storage.
        if (_balanceOfInitialized[address_]) {
            return _balanceOf[address_]; 
        } else {
            return Royale.balanceOf(address_);
        }
    }

    // Events! L[o_o]⅃ 
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Mint(address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Functions
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0x0), "ERC721IMigrator: _mint() Mint to Zero Address!");
        require(ownerOf(tokenId_) == address(0x0), "ERC721IMigrator: _mint() Token already Exists!");

        // // ERC721I Logic

        // We set _ownerOf in a normal way
        _ownerOf[tokenId_] = to_;

        // We rebalance the _balanceOf on initialization, otherwise follow normal ERC721I logic
        if (_balanceOfInitialized[to_]) {
            // If we are already initialized
            _balanceOf[to_]++;
        } else {
            _balanceOf[to_] = (Royale.balanceOf(to_) + 1);
            _balanceOfInitialized[to_] = true;
        }

        // Increment TotalSupply as normal
        totalSupply++;

        // // ERC721I Logic End

        // Emit Events
        emit Transfer(address(0x0), to_, tokenId_);
        emit Mint(to_, tokenId_);
    }

    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(from_ == ownerOf(tokenId_), "ERC721IMigrator: _transfer() Transfer from_ != ownerOf(tokenId_)");
        require(to_ != address(0x0), "ERC721IMigrator: _transfer() Transfer to Zero Address!");

        // // ERC721I Transfer Logic

        // If token has an approval
        if (getApproved[tokenId_] != address(0x0)) {
            // Remove the outstanding approval
            getApproved[tokenId_] = address(0x0);
        }

        // Set the _ownerOf to the receiver
        _ownerOf[tokenId_] = to_;

        // // Initialize and Rebalance _balanceOf 
        if (_balanceOfInitialized[from_]) {
            // If from_ is initialized, do normal balance change
            _balanceOf[from_]--;
        } else {
            // If from_ is NOT initialized, follow rebalance flow
            _balanceOf[from_] = (Royale.balanceOf(from_) - 1);
            // Set from_ as initialized
            _balanceOfInitialized[from_] = true;
        }

        if (_balanceOfInitialized[to_]) {
            // If to_ is initialized, do normal balance change
            _balanceOf[to_]++;
        } else {
            // If to_ is NOT initialized, follow rebalance flow
            _balanceOf[to_] = (Royale.balanceOf(to_) + 1);
            // Set to_ as initialized;
            _balanceOfInitialized[to_] = true;
        }

        // // ERC721I Transfer Logic End

        emit Transfer(from_, to_, tokenId_);
    }

    // Approvals
    function _approve(address to_, uint256 tokenId_) internal virtual {
        if (getApproved[tokenId_] != to_) {
            getApproved[tokenId_] = to_;
            emit Approval(ownerOf(tokenId_), to_, tokenId_);
        }
    }
    function _setApprovalForAll(address owner_, address operator_, bool approved_) internal virtual {
        require(owner_ != operator_, "ERC721IMigrator: _setApprovalForAll() Owner must not be the Operator!");
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    // // Functional Internal Views
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view returns (bool) {
        address _owner = ownerOf(tokenId_);
        require(_owner != address(0x0), "ERC721IMigrator: _isApprovedOrOwner() Owner is Zero Address!");
        return (spender_ == _owner // is the owner OR
            || spender_ == getApproved[tokenId_] // is approved for token OR
            || isApprovedForAll[_owner][spender_] // isApprovedForAll spender 
        );
    }

    // Exists
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        // We hardcode tokenId_ for gas savings
        if (tokenId_ <= 1538) { return true; }
        return _ownerOf[tokenId_] != address(0x0);
    }

    // Public Write Functions 
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(to_ != _owner, "ERC721IMigrator: approve() cannot approve owner!");
        require(msg.sender == _owner // sender is the owner of the token
            || isApprovedForAll[_owner][msg.sender], // or isApprovedForAll for the owner
            "ERC721IMigrator: approve() Caller is not owner of isApprovedForAll!");
        _approve(to_, tokenId_);
    }
    // SetApprovalForAll - the msg.sender is always the subject of approval
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    // Transfers
    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), 
            "ERC721IMigrator: transferFrom() _isApprovedOrOwner = false!");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.staticcall(abi.encodeWithSelector(0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, "ERC721IMigrator: safeTransferFrom() to_ not ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    // OZ Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    // High Gas Loop View Functions
    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            // Add another loop through for each 0x0 until array is filled
            if (ownerOf(i) == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
            // Fill the array on each token found
            if (ownerOf(i) == address_) {
                // Record the ID in the index 
                _tokens[_index] = i;
                // Increment the index
                _index++;
            }
        }
        return _tokens;
    }

    // TokenURIs Functions Omitted //

}

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


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract EtherRoyaleV2 is ERC721IMigrator {

    using Address for address;
    using Strings for uint256;

    string private baseURI;
    bool public paused = false;
    uint256 public maxSupply = 8888;
    uint256 public price = 0.069 ether;
    
    mapping (address => uint256) public saleMintCount;
    uint256 public saleWalletLimit = 10;
    bool public saleStarted = false;

    event saleModeChanged();

    constructor(string memory _tokenUrl) ERC721IMigrator("Ether Royale", "ER") {
        baseURI = _tokenUrl;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    modifier correctPayment(uint8 quantity) {
        require(quantity * price == msg.value);
        _;
    }

    modifier supplyLimit(uint8 quantity) {
        require(totalSupply + quantity <= maxSupply, "No more tokens");
        _;
    }


    modifier sale(uint8 quantity) {
        require(saleStarted, "Sale must be started");
        require(saleMintCount[msg.sender] + quantity <= saleWalletLimit, "wallet limit reached");
        _;
    }

    function saleMint(uint8 quantity) external payable notPaused supplyLimit(quantity) sale(quantity) correctPayment(quantity) {
        saleMintCount[msg.sender] += quantity;
        for (uint256 i = 0; i < quantity; i++) {
            _mint(msg.sender, totalSupply+1);
        }
    }

    function ownerMint(uint8 quantity, address toAddress) external supplyLimit(quantity) onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            _mint(toAddress, totalSupply+1);
        }
    } 

    function startPresale() external onlyOwner {
        saleStarted = false;

        emit saleModeChanged();
    }

    function startSale() external onlyOwner {
        saleStarted = true;

        emit saleModeChanged();
    }

    function resetSale() external onlyOwner {
        saleStarted = false;

        emit saleModeChanged();
    }

    function setPause(bool pause) external onlyOwner {
        paused = pause;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setSaleLimit(uint8 _saleLimit) external onlyOwner {
        saleWalletLimit = _saleLimit;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 donflamingov = address(this).balance * 15 / 100;
        uint256 catnipv = address(this).balance * 15 / 100;

        (bool donflamingohs, ) = payable(0xdCd6B7449167220724084bfD61f9B205c7dfa5a1).call{value: donflamingov}("");
        require(donflamingohs);

        (bool catniphs, ) = payable(0x026bf664D2C84E4Da15B18d66e41Ab8180f2bda3).call{value: catnipv}("");
        require(catniphs);

        uint256 balance = address(this).balance;
        payable(0xea068799096AfE357BC6bc999531751F365e24f0).transfer(balance);
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function leftLimit() external view returns (uint256) {
        require(saleStarted, "Sales wasn't started yet");

        return saleWalletLimit - saleMintCount[msg.sender];

    }

    
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }
}