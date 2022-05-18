/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract DstageNft1155Auction {  //is SpaceERC20 
    event availableForBids(uint, string) ;
    event removeFormSale (uint, string );
    enum status {NotOnSale ,onAuction, onBidding, OnfixedPrice }
    status public CurrentStatus;
    struct NftDetails{
        uint [] bidAmount;
        uint [] numOfCopies;
        address[] bidderAddress;
        uint startingPrice;
        uint startTime;
        uint endTime;
        bool Exists;
        // Using minimumPrice == minimumBid  
        uint minimumPrice;
        uint index;
        status salestatus;
    }
     // NftOwnerAddress to NftId to NftDetails (Struct) 
    mapping(address=>mapping(uint=>NftDetails)) Nft;
    modifier NftExist (address _owner, uint NftId){
        require(Nft[_owner][NftId].Exists == true , "Not Owner of Nft or Does't Exist ");
        _;
    }
    modifier notOnSale (address owner,uint nftId) {
        require(Nft[owner][nftId].salestatus == status.NotOnSale, "Error! Nft is Already on Sale");
        _;
    }
    modifier onBidding(address owner,uint nftId){
        require(Nft[owner][nftId].salestatus == status.onBidding , "Error! NFT is Not Available for Biding");
        _;
    }
    modifier onSale (address nftOwnerAddress ,uint nftId) {
        require( Nft[nftOwnerAddress][nftId].salestatus != status.NotOnSale, "Error! Nft is Not on Sale");
        _;
    }

    modifier onFixedPrice (address owner, uint nftId){
        require( Nft[owner][nftId].salestatus == status.OnfixedPrice, "NFT is Not Available for Fixed Price");
        _;
    }
//    


//     //Place NFT to Accept Bids
    function _placeNftForBids(address _owner, uint NftId ) notOnSale(_owner,NftId) NftExist(_owner , NftId) internal {
        CurrentStatus = status(2);
        // NftDetails storage NftDetailobj = Nft[NftId];   I think it will create Storage Obj automatically,  Nft[NftId].salestatus  
        Nft[_owner][NftId].salestatus = CurrentStatus;
        emit availableForBids (NftId, "Accepting Bids");
    }



//     // function putOnSale(uint NftId) internal {
//     //     require(Nft[NftId].IsonSale == false, "Not On Sale");
//     //     Nft[NftId].IsonSale = true;
//     // }
    function _pushBidingValues (address nftOwnerAddress,address bidderAddress, uint nftId, uint _bidAmount, uint _numOfCopies) onBidding(nftOwnerAddress,nftId) internal{
        Nft[nftOwnerAddress][nftId].bidAmount.push(_bidAmount);
        Nft[nftOwnerAddress][nftId].bidderAddress.push(bidderAddress);
        Nft[nftOwnerAddress][nftId].numOfCopies.push(_numOfCopies);
    }
    function _placeNftForFixedPrice(address owner ,uint nftId, uint Fixedamount )notOnSale(owner, nftId) NftExist(owner , nftId) internal{ 
        CurrentStatus = status(3);
        Nft[owner][nftId].salestatus = CurrentStatus;
        Nft[owner][nftId].minimumPrice = Fixedamount;
    }

    function _removeFromSale(address ownerAddress, uint nftId) NftExist(ownerAddress,nftId) onSale(ownerAddress,nftId) internal {
        // check Already on Sale 
        CurrentStatus = status(0);
        Nft[ownerAddress][nftId].salestatus = CurrentStatus;
        emit removeFormSale(nftId , "Error! NFT is removed from Sale ");
    }
    function CheckNftStatus(address nftOwner, uint nftId) view external returns(status){
        return Nft[nftOwner][nftId].salestatus;
    }

}


