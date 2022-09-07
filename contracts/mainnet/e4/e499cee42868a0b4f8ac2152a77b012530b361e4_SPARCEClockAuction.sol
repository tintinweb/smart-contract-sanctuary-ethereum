/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IERC721 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract SignatureVerifier {
    using ECDSA for bytes32;
    
    bytes32 public constant SIGNATURE_PERMIT_TYPEHASH = keccak256("validateSig(address _nft, uint _amount, uint _nonce, bytes memory signature)");
    uint public chainId;
    
    struct ValidatorInfo {
        uint nonce;
        mapping(bytes => bool) signature;
    }
    
    mapping(address => ValidatorInfo) validateInfo;
    
    constructor() {
        uint _chainId;
        assembly {
            _chainId := chainid()
        }
        
        chainId = _chainId;
    }
    
    function validateSig(address _owner, address _nft, uint _amount, uint _nonce, bytes memory signature) public view returns (address){
      // This recreates the message hash that was signed on the client.
      bytes32 hash = keccak256(abi.encodePacked(SIGNATURE_PERMIT_TYPEHASH, _owner, _nft, _amount, _nonce, chainId));
      bytes32 messageHash = hash.toSignedMessageHash();
    
      // Verify that the message's signer is the owner of the order
      return messageHash.recover(signature);
    }
}

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables with inline assembly.
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

interface ICollarQuest is IERC721 {
  function getSparce(
    uint256 _sparceId
  )
    external
    view
    returns (uint256 /* _genes */, uint256 /* _bornAt */, address /* _operator */, bool /* _newlyBorn */);

  function UpdateNewBornSparce( uint _sparceId) external;
}

