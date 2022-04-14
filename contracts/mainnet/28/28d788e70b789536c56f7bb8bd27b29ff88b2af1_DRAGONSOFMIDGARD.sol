/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

/**
░▒█▀▀▄░▀█▀░▒█▀▀█░▒█░▒█░▒█▀▀▀░▒█▀▀▄░▒█▀▀▀█
░▒█░░░░▒█░░▒█▄▄█░▒█▀▀█░▒█▀▀▀░▒█▄▄▀░░▀▀▀▄▄
░▒█▄▄▀░▄█▄░▒█░░░░▒█░▒█░▒█▄▄▄░▒█░▒█░▒█▄▄▄█
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library Strings {

    function toString(uint256 value) internal pure returns (string memory) {
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
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {



    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval( address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner,address indexed operator,bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId)external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator)external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index)external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721 {
 
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {

    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) external returns (bytes4);
}

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error UnableDetermineTokenOwner();
error URIQueryForNonexistentToken();

contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable{
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal _currentIndex;
 


    string private _name;
    string private _symbol;

    mapping(uint256 => TokenOwnership) internal _ownerships;
    mapping(address => AddressData) private _addressData;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function totalSupply() public view override returns (uint256) {
        return _currentIndex;
    }

    function tokenByIndex(uint256 index)public  view  override  returns (uint256){
        if (index >= totalSupply()) revert TokenIndexOutOfBounds();
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)public view override returns (uint256 a){
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        assert(false);
    }

    function supportsInterface(bytes4 interfaceId)public view virtual override(ERC165, IERC165) returns (bool){
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory){
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }

        revert UnableDetermineTokenOwner();
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ApprovalCallerNotOwnerNorApproved();

        _approve(to, tokenId, owner);
    }

    function getApproved(uint256 tokenId) public view override returns (address){
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)public override{
        if (operator == _msgSender()) revert ApproveToCaller();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)  public view virtual override returns (bool){
        return _operatorApprovals[owner][operator];
    }

    function transferFrom( address from, address to, uint256 tokenId) public virtual override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data))
            revert TransferToNonERC721ReceiverImplementer();
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    function _safeMint(  address to, uint256 quantity, bytes memory _data) internal {
        _mint(to, quantity, _data, true);
    }

    function _mint(address to, uint256 quantity, bytes memory _data, bool safe) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint128(quantity);
            _addressData[to].numberMinted += uint128(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (
                    safe &&
                    !_checkOnERC721Received(address(0), to, updatedIndex, _data)
                )
                 {
                    revert TransferToNonERC721ReceiverImplementer();
                }

                updatedIndex++;
            }

            _currentIndex = updatedIndex;

           
               
            
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);
        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr || getApproved(tokenId) == _msgSender() || isApprovedForAll(prevOwnership.addr, _msgSender()));

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();
        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                if (_exists(nextTokenId)) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership
                        .startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _approve( address to, uint256 tokenId, address owner) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _checkOnERC721Received(address from,address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0)
                    revert TransferToNonERC721ReceiverImplementer();
                else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
}

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
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

contract DRAGONSOFMIDGARD is ERC721A, Ownable {
    
    uint256 public maxSupply = 5555;
    uint256 public reserveQuantity = 169;
    uint256 private winnersQuantity=50;
    uint256 public price = 0.1 ether;
    uint256 public preSaleSupply = 2277;
    uint256 public preSalePrice = 0.07 ether;
    uint256 public maxPerWallet = 2;
    uint256 public maxPerTransaction = 5;
    bytes32 private merkleRoot;
    string  public _baseURI1;
    bool    public isPaused =true;
    bool    public isPreSalePaused =true;
    IERC721 public _juvenileObj;
    IERC721 public _ancientObj;
    IERC721 public _greatWyrmObj;
    IERC721 public deployedDragon;

    struct UserPreSaleCounter {    
        uint256 counter;
    }

    struct EVOLVING {
        bool juvenileAge;
        bool ancientAge;
        bool greatWyrmAge;
    }

    mapping(address => UserPreSaleCounter)  public  _preSaleCounter;
    mapping(address => bool)                public  _preSaleAddressExist;
    mapping(uint256 => EVOLVING)            public   evolving;
    mapping(address =>bool)                 public   oldNftAddressExist;
    
    constructor(string memory baseUri) ERC721A("DragonsOfMidgard", "DRAGONS") {
        _baseURI1= baseUri;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setReserve(uint256 _reserve) public onlyOwner {
        reserveQuantity = _reserve;
    }

    function setWinnersQuantity(uint256 _winnersQuantity) public onlyOwner {
        require(_winnersQuantity < maxSupply, "amount exceeds");
        winnersQuantity = _winnersQuantity;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    
    function setPresaleSupply(uint256 _preSaleSupply) public onlyOwner {
        preSaleSupply = _preSaleSupply;
    }
    
    function setPreSalePrice(uint256 _price) public onlyOwner {
        preSalePrice = _price;
    }
    
    function setMaxPerWallet(uint256 quantity) public onlyOwner {
        maxPerWallet = quantity;
    }
    
    function setMaxPerTrasaction(uint256 quantity) public onlyOwner {
        maxPerTransaction = quantity;
    }

    function setRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function setBaseURI(string memory baseuri) public onlyOwner {
        _baseURI1 = baseuri;
    }
    
    function flipPauseStatus() public onlyOwner {
        isPaused = !isPaused;
    }

    function flipPreSalePauseStatus() public onlyOwner {
        isPreSalePaused = !isPreSalePaused;
    }

    function setJuvenile(address juvenileAddress) public onlyOwner {
        _juvenileObj = IERC721(juvenileAddress);
    }

    function setAncient(address ancientAddress) public onlyOwner {
        _ancientObj = IERC721(ancientAddress);
    }

    function setGreatWyrm(address greatWyrm) public onlyOwner {
        _greatWyrmObj = IERC721(greatWyrm);
    }

    function setDragonAddress(address contractaddress) public onlyOwner {
        deployedDragon = IERC721(contractaddress);
    }
        
    function _baseURI()internal view override  returns (string memory){
        return _baseURI1;
    }

    function mint(uint256 quantity) public payable {
        require(quantity > 0 ,"quantity should be greater than 0");
        require(isPaused==false,"minting is stopped");
        require(quantity <=maxPerTransaction,"per transaction amount exceeds");
        require(totalSupply()+quantity<=maxSupply-reserveQuantity-winnersQuantity,"all tokens have been minted");
        require(price*quantity == msg.value, "Sent ether value is incorrect");
        _safeMint(msg.sender, quantity);
    }

    function reserve(uint256 quantity) public onlyOwner {
        require(quantity <= reserveQuantity, "the quantity exceeds reserve");
        reserveQuantity -= quantity;
        _safeMint(msg.sender, quantity);
    }

    function mintPreSale(bytes32[] calldata _merkleProof, uint256 quantity) public payable {
         if (_preSaleAddressExist[msg.sender] == false) {
            _preSaleCounter[msg.sender] = UserPreSaleCounter({
                counter: 0
            });
            _preSaleAddressExist[msg.sender] = true;
        }  
        require(isPreSalePaused== false, "turn on minting");
        require(_preSaleCounter[msg.sender].counter + quantity <= maxPerWallet, "Sorry can not mint more than maxwallet");
        require(quantity > 0, "zero not allowed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Proof"
        );
        require(totalSupply() + quantity <= preSaleSupply, "presale amount exceeds");
        require(preSalePrice*quantity==msg.value,"invalid amount");
        _safeMint(msg.sender,quantity);
        _preSaleCounter[msg.sender].counter += quantity;
    }

    function tokensOfOwner(address _owner)public view returns (uint256[] memory) {
        uint256 count = balanceOf(_owner);
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function enterage(uint256 tokenid, string memory age) external {
        if (keccak256(abi.encodePacked(age)) == keccak256(abi.encodePacked("juvenile"))) {
            _juvenileObj.ownerOf(tokenid) == msg.sender;
            evolving[tokenid].juvenileAge = true;
        }
         else if (keccak256(abi.encodePacked(age)) == keccak256(abi.encodePacked("ancient"))) {
            _ancientObj.ownerOf(tokenid) == msg.sender;
            evolving[tokenid].ancientAge = true;
        }
         else if (keccak256(abi.encodePacked(age)) == keccak256(abi.encodePacked("greatwyrm"))) {
            _greatWyrmObj.ownerOf(tokenid) == msg.sender;
            evolving[tokenid].greatWyrmAge = true;
        } else {
            revert("wrong age entered");
        }
    }
    
    function OldNftHolders(uint startIndex ,uint endIndex)public onlyOwner { 
        address owner;
        for(uint i=startIndex; i<= endIndex; i++){
            owner = deployedDragon.ownerOf(i);
            if(oldNftAddressExist[owner]==false){
            uint256  nftBalance  =   deployedDragon.balanceOf(owner);
            _safeMint(owner,nftBalance);
            oldNftAddressExist[owner]=true;
        }
      }
    }
      
    function airDropForWinners(address[] memory _accounts,uint [] memory _balances)public onlyOwner { 
        for(uint i=0; i< _accounts.length; i++){
            _safeMint(_accounts[i],_balances[i]);
            winnersQuantity-=_balances[i];
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}