contract DstageNftErc20 {

    event RoyaltiesTransfer(uint, uint, uint);
    struct royaltyInfo {
        address payable recipient;
        uint24 amount;
    }
    mapping (address => uint) deposits;
    mapping(uint256 => royaltyInfo) _royalties;
    mapping (address=>bool) DstageNftWhiteList;
    function _setTokenRoyalty(uint256 tokenId,address payable recipient,uint256 value) internal {
        require(value <= 50, "Error! Too high Royalties");
        _royalties[tokenId] = royaltyInfo(recipient, uint24(value));
    }

    function _royaltyAndDstageNftFee (uint _NftPrice, uint percentage, address payable minterAddress, address payable NftSeller) internal  {
        uint _TotalNftPrice = msg.value;                                // require(msg.value >= NftPrice[NftId], "Error! Insufficent Balance");
        uint _DstageNftFee = _deductDstageNftFee(_NftPrice);
        uint _minterFee = _SendMinterFee(_NftPrice , percentage,  minterAddress);
        _TotalNftPrice = _TotalNftPrice - _DstageNftFee - _minterFee;    //Remaining Price After Deduction  
        _transferAmountToSeller( _TotalNftPrice, NftSeller);            // Send Amount to NFT Seller after Tax deduction
        emit RoyaltiesTransfer(_DstageNftFee,_minterFee, _TotalNftPrice);
    }

    function _deductDstageNftFee(uint Price) internal pure returns(uint) {
        require((Price/10000)*10000 == Price, "Error! Too small");
        return Price*25/1000;
    }
    
    function _transferAmountToSeller(uint amount, address payable seller) internal {
        seller.transfer(amount);
    }

    function _SendMinterFee(uint _NftPrice, uint Percentage, address payable recepient) internal returns(uint) {
        uint AmountToSend = _NftPrice*Percentage/100;           //Calculate Minter percentage and Send to his Address from Struct
        recepient.transfer(AmountToSend);                       // Send this Amount To Transfer Address from Contract balacne
        return AmountToSend;
    }
    function depositBidAmmount(address payee,uint amountToDeposit) internal {
        require(msg.value == amountToDeposit, "Error while Deposit");
        deposits[payee] += amountToDeposit;
    }
    function deductAmount(address from, uint amount) internal {
        require(deposits[from]>0 && amount <= deposits[from] , "Error! Low Balance");
        deposits[from] -= amount;
    }

}
// File: DstageNft1155/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// File: DstageNft1155/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)


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
// File: DstageNft1155/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// File: DstageNft1155/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)


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
// File: DstageNft1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
// File: DstageNft1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)


// import "../../utils/introspection/IERC165.sol";


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155  is IERC165{
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

}
// File: DstageNft1155/ERC1155.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)




/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155 {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }


    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);
        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }


    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
// File: DstageNft1155/ERC1155Burnable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/ERC1155Burnable.sol)

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}
// File: DstageNft1155/DstageNft1155.sol


// Constraints for wei and Ethers in fixed amount and royalties
// Burn only owner // Open Bidding 
pragma experimental ABIEncoderV2;




