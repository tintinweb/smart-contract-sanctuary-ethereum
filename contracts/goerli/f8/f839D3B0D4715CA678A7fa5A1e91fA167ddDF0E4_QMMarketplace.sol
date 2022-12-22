/*                                                                                                             
      # ###                                                       #####   ##    ##                ##            
    /  /###                                                    ######  /#### #####                 ##           
   /  /  ###                                                  /#   /  /  ##### #####               ##           
  /  ##   ###                                                /    /  /   # ##  # ##                ##           
 /  ###    ###                                                   /  /    #     #                   ##           
##   ##     ## ##   ####      /##       /##  ###  /###          ## ##    #     #      /###     ### ##    /##    
##   ##     ##  ##    ###  / / ###     / ###  ###/ #### /       ## ##    #     #     / ###  / ######### / ###   
##   ##     ##  ##     ###/ /   ###   /   ###  ##   ###/        ## ##    #     #    /   ###/ ##   #### /   ###  
##   ##     ##  ##      ## ##    ### ##    ### ##    ##         ## ##    #     #   ##    ##  ##    ## ##    ### 
##   ##     ##  ##      ## ########  ########  ##    ##         ## ##    #     ##  ##    ##  ##    ## ########  
 ##  ## ### ##  ##      ## #######   #######   ##    ##         #  ##    #     ##  ##    ##  ##    ## #######   
  ## #   ####   ##      ## ##        ##        ##    ##            /     #      ## ##    ##  ##    ## ##        
   ###     /##  ##      /# ####    / ####    / ##    ##        /##/      #      ## ##    ##  ##    /# ####    / 
    ######/ ##   ######/ ## ######/   ######/  ###   ###      /  #####           ## ######    ####/    ######/  
      ###   ##    #####   ## #####     #####    ###   ###    /     ##                ####      ###      #####   
            ##                                               #                                                  
            /                                                 ##                                                                                                                                                
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract QMMarketplace {
  mapping(bytes32 => Offer) public offers;
  uint256 public deltaInWei;
  AggregatorV3Interface internal priceFeedContract;

  struct Offer {
    IERC721 collection;
    uint256 tokenId;
    uint96 priceInUsd;
    uint96 discountedPriceForHoldersInUsd;
  }

  event NftBought(address _collection, uint256 _tokenId, address _seller, address _buyer, uint256 _price);
  event NftOnSale(bytes32 _offerHash, address _collection, uint256 _tokenId, uint96 _priceInUsd);

  /**
   * Constructs the instance of a contract.
   * @param _priceFeedContract is the oracle to convert USD to ETH.
   */
  constructor(address _priceFeedContract, uint256 _deltaInWei) {
    priceFeedContract = AggregatorV3Interface(_priceFeedContract);
    deltaInWei = _deltaInWei;
  }

  function putOnSale(IERC721 _collection, uint256[] memory _tokenIds, uint96[] memory _pricesInUsd, uint96[] memory _discountedPricesForHoldersInUsd) external {
    require(_tokenIds.length == _pricesInUsd.length && _pricesInUsd.length == _discountedPricesForHoldersInUsd.length, 'The sizes do not match');
    for (uint i = 0; i < _tokenIds.length; i++) {
      putOnSale(_collection, _tokenIds[i], _pricesInUsd[i], _discountedPricesForHoldersInUsd[i]);
    }
  }

  /**
   * Puts a @param _tokenId from @param _collection on sale with defined @param _priceInUsd.
   * It is required to approve usage of a token to this contract before this function is called.
   * Emits NftOnSale event when successful.
   */
  function putOnSale(IERC721 _collection, uint256 _tokenId, uint96 _priceInUsd, uint96 _discountedPriceForHoldersInUsd) public {
    require(_collection.ownerOf(_tokenId) == msg.sender, 'You do not own this NFT');
    require(isApproved(msg.sender, _collection, _tokenId), 'It is required to approve for selling');

    bytes32 offerHash = getOfferHash(_collection, _tokenId);
    offers[offerHash] = Offer({
        collection: _collection,
        tokenId: _tokenId,
        priceInUsd: _priceInUsd,
        discountedPriceForHoldersInUsd: _discountedPriceForHoldersInUsd
    });
    
    emit NftOnSale(offerHash, address(_collection), _tokenId, _priceInUsd);
  }
  
  /**
   * Allows to purchase a @param _tokenId from @param _collection and sends it to @param _receiver.
   * ETH value sent must be enough for purchasing.
   * Emits NftBought event when successful.
   */
  function purchase(IERC721 _collection, uint256 _tokenId, address _receiver) external payable {
    bytes32 offerHash = getOfferHash(_collection, _tokenId);
    Offer memory offer = offers[offerHash];
    require(address(offer.collection) != address(0x0), 'No offer found');
    uint96 priceInUsd = getPriceInUsd(_receiver, _collection, _tokenId);
    uint256 priceInWei = getConversionRate(priceInUsd);
    require(msg.value + deltaInWei >= priceInWei, 'Not enough ETH');
    address payable seller = payable(IERC721(offer.collection).ownerOf(offer.tokenId));

    Address.sendValue(seller, priceInWei);
    IERC721(offer.collection).transferFrom(seller, _receiver, offer.tokenId);

    delete offers[offerHash];

    emit NftBought(address(offer.collection), offer.tokenId, seller, _receiver, msg.value);
  }

  /**
   * Generates the hash based on @param _collection and @param _tokenId.
   */
  function getOfferHash(IERC721 _collection, uint256 _tokenId) internal pure returns(bytes32) {
    return keccak256(abi.encodePacked(_collection, _tokenId));
  }

  /**
   * To get latest price of ether in wei to buy an NFT.
   */
  function getConversionRate(uint96 valueInUsd) public view returns (uint256) {
      (, int256 price, , , ) = priceFeedContract.latestRoundData();
      uint256 ethAmountInWei = ((1 * 10**26) * valueInUsd) / uint256(price);
      return ethAmountInWei;
  }
  
  /**
   * Checks if an approval was give to marketplace contract from @param _owner of @param _tokenId from @param _collection.
   */
  function isApproved(address _owner, IERC721 _collection, uint256 _tokenId) internal view returns(bool) {
    return _collection.isApprovedForAll(_owner, address(this)) || _collection.getApproved(_tokenId) == address(this);
  }

  /**
   * Returns the price in USD based on ownership of any token in a @param _collection by a @param wallet.
   */
  function getPriceInUsd(address _wallet, IERC721 _collection, uint256 _tokenId) public view returns (uint96) {
    bytes32 offerHash = getOfferHash(_collection, _tokenId);
    Offer memory offer = offers[offerHash];
    if (isNotHolder(_wallet, _collection)) {
      // normal price for non-holders and non-existing accounts
      return offer.priceInUsd;
    }
    // discounted price for holders
    return offer.discountedPriceForHoldersInUsd;
  }

  /**
   * Identifies whether @param _wallet holds any tokens of a @param _collection.
   * Returns true if a wallet is not holder and false if a wallet is a holder.
   */
  function isNotHolder(address _wallet, IERC721 _collection) internal view returns (bool) {
    return _wallet == address(0x0) || _collection.balanceOf(_wallet) == 0;
  }

  /**
   * Returns the Offer object based on @param _collection and @param _tokenId.
   */
  function getOfferPriceInUsd(IERC721 _collection, uint256 _tokenId) public view returns (Offer memory) {
    bytes32 offerHash = getOfferHash(_collection, _tokenId);
    Offer memory offer = offers[offerHash];
    return offer;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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