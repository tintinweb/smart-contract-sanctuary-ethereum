pragma solidity 0.8.7;

import "EnumerableERC721.sol";
import "SameRoyaltiesForAll.sol";
import "String.sol";
import "Uint.sol";
import "Punchable.sol";
import "SelfDestructable.sol";

interface Stoney{

    function balanceOf(address _address) external view returns(uint);
}

contract MetaboardsGen2 is EnumerableERC721, SameRoyaltiesForAll, Punchable, SelfDestructable{

    using String for string;
    using Uint for uint;

    Stoney public immutable stoney_contract;
    uint16 private immutable maxTokens;
    uint16 public immutable maxMintsAtOnce;
    uint8 public immutable maxEarlyMints;
    uint16 public startingIndex;
    uint public reveal_time;
    mapping(address => uint8) public whitelist;
    uint public price;
    uint public discount;// 1 -> 0.01%, 500 -> 5%, 1500 -> 15%
    uint public contractBalance;
    bool public whitelistMintActive;
    bool public regularMintActive;
    uint internal nextTID;

    event SecurityWithdrawal(uint amount);
    event Withdrawal(address indexed _to, uint _value);

    constructor(
                address _stoney_contract,
                address[] memory _whitelist, 
                string memory _base_uri,
                uint _price,
                uint _discount,
                uint16 _maxMintsAtOnce, 
                uint8 _maxEarlyMints,
                uint16 maxSupply,
                string memory _name, 
                string memory _symbol
                ) EnumerableERC721(_name, _symbol){ 
        stoney_contract = Stoney(_stoney_contract);
        maxTokens = maxSupply;
        price = _price;
        discount = _discount;
        maxMintsAtOnce = _maxMintsAtOnce;
        maxEarlyMints = _maxEarlyMints;
        for( uint i=0; i < _whitelist.length; i++ ){
            whitelist[_whitelist[i]]=_maxEarlyMints;
        }
        base_uri =_base_uri;
    }

    receive() external  payable
    {
        contractBalance += msg.value;
    }

    function nftsLeftToMint() external view returns (uint) {
        return maxTokens - totalSupply();
    }

    function addWhitelistedAddress(address newAddress) external onlyOwner {
        whitelist[newAddress]=maxEarlyMints;
    }

    function removeWhitelistedAddress(address oldAddress) external onlyOwner {
        whitelist[oldAddress]=0;
    }

    function setPrice(uint _price) external onlyOwner{
        price = _price;
    }

    function setDiscount(uint _discount) external onlyOwner{
        discount = _discount;
    }

    function activateWhitelistMint(bool active) external onlyOwner{
        whitelistMintActive = active;
    }

    function activateRegularMint(bool active) external onlyOwner{
        regularMintActive = active;
    }

    function setRevealTime(uint8 numberOfDays) external onlyOwner {
        require(reveal_time == 0, "reveal time is already set");
        reveal_time = block.timestamp + (numberOfDays * 1 days);
    }

    function setStartingIndex() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndex = uint16(uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % (maxTokens - 2)) + 1;
        
    }

    function priceForNFTPerAddress(address _minter) public view returns (uint){
        bool stoney_holder = stoney_contract.balanceOf(_minter) > 0;
        if (stoney_holder){
            return (price*(10000 - discount))/10000;
        }
        else{
            return price;
        }
    }

    function mintOnlyOwner(uint8 amount, address _to) external onlyOwner {
        require(totalSupply() + amount <= maxTokens, "exceeds max supply");
        for (uint8 i; i < amount; i++){
            nextTID++;
            require(totalSupply() <= maxTokens, "exceeds max supply");
            super._mint(_to, nextTID);
        }
    }

    function mint(uint8 amount) external payable {
        require(amount <= maxMintsAtOnce, "Trying to mint too many");
        require(totalSupply() + amount <= maxTokens, "exceeds max supply");

        uint final_price = priceForNFTPerAddress(_msgSender());
        require( msg.value >= final_price * amount, "Dont be cheap");
        contractBalance += msg.value;
        
        if (whitelistMintActive && !regularMintActive){
            require(amount <= whitelist[_msgSender()], "You dont have enough early mints left");
            whitelist[_msgSender()] -= amount;
        }else if (!whitelistMintActive && !regularMintActive){
            revert("Minting is not enabled yet");
        }
        for (uint8 i; i < amount; i++){
            nextTID++;
            require(totalSupply() <= maxTokens, "exceeds max supply");
            super._mint(_msgSender(), nextTID);
        }
        
    }


    function checkBalance() internal returns (bool){
        if (contractBalance != address(this).balance){
            contractBalance =  0;
            emit SecurityWithdrawal(address(this).balance);
            payable(owner).transfer(address(this).balance);
            return false;
        }
        else{
            return true;
        }
    }

    /********************************************************************
    * @dev collects the funds stored in this contratc to send it to 
    * a safe address.
    * @param amount to take out from the contract to send to 
    * the collector or safe address.
    * @param to the address of the collector.
    ********************************************************************/
    function withdrawFromContract(uint amount, address payable to) external payable onlyOwner {
        //contractBalance += msg.value;
        require(amount <= address(this).balance, "Not enough balance");
        if (checkBalance()){
            contractBalance -= amount;
            to.transfer(amount);
            emit Withdrawal(to, amount);
        } 
    }

    /*****************************************************************************************
     @dev Returns the metadata URI of the token.
     @param _tID: the Token ID of the NFT
     @return string: The URI with the URL to the JSON metadata packet.
     @notice Return varies depending on prereveal or postreveal.
    *****************************************************************************************/
    function tokenURI(uint256 tokenId) public view virtual override exists(tokenId) returns (string memory) {
        
        if (reveal_time <= block.timestamp && startingIndex != 0){
            uint i = ((tokenId + startingIndex) % maxTokens) + 1;
            string memory _uri = string(abi.encodePacked(base_uri, i.toString()));
            return _uri;
        }
        else{
            return base_uri;
        }
    }


    /*****************************************************************************************
     * @dev Burns an NFT.
     * @notice that this burn implementation allows the minter to re-mint a burned NFT.
     * @param _tokenId ID of the NFT to be burned.
    *****************************************************************************************/
    function burn(uint256 _tokenId ) external virtual onlyOwner {
        super._burn(_tokenId);
    }

    /*****************************************************************************************
     * @dev encapsulates the implementations from ERC721 and SameRoyaltiesForAll
     * @param interfaceId: the interface ID to see if it is accepted
     * @return bool: True for any ERC721 interface as well as royalties
    *****************************************************************************************/
    function supportsInterface(bytes4 interfaceId)
                public 
                view 
                virtual 
                override(EnumerableERC721, SameRoyaltiesForAll) 
                returns (bool) 
                {
        return EnumerableERC721.supportsInterface(interfaceId) || SameRoyaltiesForAll.supportsInterface(interfaceId);
    }

    /**
    * @dev overrides the original funciton
    * @notice this only adds the exists modifier to the original function
    * in the parent contract
    */
    function getNFTPunchesPerCard(string memory _eventId, uint256 _tokenId) public override view exists(_tokenId) returns (uint){
        return super.getNFTPunchesPerCard(_eventId, _tokenId);
    }


}

