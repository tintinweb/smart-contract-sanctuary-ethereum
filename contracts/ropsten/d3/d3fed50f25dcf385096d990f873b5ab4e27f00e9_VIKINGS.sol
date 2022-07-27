/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
      return interfaceId == type(IERC165).interfaceId;
    }
}


interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
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
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
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

  contract ERC721A is
      Context,
      ERC165,
      IERC721,
      IERC721Metadata,
      IERC721Enumerable
      {
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

    uint256 private currentIndex = 1;

    uint256 internal immutable collectionSize;
    uint256 internal  maxBatchSize = 50;

    string private _name;

    string private _symbol;

    bool public Royal_Sale;

    bool public Jarls_Sale;

    bool public Karls_Sale;

    uint256 public JarlsLockingTime = 2 minutes;

    uint256 public KarlsLockingTime = 3 minutes;

    mapping(uint256 => TokenOwnership) private _ownerships;

    mapping(address => AddressData) private _addressData;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256=>uint256) public jarlsMintingTime;

    mapping(uint256=>uint256) public karlsMintingTime;

    

    constructor(
      string memory name_,
      string memory symbol_,
    //   uint256 maxBatchSize_,
      uint256 collectionSize_
    ) {
      require(
        collectionSize_ > 0,
        "ERC721A: collection must have a nonzero supply"
      );
    //   require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
      _name = name_;
      _symbol = symbol_;
    //   maxBatchSize = maxBatchSize_;
      collectionSize = collectionSize_;
    }

    function totalSupply() public view override returns (uint256) {
      return currentIndex -1;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
      require(index < totalSupply()+1, "ERC721A: global index out of bounds");
      return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
      public
      view
      override
      returns (uint256)
    {
      require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
      uint256 numMintedSoFar = totalSupply()+1;
      uint256 tokenIdsIdx = 0;
      address currOwnershipAddr = address(0);
      for (uint256 i = 0; i <numMintedSoFar; i++) {
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
      revert("ERC721A: unable to get token of owner by index");
    }

    function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC165, IERC165)
      returns (bool)
    {
      return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
      require(owner != address(0), "ERC721A: balance query for the zero address");
      return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
      require(
        owner != address(0),
        "ERC721A: number minted query for the zero address"
      );
      return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId)
      internal
      view
      returns (TokenOwnership memory)
    {
      require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

      uint256 lowestTokenToCheck;
      if (tokenId >= maxBatchSize) {
        lowestTokenToCheck = tokenId - maxBatchSize + 1;
      }

      for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
        TokenOwnership memory ownership = _ownerships[curr];
        if (ownership.addr != address(0)) {
          return ownership;
        }
      }

      revert("ERC721A: unable to determine the owner of token");
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

    function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
    {
      require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );

      string memory baseURI = _baseURI();
      return
        bytes(baseURI).length > 0
          ? string(abi.encodePacked(baseURI, tokenId.toString()))
          : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
      return "";
    }

    function approve(address to, uint256 tokenId) public override {
      address owner = ERC721A.ownerOf(tokenId);
      require(to != owner, "ERC721A: approval to current owner");

      require(
        _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
        "ERC721A: approve caller is not owner nor approved for all"
      );

      _approve(to, tokenId, owner);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
      require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

      return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
      require(operator != _msgSender(), "ERC721A: approve to caller");

      _operatorApprovals[_msgSender()][operator] = approved;
      emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
      public
      view
      virtual
      override
      returns (bool)
    {
      return _operatorApprovals[owner][operator];
    }

    function transferFrom(
      address from,
      address to,
      uint256 tokenId
    ) public override {
      _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
    ) public override {
      safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory _data
    ) public override {
      _transfer(from, to, tokenId);
      require(
        _checkOnERC721Received(from, to, tokenId, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
      return tokenId < currentIndex;
    }


    function _safeMint(address to, uint256 quantity) internal {
      _safeMint(to, quantity, "");
    }

    function _safeMint(
      address to,
      uint256 quantity,
      bytes memory _data
    ) internal {
      uint256 startTokenId = currentIndex;
      require(to != address(0), "ERC721A: mint to the zero address");
      require(!_exists(startTokenId), "ERC721A: token already minted");
      require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

      _beforeTokenTransfers(address(0), to, startTokenId, quantity);

      AddressData memory addressData = _addressData[to];
      _addressData[to] = AddressData(
        addressData.balance + uint128(quantity),
        addressData.numberMinted + uint128(quantity)
      );
      _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

      uint256 updatedIndex = startTokenId;

      for (uint256 i = 1; i <=quantity; i++) {
        emit Transfer(address(0), to, updatedIndex);
        require(
          _checkOnERC721Received(address(0), to, updatedIndex, _data),
          "ERC721A: transfer to non ERC721Receiver implementer"
        );
        if (Jarls_Sale == true)
        {
            jarlsMintingTime[updatedIndex]=block.timestamp;
        }
        else if (Karls_Sale == true)
        {
            karlsMintingTime[updatedIndex]=block.timestamp;
        }
        
        updatedIndex++;
        
      }

      currentIndex = updatedIndex;
      _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(
      address from,
      address to,
      uint256 tokenId
    ) private {
      TokenOwnership memory prevOwnership = ownershipOf(tokenId);

      bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
        getApproved(tokenId) == _msgSender() ||
        isApprovedForAll(prevOwnership.addr, _msgSender()));

      require(
        isApprovedOrOwner,
        "ERC721A: transfer caller is not owner nor approved"
      );

      require(
        prevOwnership.addr == from,
        "ERC721A: transfer from incorrect owner"
      );
      require(to != address(0), "ERC721A: transfer to the zero address");
      require(
        block.timestamp>jarlsMintingTime[tokenId]+JarlsLockingTime,
        "Time not Reached for Jarls NFT"
      );
      require(
        block.timestamp>karlsMintingTime[tokenId]+KarlsLockingTime,
        "Time not Reached for Karls NFT"
      );
      


      _beforeTokenTransfers(from, to, tokenId, 1);

      _approve(address(0), tokenId, prevOwnership.addr);

      _addressData[from].balance -= 1;
      _addressData[to].balance += 1;
      _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

      uint256 nextTokenId = tokenId + 1;
      if (_ownerships[nextTokenId].addr == address(0)) {
        if (_exists(nextTokenId)) {
          _ownerships[nextTokenId] = TokenOwnership(
            prevOwnership.addr,
            prevOwnership.startTimestamp
          );
        }
      }

      emit Transfer(from, to, tokenId);
      _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _approve(
      address to,
      uint256 tokenId,
      address owner
    ) private {
      _tokenApprovals[tokenId] = to;
      emit Approval(owner, to, tokenId);
    }

    uint256 public nextOwnerToExplicitlySet = 0;

    function _setOwnersExplicit(uint256 quantity) internal {
      uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
      require(quantity > 0, "quantity must be nonzero");
      uint256 endIndex = oldNextOwnerToSet + quantity - 1;
      if (endIndex > collectionSize - 1) {
        endIndex = collectionSize - 1;
      }
      require(_exists(endIndex), "not enough minted yet for this cleanup");
      for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
        if (_ownerships[i].addr == address(0)) {
          TokenOwnership memory ownership = ownershipOf(i);
          _ownerships[i] = TokenOwnership(
            ownership.addr,
            ownership.startTimestamp
          );
        }
      }
      nextOwnerToExplicitlySet = endIndex + 1;
    }

    function _checkOnERC721Received(
      address from,
      address to,
      uint256 tokenId,
      bytes memory _data
    ) private returns (bool) {
      if (to.isContract()) {
        try
          IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
        returns (bytes4 retval) {
          return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
          if (reason.length == 0) {
            revert("ERC721A: transfer to non ERC721Receiver implementer");
          } else {
            assembly {
              revert(add(32, reason), mload(reason))
            }
          }
        }
      } else {
        return true;
      }
    }

    function _beforeTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
    ) internal virtual {}

    function _afterTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
    ) internal virtual {}
  }
 abstract contract Ownable is Context {
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
 library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


  contract VIKINGS is ERC721A,Ownable{

    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 5555;

    uint256 totalMintedInFirstSale;
    uint256 totalMintedInSecondSale;

    uint256 public firstSaleMintingLimit = 2000;
    uint256 public secondSaleMintingLimit = 1500;

    mapping(address=>uint256) public RoyalVikingSale;
    mapping(address=>uint256) public JarlsVikingSale;
    mapping(address=>uint256) public KarlsVikingSale;

    struct mintedData
    {
      address mintedAddress;
      uint256 amount;
    }
    
    mintedData[] public minteddata;

    constructor(address[] memory InitialAddresses) ERC721A(" The Vikings ", " TVK ",5555)
    {
        InitMinting(InitialAddresses);
        maxBatchSize=2;
    }

    // Initial Minting
    function InitMinting(address[] memory _recipients) internal {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _safeMint(_recipients[i], 50);
        }
    }

    // 1st sale
    function RoyalVikingsSale(uint256 _count) public
    {
        require(Royal_Sale == true, "MINT_NOT_STARTED");
        require(totalMintedInFirstSale+_count<=firstSaleMintingLimit,"Max Limit Reached");
        _safeMint(msg.sender, _count);
        RoyalVikingSale[msg.sender]+=_count;
        addToMintData(_count);
        totalMintedInFirstSale+=_count;
    }

    //  2nd sale
    function JarlsVikingsSale(uint256 _count) public
    {
        require(Jarls_Sale == true, "MINT_NOT_STARTED");
        require(totalMintedInSecondSale+_count<=secondSaleMintingLimit,"Max Limit Reached");
        _safeMint(msg.sender,_count);
        JarlsVikingSale[msg.sender]+=_count;
        addToMintData(_count);
        totalMintedInSecondSale+=_count;
    }

    //  3rd sale
    function KarlsVikings_Sale(uint256 _count) public
    {
        require(Karls_Sale == true, "MINT_NOT_STARTED");
        require(totalSupply() + _count <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");
        _safeMint(msg.sender,_count);
        KarlsVikingSale[msg.sender]+=_count;
        addToMintData(_count); 
    }

    function totalMintedAddress()public view returns(uint256){
    return minteddata.length;
    }

    // function to get tokenIds from sales
    function WalletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // * Admin Fuctions * //
    // * Set Sale * //
    function setSale1() public onlyOwner {
    if(Royal_Sale == true){
        Royal_Sale = false;
        }
        else{
        Royal_Sale = true;}
    }
    function setSale2() public {
        if(Jarls_Sale == true){
        Jarls_Sale = false;
        }
        else{
        Jarls_Sale = true;
        Royal_Sale = false;
        }
    }
    function setSale3() public {
        if(Karls_Sale == true){
        Karls_Sale = false;
        }
        else{
        Karls_Sale = true;
        Jarls_Sale = false;
        Royal_Sale = false;
        }
    }

    function addToMintData(uint256 _count) internal{
    (bool _isMinted, uint256 s) = isAlreadyMinted(msg.sender);
    if(_isMinted){
      minteddata[s].amount+=_count;
    }
    else
    {
      minteddata.push(mintedData(msg.sender,_count));
    }

    }

    function isAlreadyMinted(address _address)
      internal
      view
      returns(bool, uint256)
    {
      for (uint256 s = 0; s < minteddata.length; s += 1){
          if (_address == minteddata[s].mintedAddress) return (true, s);
      }
      return (false, 0);
    }

  }

  // [
  //     0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC,
  //     0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c,
  //     0x12E8613F1d980FD0543ECEBB2dab9533C589250F,
  //     0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
  //     0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB,
  //     0x583031D1113aD414F02576BD6afaBfb302140225,
  //     0xdD870fA1b7C4700F2BD7f44238821C26f7392148,
  //     0xAD4f1d02ad3e819AD86D3eD27dfd13F31A19a09a,
  //     0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
  //     0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
  // ]