contract SPARCEClockAuction is Pausable, Ownable, SignatureVerifier {
  enum Operations {Market,Breeder}
  
  ICollarQuest public collarQuest;

  struct Auction {
    address seller;
    address operator;
    uint startingPrice;
    uint endingPrice;
    uint duration;
    uint startedAt;
    bool newBorn;
  }

  struct Fees {
    uint256 daoFee;
    uint256 royalityFee;
  }

  uint256 constant DIVISOR = 10000;
  address public treasury;
  address public breedingContract;
  address public signer;
  
  // Map from token ID to their corresponding auction.
  mapping (address => mapping (uint256 => Auction)) public auctions;
  mapping(bool => mapping(uint8 => Fees)) public feeStruct;

  // stores verified signatures
  mapping(bytes => bool) public isVerified;

  // returns current nonce of address
  mapping(address => uint256) public nonce;

  event AuctionCreated(
    address indexed _nftAddress,
    uint256 indexed _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  );

  event AuctionSuccessful(
    address indexed _nftAddress,
    uint256 indexed _tokenId,
    uint256 _totalPrice,
    address _winner
  );

  event AuctionCancelled(
    address indexed _nftAddress,
    uint256 indexed _tokenId
  );

  constructor(ICollarQuest _collarQuest, address _treasury, address _signer) {
    treasury = _treasury;
    signer = _signer;
    collarQuest = _collarQuest;
    feeStruct[true][uint8(Operations.Market)] = Fees(1000, 0);
    feeStruct[true][uint8(Operations.Breeder)] = Fees(500, 0);
    feeStruct[false][uint8(Operations.Breeder)] = feeStruct[false][uint8(Operations.Market)] = Fees(500, 500);
  }

  fallback () external {}

  /// @dev Returns auction info for an NFT on auction.
  /// @param _nftAddress - Address of the NFT.
  /// @param _tokenId - ID of NFT on auction.
  function getAuction(
    address _nftAddress,
    uint256 _tokenId
  )
    external
    view
    returns (
      address seller,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 duration,
      uint256 startedAt,
      address operator,
      bool newBorn
    )
  {
    Auction storage _auction = auctions[_nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    return (
      _auction.seller,
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      _auction.startedAt,
      _auction.operator,
      _auction.newBorn
    );
  }

  /// @dev Returns the current price of an auction.
  /// @param _nftAddress - Address of the NFT.
  /// @param _tokenId - ID of the token price we are checking.
  function getCurrentPrice(
    address _nftAddress,
    uint256 _tokenId
  )
    external
    view
    returns (uint256)
  {
    Auction storage _auction = auctions[_nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    return _getCurrentPrice(_auction);
  }

  /// @dev Creates and begins a new auction.
  /// @param _nftAddress - address of a deployed contract implementing
  ///  the Nonfungible Interface.
  /// @param _tokenId - ID of token to auction, sender must be owner.
  /// @param _startingPrice - Price of item (in wei) at beginning of auction.
  /// @param _endingPrice - Price of item (in wei) at end of auction.
  /// @param _duration - Length of time to move between starting
  ///  price and ending price (in seconds).
  function createAuction(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
    external
    whenNotPaused
  {
    address _seller = msg.sender;
    require(_owns(_nftAddress, _seller, _tokenId));
    
    (, , address _operator, bool _newlyBorn ) =  collarQuest.getSparce(_tokenId);
    _escrow(_nftAddress, _seller, _tokenId);    

    Auction memory _auction = Auction({
      seller : _seller,
      operator : _operator,
      startingPrice : _startingPrice,
      endingPrice : _endingPrice,
      duration : _duration,
      startedAt : block.timestamp,
      newBorn : _newlyBorn
    });

    _addAuction(
      _nftAddress,
      _tokenId,
      _auction,
      _seller
    );
  }

  /// @dev Bids on an open auction, completing the auction and transferring
  ///  ownership of the NFT if enough Ether is supplied.
  /// @param _nftAddress - address of a deployed contract implementing
  ///  the Nonfungible Interface.
  /// @param _tokenId - ID of token to bid on.
  function bid(
    address _nftAddress,
    address royalityAddress,
    uint256 _tokenId,
    bytes calldata signature
  )
    external
    payable
    whenNotPaused
  {
    require(!isVerified[signature], "signature already verified");
    require(validateSig( msg.sender, _nftAddress, msg.value, nonce[msg.sender],signature) == signer,"Signature invalid");

    nonce[msg.sender]++;
    isVerified[signature] = true;
    bool _newBorn = auctions[_nftAddress][_tokenId].newBorn;

    // _bid will throw if the bid or funds transfer fails
    _bid(_nftAddress, royalityAddress, _tokenId, msg.value);
    
    if(_nftAddress == address(collarQuest)) {
      if(_newBorn) {
        collarQuest.UpdateNewBornSparce(_tokenId);
      }
    }

    _transfer(_nftAddress, msg.sender, _tokenId);
  }

  /// @dev Cancels an auction that hasn't been won yet.
  ///  Returns the NFT to original owner.
  /// @notice This is a state-modifying function that can
  ///  be called while the contract is paused.
  /// @param _nftAddress - Address of the NFT.
  /// @param _tokenId - ID of token on auction
  function cancelAuction(address _nftAddress, uint256 _tokenId) external {
    Auction storage _auction = auctions[_nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    require(msg.sender == _auction.seller);
    _cancelAuction(_nftAddress, _tokenId, _auction.seller);
  }

  /// @dev Cancels an auction when the contract is paused.
  ///  Only the owner may do this, and NFTs are returned to
  ///  the seller. This should only be used in emergencies.
  /// @param _nftAddress - Address of the NFT.
  /// @param _tokenId - ID of the NFT on auction to cancel.
  function cancelAuctionWhenPaused(
    address _nftAddress,
    uint256 _tokenId
  )
    external
    whenPaused
    onlyOwner
  {
    Auction storage _auction = auctions[_nftAddress][_tokenId];
    require(_isOnAuction(_auction));
    _cancelAuction(_nftAddress, _tokenId, _auction.seller);
  }

  function setBreederContract( address _breedingContract) external onlyOwner {
    breedingContract = _breedingContract;
  }

  function setSigner( address _signer) external onlyOwner {
    signer = _signer;
  }

  function setTreasury( address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function setCollarQuest( ICollarQuest _collarQuest) external onlyOwner {
        collarQuest = _collarQuest;
    }

  function setPrimaryDAOFee( uint8 _type, uint _daoFee) external onlyOwner {
    require(_type <= uint8(Operations.Breeder));
    require(_daoFee <= DIVISOR);
    feeStruct[true][uint8(_type)].daoFee = _daoFee;
  }

  function setPrimaryRoyalityFee(uint8 _type, uint _royalityFee) external onlyOwner {
    require(_type <= uint8(Operations.Breeder));
    require(_royalityFee <= DIVISOR);
    feeStruct[true][uint8(_type)].royalityFee = _royalityFee;
  }

  function setSecondaryDAOFee(uint8 _type, uint _daoFee) external onlyOwner {
    require(_type <= uint8(Operations.Breeder));
    require(_daoFee <= DIVISOR);
    feeStruct[false][uint8(_type)].daoFee = _daoFee;
  }

  function setSecondaryRoyalityFee(uint8 _type, uint _royalityFee) external onlyOwner {
    require(_type <= uint8(Operations.Breeder));
    require(_royalityFee <= DIVISOR);
    feeStruct[false][uint8(_type)].royalityFee = _royalityFee;
  }

  /// @dev Returns true if the NFT is on auction.
  /// @param _auction - Auction to check.
  function _isOnAuction(Auction storage _auction) internal view returns (bool) {
    return (_auction.startedAt > 0);
  }

  /// @dev Gets the NFT object from an address, validating that implementsERC721 is true.
  /// @param _nftAddress - Address of the NFT.
  function _getNftContract(address _nftAddress) internal pure returns (IERC721) {
    IERC721 candidateContract = IERC721(_nftAddress);
    // require(candidateContract.implementsERC721());
    return candidateContract;
  }

  /// @dev Returns current price of an NFT on auction. Broken into two
  ///  functions (this one, that computes the duration from the auction
  ///  structure, and the other that does the price computation) so we
  ///  can easily test that the price computation works correctly.
  function _getCurrentPrice(
    Auction storage _auction
  )
    internal
    view
    returns (uint256)
  {
    uint256 _secondsPassed = 0;

    if (block.timestamp > _auction.startedAt) {
      _secondsPassed = block.timestamp - _auction.startedAt;
    }

    return _computeCurrentPrice(
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      _secondsPassed
    );
  }

  /// @dev Computes the current price of an auction. Factored out
  ///  from _currentPrice so we can run extensive unit tests.
  ///  When testing, make this function external and turn on
  ///  `Current price computation` test suite.
  function _computeCurrentPrice(
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    uint256 _secondsPassed
  )
    internal
    pure
    returns (uint256)
  {
    if (_secondsPassed >= _duration) {
      return _endingPrice;
    } else {
      int256 _totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
      int256 _currentPriceChange = _totalPriceChange * int256(_secondsPassed) / int256(_duration);
      int256 _currentPrice = int256(_startingPrice) + _currentPriceChange;

      return uint256(_currentPrice);
    }
  }

  /// @dev Returns true if the claimant owns the token.
  /// @param _nftAddress - The address of the NFT.
  /// @param _claimant - Address claiming to own the token.
  /// @param _tokenId - ID of token whose ownership to verify.
  function _owns(address _nftAddress, address _claimant, uint256 _tokenId) internal view returns (bool) {
    IERC721 _nftContract = _getNftContract(_nftAddress);
    return (_nftContract.ownerOf(_tokenId) == _claimant);
  }

  /// @dev Adds an auction to the list of open auctions. Also fires the
  ///  AuctionCreated event.
  /// @param _tokenId The ID of the token to be put on auction.
  /// @param _auction Auction to add.
  function _addAuction(
    address _nftAddress,
    uint256 _tokenId,
    Auction memory _auction,
    address _seller
  )
    internal
  {
    // Require that all auctions have a duration of
    // at least one minute. (Keeps our math from getting hairy!)
    require(_auction.duration >= 1 minutes);
    auctions[_nftAddress][_tokenId] = _auction;

    emit AuctionCreated(
      _nftAddress,
      _tokenId,
      uint256(_auction.startingPrice),
      uint256(_auction.endingPrice),
      uint256(_auction.duration),
      _seller
    );
  }

  /// @dev Removes an auction from the list of open auctions.
  /// @param _tokenId - ID of NFT on auction.
  function _removeAuction(address _nftAddress, uint256 _tokenId) internal {
    delete auctions[_nftAddress][_tokenId];
  }

  /// @dev Cancels an auction unconditionally.
  function _cancelAuction(address _nftAddress, uint256 _tokenId, address _seller) internal {
    _removeAuction(_nftAddress, _tokenId);
    _transfer(_nftAddress, _seller, _tokenId);
    emit AuctionCancelled(_nftAddress, _tokenId);
  }

  /// @dev Escrows the NFT, assigning ownership to this contract.
  /// Throws if the escrow fails.
  /// @param _nftAddress - The address of the NFT.
  /// @param _owner - Current owner address of token to escrow.
  /// @param _tokenId - ID of token whose approval to verify.
  function _escrow(address _nftAddress, address _owner, uint256 _tokenId) internal {
    IERC721 _nftContract = _getNftContract(_nftAddress);
    
    _nftContract.transferFrom(_owner, address(this), _tokenId);
  }

  /// @dev Transfers an NFT owned by this contract to another address.
  /// Returns true if the transfer succeeds.
  /// @param _nftAddress - The address of the NFT.
  /// @param _receiver - Address to transfer NFT to.
  /// @param _tokenId - ID of token to transfer.
  function _transfer(address _nftAddress, address _receiver, uint256 _tokenId) internal {
    IERC721 _nftContract = _getNftContract(_nftAddress);
    _nftContract.transferFrom(address(this), _receiver, _tokenId);
  }

  /// @dev Computes the price and transfers winnings.
  /// Does NOT transfer ownership of token.
  function _bid(
    address _nftAddress,
    address _royalityAddress,
    uint256 _tokenId,
    uint256 _bidAmount
  )
    internal
    returns (uint256)
  {
    Auction storage _auction = auctions[_nftAddress][_tokenId];

    require(_isOnAuction(_auction));
    uint256 _price = _getCurrentPrice(_auction);
    require(_bidAmount >= _price);
    address _seller = _auction.seller;
     (address _operator, bool _newlyBorn) = (_auction.operator,_auction.newBorn);
    _removeAuction(_nftAddress, _tokenId);

    if (_price > 0) {
      (uint _royalityFee, uint _daoFee, uint _sellerProceeds) = _calculateSaleRoyality(_nftAddress,_operator, _newlyBorn, _price);

      if(_daoFee > 0)
        payable(treasury).transfer(_daoFee);

      if(_sellerProceeds > 0)
        payable(_seller).transfer(_sellerProceeds);
      
      if(_royalityFee > 0)
        payable(_royalityAddress).transfer(_royalityFee);
    }

    if (_bidAmount > _price) {
      uint256 _bidExcess = _bidAmount - _price;
      payable(msg.sender).transfer(_bidExcess);
    }

    emit AuctionSuccessful(
      _nftAddress,
      _tokenId,
      _price,
      msg.sender
    );

    return _price;
  }

  function _calculateSaleRoyality(
    address _nftAddress, 
    address _operator, 
    bool _newlyBorn, 
    uint price
  ) 
    private
    view 
    returns (uint _royalityFee, uint _daoFee, uint _price) 
  {
    if(_nftAddress != address(collarQuest)) {
      return (_royalityFee,_daoFee,_price);
    }

    uint8 _sale = isBreederContract(_operator);
    _royalityFee = (price * feeStruct[_newlyBorn][_sale].royalityFee) / DIVISOR;
    _daoFee = (price * feeStruct[_newlyBorn][_sale].daoFee) / DIVISOR;
    _price = price - (_royalityFee + _daoFee);
  }

  function isBreederContract(address operator) private view returns (uint8 _type) {
    _type = (operator == breedingContract) ? uint8(Operations.Breeder) : uint8(Operations.Market);
  }
}