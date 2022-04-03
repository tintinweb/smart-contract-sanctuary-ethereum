/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// File: common/openzeppelin-solidity/contracts/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: common/openzeppelin-solidity/contracts/token/ERC721/IERC721.sol


pragma solidity >=0.6.2 <0.8.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: common/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: common/multi-token-standard/contracts/interfaces/IERC1155.sol

pragma solidity 0.7.4;


interface IERC1155 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

// File: v1/PortionExchange.sol

pragma solidity 0.7.4;




contract PortionExchange {

	string name = "PortionExchange";
	address signer;
	IERC721 public artTokensContract;
	IERC1155 public artTokens1155Contract;
	IERC20 public potionTokensContract;
	uint nonceCounter = 0;

	mapping(uint => uint) public prices;

	struct Erc1155Offer {
		uint tokenId;
		uint quantity;
		uint pricePerToken;
		address seller;
	}
	Erc1155Offer[] public erc1155Offers;

	event TokenListed (uint indexed _tokenId, uint indexed _price, address indexed _owner);
	event TokenSold (uint indexed _tokenId, uint indexed _price, string indexed _currency);
	event TokenDeleted (uint indexed _tokenId, address indexed _previousOwner, uint indexed _previousPrice);
	event TokenOwned (uint indexed _tokenId, address indexed _previousOwner, address indexed _newOwner);

	event Token1155Listed (uint _erc1155OfferId, uint _tokenId, uint _quantity, uint _price, address _owner);
	event Token1155Deleted (
		uint _erc1155OfferId,
		uint _tokenId,
		uint _previousQuantity,
		uint _previousPrice,
		address _previousOwner
	);
	event Token1155Sold(
		uint _erc1155OfferId,
		uint _tokenId,
		uint _quantity,
		uint _price,
		string _currency,
		address _previousOwner,
		address _newOwner
	);
	constructor (address _artTokensAddress, address _artToken1155Address, address _portionTokensAddress) public {
		signer = msg.sender;
		artTokensContract = IERC721(_artTokensAddress);
		artTokens1155Contract = IERC1155(_artToken1155Address);
		potionTokensContract = IERC20(_portionTokensAddress);
		require (_artTokensAddress != address(0), "_artTokensAddress is null");
		require (_artToken1155Address != address(0), "_artToken1155Address is null");
		require (_portionTokensAddress != address(0), "_portionTokensAddress is null");
	}

	function listToken(uint _tokenId, uint _price) external {
		address owner = artTokensContract.ownerOf(_tokenId);
		require(owner == msg.sender, 'message sender is not the owner');
		prices[_tokenId] = _price;
		emit TokenListed(_tokenId, _price, msg.sender);
	}

	function listToken1155(uint _tokenId, uint _quantity, uint _price) external returns (uint) {
		require(artTokens1155Contract.balanceOf(msg.sender, _tokenId) >= _quantity, 'Not enough balance');
		uint tokenListed = 0;
		for (uint i = 0; i < erc1155Offers.length; i++) {
			if (erc1155Offers[i].seller == msg.sender && erc1155Offers[i].tokenId == _tokenId) {
				tokenListed += erc1155Offers[i].quantity;
			}
		}
		require(artTokens1155Contract.balanceOf(msg.sender, _tokenId) >= _quantity + tokenListed, 'Not enough balance');

		erc1155Offers.push(Erc1155Offer({
			tokenId: _tokenId,
			quantity: _quantity,
			pricePerToken: _price,
			seller: msg.sender
		}));
		uint offerId = erc1155Offers.length - 1;

		emit Token1155Listed(offerId, _tokenId, _quantity, _price, msg.sender);

		return offerId;
	}

	function removeListToken(uint _tokenId) external {
		address owner = artTokensContract.ownerOf(_tokenId);
		require(owner == msg.sender, 'message sender is not the owner');
		deleteToken(_tokenId, owner);
	}

	function removeListToken1155(uint _offerId) external {
		require(erc1155Offers[_offerId].seller == msg.sender, 'message sender is not the owner');
		deleteToken1155(_offerId);
	}

	function isValidBuyOrder(uint _tokenId, uint _askPrice) private view returns (bool) {
		require(prices[_tokenId] > 0, "invalid price, token is not for sale");
		return (_askPrice >= prices[_tokenId]);
	}

	function isValidBuyOrder1155(uint _offerId, uint _amount, uint _askPrice) private view returns (bool) {
		require(erc1155Offers[_offerId].pricePerToken > 0, "invalid price, token is not for sale");
		return (_askPrice >= _amount * erc1155Offers[_offerId].pricePerToken);
	}

	function deleteToken(uint _tokenId, address owner) private {
		emit TokenDeleted(_tokenId, owner, prices[_tokenId]);
		delete prices[_tokenId];
	}

	function deleteToken1155(uint _offerId) private {
		emit Token1155Deleted(_offerId, erc1155Offers[_offerId].tokenId, erc1155Offers[_offerId].quantity, erc1155Offers[_offerId].pricePerToken, erc1155Offers[_offerId].seller);
		delete erc1155Offers[_offerId];
	}

	function listingPrice(uint _tokenId) external view returns (uint) {
		return prices[_tokenId];
	}

	function listing1155Price(uint _offerId) external view returns (uint) {
		return erc1155Offers[_offerId].pricePerToken;
	}

	function buyToken(uint _tokenId, uint _nonce) external payable {
		nonceCounter++;
		require(nonceCounter == _nonce, "invalid nonce");

		require(isValidBuyOrder(_tokenId, msg.value), "invalid price");

		address owner = artTokensContract.ownerOf(_tokenId);
		address payable payableOwner = address(uint160(owner));
		payableOwner.transfer(msg.value);
		artTokensContract.safeTransferFrom(owner, msg.sender, _tokenId);
		emit TokenSold(_tokenId, msg.value, "ETH");
		emit TokenOwned(_tokenId, owner, msg.sender);
		deleteToken(_tokenId, owner);
	}

	function buyToken1155(uint _offerId, uint _quantity, uint _nonce) external payable {
		nonceCounter++;
		require(nonceCounter == _nonce, "invalid nonce");
		require(_quantity <= erc1155Offers[_offerId].quantity, "invalid quantity");

		require(isValidBuyOrder1155(_offerId, _quantity, msg.value), "invalid price");

		address owner = erc1155Offers[_offerId].seller;
		address payable payableOwner = address(uint160(owner));
		payableOwner.transfer(msg.value);
		artTokens1155Contract.safeTransferFrom(owner, msg.sender, erc1155Offers[_offerId].tokenId, _quantity, "");
		emit Token1155Sold(_offerId,
			erc1155Offers[_offerId].tokenId,
			_quantity,
			erc1155Offers[_offerId].pricePerToken,
			"ETH",
			owner,
			msg.sender
		);
		if (erc1155Offers[_offerId].quantity == _quantity) {
			deleteToken1155(_offerId);
		} else {
			erc1155Offers[_offerId].quantity -= _quantity;
		}
	}

	function buyTokenForPRT(uint _tokenId, uint256 _amountOfPRT, uint256 _nonce, bytes calldata _signature) external {
		nonceCounter++;
		require(nonceCounter == _nonce, "invalid nonce");

		bytes32 hash = keccak256(abi.encodePacked(_tokenId, _amountOfPRT, _nonce));
		bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		address recoveredSignerAddress = recoverSignerAddress(ethSignedMessageHash, _signature);
		require(recoveredSignerAddress == signer, "invalid secret signer"); // to be sure that the price in PRT is correct

		require(prices[_tokenId] > 0, "invalid price, token is not for sale");

		address owner = artTokensContract.ownerOf(_tokenId);
		potionTokensContract.transferFrom(msg.sender, owner, _amountOfPRT);
		artTokensContract.safeTransferFrom(owner, msg.sender, _tokenId);
		emit TokenSold(_tokenId, _amountOfPRT, "PRT");
		emit TokenOwned(_tokenId, owner, msg.sender);
		deleteToken(_tokenId, owner);
	}

	function buyArtwork1155ForPRT(uint256 _offerId, uint256 _quantity, uint256 _amountOfPRT, uint256 _nonce, bytes calldata _signature) external {
		nonceCounter++;
		require(nonceCounter == _nonce, "invalid nonce");

		bytes32 hash = keccak256(abi.encodePacked(_offerId, _quantity, _amountOfPRT, _nonce));
		bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		address recoveredSignerAddress = recoverSignerAddress(ethSignedMessageHash, _signature);
		require(recoveredSignerAddress == signer, "invalid secret signer"); // to be sure that the price in PRT is correct

		require(erc1155Offers[_offerId].pricePerToken > 0, "invalid price, token is not for sale");

		address owner = erc1155Offers[_offerId].seller;
		potionTokensContract.transferFrom(msg.sender, owner, _amountOfPRT * _quantity);
		artTokens1155Contract.safeTransferFrom(owner, msg.sender, erc1155Offers[_offerId].tokenId, _quantity, "");
		emit Token1155Sold(_offerId,
			erc1155Offers[_offerId].tokenId,
			_quantity,
			_amountOfPRT,
			"PRT",
			owner,
			msg.sender
		);
		if (erc1155Offers[_offerId].quantity == _quantity) {
			deleteToken1155(_offerId);
		} else {
			erc1155Offers[_offerId].quantity -= _quantity;
		}
	}

	function recoverSignerAddress(bytes32 _hash, bytes memory _signature) public pure returns (address) {
		require(_signature.length == 65, "invalid signature length");

		bytes32 r;
		bytes32 s;
		uint8 v;

		assembly {
			r := mload(add(_signature, 32))
			s := mload(add(_signature, 64))
			v := and(mload(add(_signature, 65)), 255)
		}

		if (v < 27) {
			v += 27;
		}

		if (v != 27 && v != 28) {
			return address(0);
		}

		return ecrecover(_hash, v, r, s);
	}

	function getName() external view returns (string memory) {
		return name;
	}

	function getSigner() external view returns (address) {
		return signer;
	}

	function setSigner(address _newSigner) external {
		require(msg.sender == signer, "not enough permissions to change the signer");
		signer = _newSigner;
	}

	function getNextNonce() external view returns (uint) {
		return nonceCounter + 1;
	}

	function getArtwork1155Owner(uint _offerId) external view returns (address) {
		return erc1155Offers[_offerId].seller;
	}
}