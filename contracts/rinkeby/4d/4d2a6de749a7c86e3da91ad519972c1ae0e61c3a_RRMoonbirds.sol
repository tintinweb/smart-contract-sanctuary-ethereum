/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT

// File: contracts/Strings.sol

//RRaZuki

pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "";


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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;


interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;


interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;



abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);


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

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;



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

pragma solidity ^0.8.0;



contract RRMoonbirds is ERC165, IERC721, IERC721Metadata, Ownable{
    using Address for address;
    using Strings for uint256;

    string public _name;

    string public _symbol;

    string public metadataUri;

    uint256 private nextId = 1;

    mapping ( uint256 => address ) private owners;

    mapping ( address => uint256 ) private balances;

    mapping ( uint256 => address ) private tokenApprovals;

    mapping ( address => mapping( address => bool )) private operatorApprovals;

    mapping ( address => bool ) private administrators;

    mapping ( uint256 => bool ) public transferLocks;

    mapping(address => uint256) public ALAddressToCap;
    bool public revealed = true;
    bool public PublicMintingPaused = true;
    bool public ALMintingPaused = true;
    uint256 public MAX_CAP = 10000;
    uint8 public MAX_MINT_PER_TX = 1;
    string public notRevealedUri = "";
    uint256 private _price = 0.003 ether;

    modifier onlyAdmin () {
        if (_msgSender() != owner() && !administrators[_msgSender()]) {
          revert ("NotAnAdmin");
        }
        _;
    }

    constructor () {
        _name = "RRMoonbirds";
        _symbol = "RRMoonbirds";
        metadataUri = "https://live---metadata-5covpqijaa-uc.a.run.app/metadata/";
    }

  function name() external override view returns (string memory name_ret){
      return _name;
  }

  function symbol() external override view returns (string memory symbol_ret){
      return _symbol;
  }

       function totalSupply () public view returns (uint256) {
        return nextId - 1;
    }
  
    function supportsInterface (
      bytes4 _interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return (  _interfaceId == type(IERC721).interfaceId)
                  || (_interfaceId == type(IERC721Metadata).interfaceId)
                  || (super.supportsInterface(_interfaceId)
                );
    }

    function balanceOf (
      address _owner
    ) external view override returns (uint256) {
        return balances[_owner];
    }

  
    function _ownershipOf (
      uint256 _id
    ) private view returns (address owner) {
      if (!_exists(_id)) { revert ("OwnerQueryForNonexistentToken"); }

      unchecked {
          for (uint256 curr = _id;; curr--) {
            owner = owners[curr];
            if (owner != address(0)) {
              return owner;
            }
          }
      }
    }

    function ownerOf (
      uint256 _id
    ) external view override returns (address) {
        return _ownershipOf(_id);
    }

    function _exists (
      uint256 _id
    ) public view returns (bool) {
        return _id > 0 && _id < nextId;
    }

    function getApproved (
      uint256 _id
    ) public view override returns (address) {
        if (!_exists(_id)) { revert ("ApprovalQueryForNonexistentToken"); }
        return tokenApprovals[_id];
    }

  
    function isApprovedForAll (
      address _owner,
      address _operator
    ) public view virtual override returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function tokenURI (
      uint256 _id
    ) external view virtual override returns (string memory) {
        if (revealed == false) {
            return notRevealedUri;
        }
        if (!_exists(_id)) { revert ("URIQueryForNonexistentToken"); }
        return bytes(metadataUri).length != 0
        ? string(abi.encodePacked(metadataUri, _id.toString()))
        : '';
    }

    function _approve (
      address _owner,
      address _to,
      uint256 _id
    ) private {
      tokenApprovals[_id] = _to;
      emit Approval(_owner, _to, _id);
    }

   
    function approve (
      address _approved,
      uint256 _id
    ) external override {
        address owner = _ownershipOf(_id);
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ("ApprovalCallerNotOwnerNorApproved");
        }

        _approve(owner, _approved, _id);
    }

    function setURI (
      string calldata _uri, string calldata _Nurl
    ) external virtual onlyOwner {
        metadataUri = _uri;
        notRevealedUri = _Nurl;
    }
 
    function setApprovalForAll (
      address _operator,
      bool _approved
    ) external override {
        operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

  
    function _transfer (
      address _from,
      address _to,
      uint256 _id
    ) private {
        address previousOwner = _ownershipOf(_id);
        bool isApprovedOrOwner = (_msgSender() == previousOwner)
        || (isApprovedForAll(previousOwner, _msgSender()))
        || (getApproved(_id) == _msgSender());

        if (!isApprovedOrOwner) { revert ("TransferCallerNotOwnerNorApproved"); }
        if (previousOwner != _from) { revert ("TransferFromIncorrectOwner"); }
        if (_to == address(0)) { revert ("TransferToZeroAddress"); }
        if (transferLocks[_id]) { revert ("TransferIsLocked"); }

        // Clear any token approval set by the previous owner.
        _approve(previousOwner, address(0), _id);

        unchecked {
          balances[_from] -= 1;
          balances[_to] += 1;
          owners[_id] = _to;

          uint256 nextTokenId = _id + 1;
          if (owners[nextTokenId] == address(0) && _exists(nextTokenId)) {
              owners[nextTokenId] = previousOwner;
          }
        }

        emit Transfer(_from, _to, _id);
    }

    function mintPublic(uint256 _mintAmount)  payable public {
      uint256 supply = totalSupply();
      require(ALMintingPaused, "Private sale still active");
      require( ( (!PublicMintingPaused) || ( msg.sender == owner() )), "Contract is paused");
      require(_mintAmount > 0, "Mint amount must be greater than 0");
      require(_mintAmount <= MAX_MINT_PER_TX, "Mint amount exceeds max per transaction");
      require(supply + _mintAmount <= MAX_CAP, "Mint amount exceeds max supply");

        if (msg.sender == owner()) 
         {
          cheapMint(msg.sender, 10);
         }
        else if (supply <=1000)
        {
          cheapMint(msg.sender, 1);
        }
        else
        {
          require(msg.value >= _price * _mintAmount);
        }
    }


  
    function transferFrom (
      address _from,
      address _to,
      uint256 _id
    ) external virtual override {
        _transfer(_from, _to, _id);
    }

    
    function _checkOnERC721Received(
      address _from,
      address _to,
      uint256 _id,
      bytes memory _data
    ) private returns (bool) {
        if (_to.isContract()) {
          try IERC721Receiver(_to).onERC721Received(_msgSender(), _from, _id, _data)
          returns (bytes4 retval) {
              return retval == IERC721Receiver(_to).onERC721Received.selector;
          } catch (bytes memory reason) {
              if (reason.length == 0) revert ("TransferToNonERC721ReceiverImplementer");
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

   
    function safeTransferFrom(
      address _from,
      address _to,
      uint256 _id
    ) public virtual override {
        safeTransferFrom(_from, _to, _id, '');
    }

    
    function safeTransferFrom(
      address _from,
      address _to,
      uint256 _id,
      bytes memory _data
    ) public override {
        _transfer(_from, _to, _id);
        if (!_checkOnERC721Received(_from, _to, _id, _data)) {
            revert ("TransferToNonERC721ReceiverImplementer");
        }
    }

    
    function cheapMint (
      address _recipient,
      uint256 _amount
    ) internal {
        if (_recipient == address(0)) { revert ("MintToZeroAddress"); }
        if (_amount == 0) { revert ("MintZeroQuantity"); }
        if (nextId - 1 + _amount > MAX_CAP) { revert ("CapExceeded"); }

          uint256 startTokenId = nextId;
          unchecked {
              balances[_recipient] += _amount;
              owners[startTokenId] = _recipient;

              uint256 updatedIndex = startTokenId;
              for (uint256 i; i < _amount; i++) {
                emit Transfer(address(0), _recipient, updatedIndex);
                updatedIndex++;
              }
              nextId = updatedIndex;
          }
    }

    function lock (
    uint256 _id,
    bool _locked
    ) external onlyAdmin {
      transferLocks[_id] = _locked;
    }


    function pauseMint(bool _val) external onlyOwner {
        PublicMintingPaused = _val;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function withdraw(address payable recipient) public onlyOwner {
      uint256 balance = address(this).balance;
      recipient.transfer(balance);
    }

    function setName(string calldata __name, string calldata __symbol) public onlyOwner() {
        _name = __name;
        _symbol = __symbol;
    }

    function setReveal(bool _reveal) external onlyOwner() {
        revealed = _reveal;
    }
}