contract DstageNft1155 is ERC1155, ERC1155Burnable, DstageNftErc20 ,DstageNft1155Auction { 

    mapping (uint => bool) nftExists;
    mapping (uint=>string)TokenURI;
    
    // NFT ID to Price
    mapping (address=>mapping(uint=>uint)) NFT_Price;

    // Too Check token Exixtance
    
    modifier TokenNotExist( uint nftId){
        require(nftExists[nftId]==false , "Token Already Exists");
        _;
    }
    modifier contractIsNotPaused(){
        require (IsPaused == false, "Contract is Paused" );
        _;
    }

    function CheckNftPrice(address owner, uint id) public view returns(uint){
        return NFT_Price[owner][id];
    }

    modifier OnlyOwner {
        require(_msgSender() == Owner, "DstageNft Owner can Access");
        _;
    }

    bool public IsPaused = true;
    address payable public  Owner;
    string private _name;
    
    constructor (string memory name){
        _name = name;
        Owner = payable(msg.sender);
    }

    /* Direct Minting on Blockchain 
    ** No Fee and Taxes on Minting
    ** Want to mint his own Address direct BVlockchain
    ** TokenURI is IPFS hash and will Get from Web3
    */
    function simpleMint (uint nftId, uint amount,  bytes memory data, string memory tokenURI, uint RoyaltyValueOfMinter ) contractIsNotPaused TokenNotExist(nftId) public {
        _mint(_msgSender(), nftId, amount, data);
        TokenURI[nftId] = tokenURI;
        _setTokenRoyalty(nftId, payable(_msgSender()), RoyaltyValueOfMinter);
        nftExists[nftId] = true;
        Nft[_msgSender()][nftId].Exists=true;
    }

    // localy Minted and Want to Mint directlty on Purchaser Address
    // Will Accept Payments For NFTs 
    // Deduct Royalties and DstageNft Fee
    // Buyer Is Insiating Transaction himself
    // MinterAddress, RoyaltyValueOfMinter, NftPrice will get from Web3
    function LocalMintedNfts (address to, uint id, uint amount, bytes memory data, string memory tokenURI, uint NftPrice, address payable MinterAddress, uint RoyaltyValueOfMinter) public payable{
        require(IsPaused == false, "Contract is Paused");
        require(msg.value>=NftPrice*amount, "Error! Insufficient Balance ");
        _mint(to, id, amount, data);
        TokenURI[id] = tokenURI;
        NFT_Price[to][id]= NftPrice;
        _setTokenRoyalty(id,MinterAddress, RoyaltyValueOfMinter);
        //Send Amount to Local Minter
        // Deduct Royalties
        _royaltyAndDstageNftFee(NftPrice*amount, RoyaltyValueOfMinter, MinterAddress, MinterAddress );
    }
    // Batch Minting Public Function
    // Direct minting on Blockchain 
    function MintBatch(address to, uint[] memory ids, uint[] memory amounts, string[] memory TokenUriArr, bytes memory data, uint[] memory RoyaltyValue) external{
        
        require(IsPaused == false, "Contract is Paused");
        require(ids.length == TokenUriArr.length, "TokenURI and Token ID Length Should be Same");
        _mintBatch(to, ids, amounts, TokenUriArr ,data, RoyaltyValue );
    }

    //Batch Minting Direct on Blockchain Internal Function
    function _mintBatch(address to,uint256[] memory ids,uint256[] memory amounts,string[] memory Uri,bytes memory data, uint[] memory RoyaltyValue) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        //Add check that he is only able to Add tokens in his own NFts if ID exists already
        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
            TokenURI[ids[i]] = Uri[i];
            _setTokenRoyalty(ids[i], payable(_msgSender()), RoyaltyValue[i]);
        }
        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function IncrementInExistingTokens(address Add, uint id, uint Amount, bytes memory data) public {
        //Check TokenID Already has Balance or Not
        require(balanceOf(Add,id)>0, "Error! Use Function With URI");
        //Only Owner of that Token can Increment check owner or token Now check Approved or not
        require(_msgSender() == Add || isApprovedForAll(Add, _msgSender()), "Only Owner and Approved Address can Increment");
        _mint(Add, id, Amount , data);
    }

    /*  function BuyerOfNft
    **  Will Transfer NFTs and Deduct Amount and Will forward to Addresses 
    **  Will just Pay royalties 
    **  Get minter Address from Struct recipient 
    **  Get NFT price
    */
    function DstageNftsafeTransferFrom(address from, address to, uint id, uint amount, bytes memory data ) internal {
        _royaltyAndDstageNftFee( ((NFT_Price[from][id])*amount), _royalties[id].amount, _royalties[id].recipient, payable(from));
        _safeTransferFrom(from, to, id, amount, data);
        delete NFT_Price[from][id];
        NFT_Price[to][id]= msg.value/amount;
        Nft[to][id].Exists = true;
    } 
    
    //Function To Switch Sale State in Bool
    function SwitchSaleState() public OnlyOwner {
        if (IsPaused == true){
            IsPaused = false;
        }
        else {
            IsPaused = true;
        }
    }

    //To WithDraw All Ammount from Contract to Owners Address 
    function withDraw(address payable to) public payable OnlyOwner {
        uint Balance = address(this).balance;
        require(Balance > 0 wei, "Error! No Balance to withdraw"); 
        to.transfer(Balance);
    }   

    //To Check Contract Balance in Wei
    function ContractBalance() public view OnlyOwner returns (uint){
        return address(this).balance;
    }
    //Return Tokens IPFS URI against Address and ID
    function TokenUri(uint id) public view returns(string memory){
        require(bytes(TokenURI[id]).length != 0, "Token ID Does Not Exist");
        return TokenURI[id];
    }

    //Extra Function For Testing
    function checkFirstMinter( uint t_id ) view public returns(royaltyInfo memory){
        royaltyInfo memory object = _royalties[t_id];
        return object;
    }
    function mintForOpenBidding (uint nftId, uint amount,  bytes memory data, string memory tokenURI, uint RoyaltyValueOfMinter ) contractIsNotPaused TokenNotExist(nftId) external{
        simpleMint (nftId,  amount,  data, tokenURI, RoyaltyValueOfMinter );
        _placeNftForBids(_msgSender(),nftId);
    }
    function mintForFixedPrice (uint nftId, uint amount,  bytes memory data, string memory tokenURI, uint RoyaltyValueOfMinter, uint fixPriceOfNft ) contractIsNotPaused TokenNotExist(nftId) external{
        simpleMint (nftId,  amount,  data, tokenURI, RoyaltyValueOfMinter );
        _placeNftForFixedPrice(_msgSender(), nftId , fixPriceOfNft);
        NFT_Price[_msgSender()][nftId] = fixPriceOfNft;

    }
    function placeNftForOpenBidding(uint nftId) external{
        _placeNftForBids(_msgSender(),nftId);        
    }
    function placeNftForFixedAmount(uint nftId, uint fixPriceOfNft ) external {
        _placeNftForFixedPrice( _msgSender() , nftId, fixPriceOfNft );
        NFT_Price[_msgSender()][nftId] = fixPriceOfNft;
    }
    function purchaseAgainstFixedPrice ( address from, address to, uint nftId, uint amountOfNft) external payable{
        if (deposits[_msgSender()] < NFT_Price[from][nftId]*amountOfNft){
            depositBidAmmount(_msgSender(), msg.value);
        }
        require(NFT_Price[from][nftId]*amountOfNft <= deposits[_msgSender()] && amountOfNft > 0, "Error while Purchasing" );
        deductAmount(_msgSender(), NFT_Price[from][nftId]*amountOfNft);
        DstageNftsafeTransferFrom(from,  to,  nftId, amountOfNft, "Data");
    }
    function removeFromSale(uint nftId) external 
    {
        _removeFromSale(_msgSender(), nftId);
    }
    function addBid (address nftOwner, uint nftId, uint bidAmount, uint numOfCopies) external payable{
        if (deposits[_msgSender()] < bidAmount){
            depositBidAmmount(_msgSender(), msg.value);
        }
        require(deposits[_msgSender()] >= bidAmount && numOfCopies > 0 && nftExists[nftId] == true, "Error while Purchasing" );
        _pushBidingValues ( nftOwner,_msgSender(), nftId, bidAmount, numOfCopies);
    }
    function acceptBids (uint nftId,uint index ) external onBidding(_msgSender(), nftId) {
        // Check has enough number of copies 
        NftDetails memory obj = Nft[_msgSender()][nftId];
        require (obj.Exists == true && deposits[obj.bidderAddress[index]]>= obj.bidAmount[index], "Error while Accepting Bids" );
        deductAmount(obj.bidderAddress[index], obj.bidAmount[index]);
        DstageNftsafeTransferFrom(_msgSender(), obj.bidderAddress[index], nftId,  obj.numOfCopies[index], "" ); 
    }

}