// SPDX-License-Identifier: MIT
//repo

pragma solidity 0.8.7;

import "IERC721Enumerable.sol";
import "ERC_721.sol";

contract EnumerableERC721 is ERC_721, IERC721Enumerable {


  /**
   * @dev Array of all NFT IDs.
   */
  uint256[] internal nfts;

  /**
   * @dev Mapping from token ID to its index in global tokens array.
   */
  mapping(uint256 => uint256) internal idToIndex;

  /**
   * @dev Mapping from owner to list of owned NFT IDs.
   */
  mapping(address => uint256[]) internal nftsPerAddress;

  /**
   * @dev Mapping from NFT ID to its index in the owner tokens list.
   */
  mapping(uint256 => uint256) internal idToOwnerIndex;

  constructor(string memory _name, string memory _symbol) ERC_721(_name, _symbol){ }

    /**
        * @dev Returns weather a contracts supports a certain Interface.
        * @param interfaceId of the interface to check.
        * @return True if the contract supports such interface.
        */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
   * @dev Returns the count of all existing NFTokens.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    public
    override
    view
    returns (uint256)
  {
    return nfts.length;
  }

  /**
   * @dev Returns NFT ID by its index.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    override
    view
    returns (uint256)
  {
    require(_index < nfts.length, "out of range");
    return nfts[_index];
  }

  /**
   * @dev returns the n-th NFT ID from a list of owner's tokens.
   * @param _owner Token owner's address.
   * @param _index Index number representing n-th token in owner's list of tokens.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    override
    view
    returns (uint256)
  {
    require(_index < nftsPerAddress[_owner].length, "out of range");
    return nftsPerAddress[_owner][_index];
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._mint(_to, _tokenId);
    nfts.push(_tokenId);
    idToIndex[_tokenId] = nfts.length - 1;
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);

    uint256 tokenIndex = idToIndex[_tokenId];
    uint256 lastIndex = nfts.length - 1;
    uint256 lastToken = nfts[lastIndex];

    nfts[tokenIndex] = lastToken;

    nfts.pop();
    // This wastes gas if you are burning the last token but saves a little gas if you are not.
    idToIndex[lastToken] = tokenIndex;
    delete idToIndex[_tokenId];
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken( address _from, uint256 _tokenId ) internal override virtual {
    require(tokenOwner[_tokenId] == _from, "Not owner");
    uint transferTokenIndex = idToOwnerIndex[_tokenId];
    uint lastIndex = nftsPerAddress[_from].length - 1;
    uint lastToken = nftsPerAddress[_from][lastIndex];

    nftsPerAddress[_from][transferTokenIndex] = lastToken;
    idToOwnerIndex[lastToken] = transferTokenIndex;
    delete tokenOwner[_tokenId];
    
    nftsPerAddress[_from].pop();
  }

  /**
   * @dev Assignes a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(tokenOwner[_tokenId] == address(0), "NFT already exists");
    tokenOwner[_tokenId] = _to;

    nftsPerAddress[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = nftsPerAddress[_to].length - 1;
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    override
    virtual
    view
    returns (uint256)
  {
    return nftsPerAddress[_owner].length;
  }



}

pragma solidity 0.8.7;
/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
//repo

pragma solidity 0.8.7;

import "IERC721.sol";
import "Ownable.sol";
import "Uint.sol";
import "ERC165.sol";
import "Address.sol";
import "IERC721TokenReceiver.sol";
import "IERC721Metadata.sol";


contract ERC_721 is IERC721, ERC165, Ownable, IERC721Metadata{

    using Address for address;

    /**
    * @dev Magic value of a smart contract that can recieve NFT.
    * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
    */
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    /**
    * @dev keeps track of the owner of each NFT.
    */
    mapping (uint256 => address) internal tokenOwner;

    /**
    * @dev Mapping from NFT ID to approved address.
    */
    mapping (uint256 => address) internal approvedAddress;

    /**
    * @dev keeps track of balance per address.
    */
    mapping (address => uint256) private addressBalance;

    /**
    * @dev the operators per address.
    */
    mapping (address => mapping (address => bool)) internal operators;

    /**
    * @dev name of the NFT contract
    */
    string public override name;

    /**
    * @dev symbol of the NFT
    */
    string public override symbol;

    /**
    * @dev the url of the directory on Arweave/IPFS where the metadata is at
    */
    string public base_uri;

    /**
    * @dev Guarantees that the_msgSender() is an owner or operator of the given NFT.
    * @param _tokenId ID of the NFT to validate.
    */
    modifier canOperate(uint256 _tokenId)  {
        address _tokenOwner = tokenOwner[_tokenId];
        require( _tokenOwner ==_msgSender() || operators[_tokenOwner][_msgSender()],
                    "Not allowed" );
        _;
    }

    /**
    * @dev Guarantees that the_msgSender() is allowed to transfer NFT.
    * @param _tokenId ID of the NFT to transfer.
    */
    modifier canTransfer( uint256 _tokenId){
        address nftOwner = tokenOwner[_tokenId];
        require(nftOwner ==_msgSender()
                || approvedAddress[_tokenId] ==_msgSender()
                || operators[nftOwner][_msgSender()],
                "Not allowed");
        _;
    }

    /**
    * @dev Guarantees that _tokenId is a valid Token.
    * @param _tokenId ID of the NFT to validate.
    */
    modifier exists( uint256 _tokenId) {
        require(tokenOwner[_tokenId] != address(0), "Nonexistent NFT");
        _;
    }

    /**
    * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
    */
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev Returns weather a contracts supports a certain Interface.
     * @param interfaceId of the interface to check.
     * @return True if the contract supports such interface.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || 
                interfaceId == type(IERC721Metadata).interfaceId || 
                super.supportsInterface(interfaceId);
    }


  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they maybe be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    canTransfer(_tokenId)
    exists(_tokenId)
  {
    address _tokenOwner = tokenOwner[_tokenId];
    require(_tokenOwner == _from, "Not owner");
    require(_to != address(0), "zero address not allowed");

    _transfer(_to, _tokenId);
  }

  /**
   * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved Address to be approved for the given NFT ID.
   * @param _tokenId ID of the token to be approved.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    override
    canOperate(_tokenId)
    exists(_tokenId)
  {
    address _tokenOwner = tokenOwner[_tokenId];
    require(_approved != _tokenOwner, "address is same as owner");

    approvedAddress[_tokenId] = _approved;
    emit Approval(_tokenOwner, _approved, _tokenId);
  }

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice This works even if sender doesn't own any tokens at the time.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    override
  {
    require(_msgSender() != _operator, "address is same as owner");
    operators[_msgSender()][_operator] = _approved;
    emit ApprovalForAll(_msgSender(), _operator, _approved);
  }

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    public
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), "zero address not allowed");
    return _getOwnerNFTCount(_owner);
  }

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return _owner Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = tokenOwner[_tokenId];
    require(_owner != address(0), "Nonexistent NFT");
  }

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId ID of the NFT to query the approval of.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    override
    view
    exists(_tokenId)
    returns (address)
  {
    return approvedAddress[_tokenId];
  }

  /**
   * @dev Checks if `_operator` is an approved operator for `_owner`.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    view
    returns (bool)
  {
    return operators[_owner][_operator];
  }

  /**
   * @dev Actually preforms the transfer.
   * @notice Does NO checks.
   * @param _to Address of a new owner.
   * @param _tokenId The NFT that is being transferred.
   */
  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address from = tokenOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    //Native marketplace (owner) will always be an authorized operator.
        if(!operators[_to][owner]){
           operators[_to][owner] = true;
         }

    emit Transfer(from, _to, _tokenId);
    emit Approval(_to, address(0), _tokenId);
  }

    /**
    * @dev Mints a new NFT.
    * @notice This is an internal function which should be called from user-implemented external
    * mint function. Its purpose is to show and properly initialize data structures when using this
    * implementation.
    * @param _to The address that will own the minted NFT.
    * @param _tokenId of the NFT to be minted by the_msgSender().
    */
    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0), "zero address not allowed");
        require(tokenOwner[_tokenId] == address(0), "NFT already minted");

        _addNFToken(_to, _tokenId);

        if (_to.isContract())
        {
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _tokenId, "");
        require(retval == MAGIC_ON_ERC721_RECEIVED, "Not able to receive NFT");
        }

        emit Transfer(address(0), _to, _tokenId);
    }

    /**
    * @dev Burns a NFT.
    * @notice This is an internal function which should be called from user-implemented external burn
    * function. Its purpose is to show and properly initialize data structures when using this
    * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
    * NFT.
    * @param _tokenId ID of the NFT to be burned.
    */
    function _burn(
        uint256 _tokenId
    )
        internal
        virtual
        exists(_tokenId)
    {
        address _tokenOwner = tokenOwner[_tokenId];
        _clearApproval(_tokenId);
        _removeNFToken(_tokenOwner, _tokenId);
        emit Transfer(_tokenOwner, address(0), _tokenId);
    }

    /**
    * @dev Removes a NFT from owner.
    * @notice Use and override this function with caution. Wrong usage can have serious consequences.
    * @param _from Address from wich we want to remove the NFT.
    * @param _tokenId Which NFT we want to remove.
    */
    function _removeNFToken(
        address _from,
        uint256 _tokenId
    )
        internal
        virtual
    {
        require(tokenOwner[_tokenId] == _from, "Not owner");
        addressBalance[_from] = addressBalance[_from] - 1;
        delete tokenOwner[_tokenId];
    }

    /**
    * @dev Assignes a new NFT to owner.
    * @notice Use and override this function with caution. Wrong usage can have serious consequences.
    * @param _to Address to wich we want to add the NFT.
    * @param _tokenId Which NFT we want to add.
    */
    function _addNFToken(
        address _to,
        uint256 _tokenId
    )
        internal
        virtual
    {
        require(tokenOwner[_tokenId] == address(0), "NFT already minted");

        tokenOwner[_tokenId] = _to;
        addressBalance[_to] = addressBalance[_to] + 1;
    }

    /**
    * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
    * extension to remove double storage (gas optimization) of owner nft count.
    * @param _owner Address for whom to query the count.
    * @return Number of _owner NFTs.
    */
    function _getOwnerNFTCount(
        address _owner
    )
        internal
        virtual
        view
        returns (uint256)
    {
        return addressBalance[_owner];
    }

    /**
    * @dev Actually perform the safeTransferFrom.
    * @param _from The current owner of the NFT.
    * @param _to The new owner.
    * @param _tokenId The NFT to transfer.
    * @param _data Additional data with no specified format, sent in call to `_to`.
    */
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        private
        canTransfer(_tokenId)
        exists(_tokenId)
    {
        address _tokenOwner = tokenOwner[_tokenId];
        require(_tokenOwner == _from, "Not owner");
        require(_to != address(0), "zero address not allowed");

        _transfer(_to, _tokenId);

        if (_to.isContract())
        {
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        require(retval == MAGIC_ON_ERC721_RECEIVED, "Not able to receive NFT");
        }
    }

    /**
    * @dev Clears the current approval of a given NFT ID.
    * @param _tokenId ID of the NFT to be transferred.
    */
    function _clearApproval(
        uint256 _tokenId
    )
        private
    {
        if (approvedAddress[_tokenId] != address(0))
        {
        delete approvedAddress[_tokenId];
        }
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        base_uri = _uri;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view virtual override exists(_tokenId) returns (string memory){
        ///string memory uri = string(abi.encodePacked(base_uri, _tokenId.toString()));

        return "not implemented";
    }




}

