/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

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
        // On the first call to nonReentrant, _notEntered will be true
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

contract XWC_NFT is Ownable,ReentrancyGuard {

    event setETHPriceOnSaleEvent(address indexed _address, uint256 indexed _tokenId, uint256 indexed _price, uint256 timeStamp, string itemName, string ownerName, string itemDescription, string copyRightMsg, string url, bool isSetPrice);
    event CancelSellEvent(address indexed _address, uint256 indexed _tokenId, uint256 indexed _price, uint256 _timeStamp);
    event Mint(address indexed from, address indexed to, uint256 indexed tokenId,uint256 price, uint256 _timeStamp, string itemName, string ownerName, string itemDescription, string copyRightMsg, string url, bool isSetPrice);
    event PurchaseWithEthEvent(address indexed _seller, address indexed _buyer, uint256 indexed _price, uint256 tokenId, uint256 _timeStamp, string itemName, string ownerName, string itemDescription, string copyRightMsg, string url, bool isSetPrice);
    event TransferNFTEvent(address indexed from, address indexed to, uint256 indexed tokenId,uint256 price, uint256 _timeStamp, string itemName, string ownerName, string itemDescription, string copyRightMsg, string url, bool isSetPrice);
   
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    struct TokenDescription {
        uint256 TokenId; 
        uint256 Price; 
        address Account; 
        string ItemName; 
        string OwnerName; 
        string ItemDescription; 
        string CopyRightMsg; 
        string Url; 
        bool isSetPrice; 
    }

    string public _name;
    string public _symbol;
    uint256 private _currentTokenId = 0;
    uint256 constant public FEE = 0.00001 ether;
    address public feeTo;

    mapping(uint256 => TokenDescription) tokenDescriptionMaps;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;

    constructor(
        string memory name_,
        string memory symbol_,
        address _feeTo
    ) {
        _name = name_;
        _symbol = symbol_;
        require(bytes(name_).length != 0 && bytes(symbol_).length != 0,"name and symbol can't be empty");
        feeTo = _feeTo;
    }

    function updateFeeTo(address _feeTo) external notContract onlyOwner {
        feeTo = _feeTo;
    }

    function refundIfOver() private {
        if(msg.value > FEE) {
            uint bal = msg.value - FEE;
            payable(msg.sender).transfer(bal);
        }
    }

    function setETHPriceOnSale(uint256 _tokenId,uint256 _price) public returns(bool) {
        require(_tokenId <= getLastTokenId(),"NFT not exist!");
        require(msg.sender == ownerOf(_tokenId),"You don't have permission to setPrice for this NFT!");
        require(_price > 0, "Price Must Be Above Zero!");

        TokenDescription memory t = tokenDescriptionMaps[_tokenId];
        tokenDescriptionMaps[_tokenId] = TokenDescription(
            _tokenId,
            _price,
            msg.sender,
            t.ItemName,
            t.OwnerName,
            t.ItemDescription,
            t.CopyRightMsg,
            t.Url,
            true
        );

        emit setETHPriceOnSaleEvent(
            msg.sender,
            _tokenId,
            _price,
            block.timestamp,
            t.ItemName,
            t.OwnerName,
            t.ItemDescription,
            t.CopyRightMsg,
            t.Url,
            true
            );

        return true;
    }

    function cancelSell(uint _tokenId) public notContract returns(bool) {
        require(msg.sender == ownerOf(_tokenId),"You don't have permission to cancel sell for this NFT!");
        require(tokenDescriptionMaps[_tokenId].isSetPrice == true,"not on sale yet1!");

        tokenDescriptionMaps[_tokenId].Price = 0;
        tokenDescriptionMaps[_tokenId].isSetPrice = false;

        emit CancelSellEvent(msg.sender,_tokenId,tokenDescriptionMaps[_tokenId].Price,block.timestamp);

        return true;
    }

    function getTokenDescriptionByTokenId(uint256 _tokenId) external view returns(
        uint256 price,
        address account,
        string memory itemName,
        string memory ownerName,
        string memory itemDescription,
        string memory copyRightMsg,
        string memory url,
        bool isSetPrice) {
        require(_tokenId <= getLastTokenId(),"NFT not exist!");

        TokenDescription memory t = tokenDescriptionMaps[_tokenId];

        return (
            t.Price,
            t.Account,
            t.ItemName,
            t.OwnerName,
            t.ItemDescription,
            t.CopyRightMsg,
            t.Url,
            t.isSetPrice
            );
    }

    function mint(
        string calldata _ItemName,
        string calldata _OwnerName,
        string calldata _ItemDescription,
        string calldata _CopyRightMsg,
        string calldata _Url)
    external virtual payable notContract nonReentrant {
        require(msg.value >= FEE,"You don't have enough money to mint!");

        uint256 _tokenId = _tokenIdTracker.current()+1;

        _mint(msg.sender, _tokenId);

        tokenDescriptionMaps[_tokenId] = TokenDescription(
            _tokenId,
            0,
            msg.sender,
            _ItemName,
            _OwnerName,
            _ItemDescription,
            _CopyRightMsg,
            _Url,
            false
        );

        _tokenIdTracker.increment();
        
        payable(feeTo).transfer(FEE);

        refundIfOver();

        emit Mint(
            address(0), 
            msg.sender, 
            _tokenId,
            tokenDescriptionMaps[_tokenId].Price,
            block.timestamp,
            tokenDescriptionMaps[_tokenId].ItemName,
            tokenDescriptionMaps[_tokenId].OwnerName,
            tokenDescriptionMaps[_tokenId].ItemDescription,
            tokenDescriptionMaps[_tokenId].CopyRightMsg,
            tokenDescriptionMaps[_tokenId].Url,
            false
        );
    }

    function purchaseWithETH(uint256 _tokenId) external virtual payable nonReentrant {
        address _seller = ownerOf(_tokenId);

        require(tokenDescriptionMaps[_tokenId].isSetPrice == true,"not on sale yet2!");
        require(msg.sender != _seller,"You can't purchase the NFT which is belong to yourself!");
        require(msg.value >= tokenDescriptionMaps[_tokenId].Price,"You don't have enough money to purchase NFT!");
        require(msg.value >= tokenDescriptionMaps[_tokenId].Price + FEE,"You don't have enough money to pay fee!");

        payable(_seller).transfer(tokenDescriptionMaps[_tokenId].Price);

        payable(feeTo).transfer(FEE);

        if(msg.value > tokenDescriptionMaps[_tokenId].Price + FEE) {
            uint bal = msg.value - (tokenDescriptionMaps[_tokenId].Price + FEE);
            payable(msg.sender).transfer(bal);
        }

        _transfer(_seller,msg.sender,_tokenId);

        tokenDescriptionMaps[_tokenId] = TokenDescription(
            _tokenId,
            0,
            msg.sender,
            tokenDescriptionMaps[_tokenId].ItemName,
            tokenDescriptionMaps[_tokenId].OwnerName,
            tokenDescriptionMaps[_tokenId].ItemDescription,
            tokenDescriptionMaps[_tokenId].CopyRightMsg,
            tokenDescriptionMaps[_tokenId].Url,
            false
        );

        emit PurchaseWithEthEvent(
            _seller, 
            msg.sender, 
            msg.value,
            _tokenId,
            block.timestamp,
            tokenDescriptionMaps[_tokenId].ItemName,
            tokenDescriptionMaps[_tokenId].OwnerName,
            tokenDescriptionMaps[_tokenId].ItemDescription,
            tokenDescriptionMaps[_tokenId].CopyRightMsg,
            tokenDescriptionMaps[_tokenId].Url,
            tokenDescriptionMaps[_tokenId].isSetPrice
            );
    }

    function transferNFT(
        address _to,
        uint256 _tokenId
    ) external virtual payable nonReentrant {
        require(msg.sender == ownerOf(_tokenId), "ERC721: caller is not token owner not approved");
        require(msg.value >= FEE,"You don't have enough money to pay fee!");
        require(_to != msg.sender,"You can't purchase the NFT which is belong to yourself!");
        
        payable(feeTo).transfer(FEE);

        refundIfOver();

        _transfer(msg.sender, _to, tokenDescriptionMaps[_tokenId].TokenId);

        tokenDescriptionMaps[_tokenId] = TokenDescription(
            _tokenId,
            0,
            _to,
            tokenDescriptionMaps[_tokenId].ItemName,
            tokenDescriptionMaps[_tokenId].OwnerName,
            tokenDescriptionMaps[_tokenId].ItemDescription,
            tokenDescriptionMaps[_tokenId].CopyRightMsg,
            tokenDescriptionMaps[_tokenId].Url,
            false
        );

        emit TransferNFTEvent(
            msg.sender, 
            _to, 
            _tokenId,
            tokenDescriptionMaps[_tokenId].Price,
            block.timestamp,
            tokenDescriptionMaps[_tokenId].ItemName,
            tokenDescriptionMaps[_tokenId].OwnerName,
            tokenDescriptionMaps[_tokenId].ItemDescription,
            tokenDescriptionMaps[_tokenId].CopyRightMsg,
            tokenDescriptionMaps[_tokenId].Url,
            tokenDescriptionMaps[_tokenId].isSetPrice
            );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        _afterTokenTransfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed"); 
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getLastTokenId() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}