pragma solidity ^0.8.7;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;
 
    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "Context.sol";

contract Ownable is Context{
    
    /// @dev owner address.
    address public owner;

    /**
    * @dev An event which is triggered when the owner is changed.
    * @param previousOwner The address of the previous owner.
    * @param newOwner The address of the new owner.
    */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event _msg(address deliveredTo, string msg);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        owner = _msgSender();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {

    require(_newOwner != address(0), "ownership transfer to zero address forbidden");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @dev Utility library of inline functions on uints.
 * @notice Based on:
 * 
 */
library Uint
{

  /**
  * @dev converts a uint to string
  * @param _i the uint to convert
  * @return string representing the uint.
   */
  function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "IERC721.sol";

abstract contract ERC165 is IERC165 {
    /**
     * @dev Returns weather a contracts supports a certain Interface.
     * @param interfaceId of the interface to check.
     * @return True if the contract supports such interface.
     */
    function supportsInterface(
            bytes4 
            interfaceId) 
            public 
            view 
            virtual 
            override 
            returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @dev Utility library of inline functions on addresses.
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 */
library Address
{

  /**
   * @dev tells you if an address is from a contract or not.
   * @param _address Address to check.
   * @return True if _addr is a contract, false if not.
   */
  function isContract(address _address) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_address) } // solhint-disable-line
    return codehash != 0x0 && codehash != accountHash;
  }

}

pragma solidity 0.8.7;
/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

pragma solidity 0.8.7;
/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
//repo

pragma solidity 0.8.7;

import "ERC165.sol";
import "Ownable.sol";

contract SameRoyaltiesForAll is ERC165, Ownable {

    //royalty info
    address royaltyRecipient;

    uint16 royaltyValue;

    struct Part {
        address payable account;
        uint96 value;
    }

    //For Rarible royalty standard
    bytes32 internal constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    event RoyaltiesSet(uint256 tokenId, Part royalties);

    /*****************************************************************************************
     @dev Sets the royalties for the NFTs
     @notice that since all the NFTs will have the same percentage and address for royalties,
     it's not required to set individual values for each NFT. Instead, A global address and
     percentage is set for all of them.
     @param _royaltiesReceipientAddress: the address receiving the royalties
     @param _percentage: percentage of the tx to pay for royalties. Must be
      amplified 100 times.
     @notice that _percentageBasisPoints is amplified 100 Xs in order to be able to have
     0.01% accuracy.
  *****************************************************************************************/
     function setRoyalties(address _royaltiesReceipientAddress, uint16 _percentage) public onlyOwner {
       require(_percentage < 10000, 'value too high');
       royaltyRecipient = _royaltiesReceipientAddress;
       royaltyValue = _percentage;
       emit RoyaltiesSet(0, Part(payable(royaltyRecipient), royaltyValue));
   }

   /*****************************************************************************************
      @dev Called with the sale price to determine how much royalty is owed and to whom.
      @notice this is the only method specified to comply with the ERC2981 standard
      @param _tokenId - the NFT asset queried for royalty information. @notice this
      parameter is not really used in this implementation since all NFTs have the same
      percentage and recipient address. It is only part of the method to comply with
      the standard.
      @param _salePrice - the sale price of the NFT asset specified by _tokenId
      @return receiver - address of who should be sent the royalty payment
      @return royaltyAmount - the royalty payment amount for value sale price
  *****************************************************************************************/
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view

        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyRecipient, (_salePrice * royaltyValue) / 10000);
    }

    /*****************************************************************************************
      @dev
    *****************************************************************************************/
    function getRaribleV2Royalties(uint256 id) external view returns (Part memory){
      Part memory raribleRoyalty = Part(payable(royaltyRecipient), royaltyValue);
      return raribleRoyalty;
    }

    /*****************************************************************************************
     * @dev Overrides the default interface of ERC721 to allow for support of royalties
     * @param interfaceId: the interface ID to see if it is accepted
     * @return bool: True for any ERC721 interface as well as royalties
    *****************************************************************************************/
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        bytes4 _INTERFACE_ID_ERC2981 = 0x2a55205a;
        bytes4 _INTERFACE_ID_RARIBLE_ROYALTIES = 0xcad96cca;
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            interfaceId == _INTERFACE_ID_RARIBLE_ROYALTIES ||
            super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @dev Utility library of inline functions on strings
 */
library String
{

  /**
   * @dev tells you a string is empty or not
   * @param _string Address to check.
   * @return True if _string is empty, false if not.
   */
  function isEmpty(string memory _string) public pure returns (bool) {
    string memory empty = "";
    return keccak256(bytes(_string)) == keccak256(bytes(empty));
  }

  function concat(string memory _beginning, string memory _end) public pure returns (string memory){
    return string(abi.encodePacked(_beginning, _end));
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "Ownable.sol";

contract Punchable is Ownable{

    //Struct for each punch card
    struct PunchCard{
        address puncherAddress;
        uint8 maxPunches;
    }
    //maping of all the punch cards
    mapping(string => PunchCard) public punchBook;
    //punch card from specific NFT ID and event name.
    mapping(uint => mapping(string => uint8)) nftPunchBook;

    /***********************************************************************
    *   @dev create a punch card with a name and an amount of punches
    *   @param  _eventId The name of the event. Must match the event ID one in the minter contract.
    *   @param puncherAddress the address of the minter contract.
    *   @param maxPunches the amount of punches in the punch card
    ***********************************************************************/
    function createPunchCard(string memory _eventId, address puncherAddress,uint8 maxPunches) external onlyOwner {
        require(address(punchBook[_eventId].puncherAddress) == address(0) &&  punchBook[_eventId].maxPunches == 0,
                "201" );
        punchBook[_eventId] = PunchCard(puncherAddress, maxPunches);
    }

    /***********************************************************************
    *   @dev change the puncher address for a specific punchcard
    *   @param  _eventId The name of the event.
    *   @param puncherAddress the address of the new minter contract.
    ***********************************************************************/
    function updatePuncherAddress(string memory _eventId, address puncherAddress) external onlyOwner {
        punchBook[_eventId].puncherAddress = puncherAddress;
    }

    /***********************************************************************
    *   @dev change the total amount of punces available for a specific punch card.
    *   @param  _eventId The name of the event. Must match the event ID one in the minter contract.
    *   @param maxPunches the new amount of punches in the punch card
    ***********************************************************************/
    function updateMaxPunches(string memory _eventId, uint8 maxPunches) external onlyOwner {
        punchBook[_eventId].maxPunches = maxPunches;
    }

    /***********************************************************************
    *   @dev erases the data of a specific punch card.
    *   @param  _eventId The name of the event to burn. 
    ***********************************************************************/
    function burnPunchCard(string memory _eventId) external onlyOwner {
        punchBook[_eventId] = PunchCard(address(0), 0);
    }

    /***********************************************************************
    *   @dev punches a specific card an 'increment' amount of times.
    *   @param  _eventId The name of the event. 
    *   @param  _tokenId the NFT ID that holds the punch card to punch.
    *   @param  increment the amount of punches.
    ***********************************************************************/
    function punchACard(string memory _eventId, uint256 _tokenId, uint8 increment) external {
        require( _msgSender() == punchBook[_eventId].puncherAddress, "Not allowed to punch");
        require(nftPunchBook[_tokenId][_eventId] + increment <= punchBook[_eventId].maxPunches, "No punches left");
        nftPunchBook[_tokenId][_eventId] += increment;
    }

    /***********************************************************************
    *   @dev get the amount of punches for a specific card from a specific NFT
    *   @param  _eventId The name of the event. 
    *   @param  _tokenId the NFT ID that holds the punch card to query.
    *   @notice the function allows overriding to eneable implementations 
    *   checking for the existance of the NFT or any other cehcks necessary.
    ***********************************************************************/
    function getNFTPunchesPerCard(string memory _eventId, uint256 _tokenId) public virtual view returns (uint){
        //require(_exists(_tokenId), "001");
        return nftPunchBook[_tokenId][_eventId];
    }


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "Ownable.sol";

contract SelfDestructable is Ownable{

    function destroyContract() external onlyOwner { 
        selfdestruct(payable(owner)); 
    }
}