/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT


// File: contracts/Strings.sol



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
// File: contracts/Address.sol



pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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
// File: contracts/IERC721Receiver.sol



pragma solidity ^0.8.0;


interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: contracts/IERC165.sol



pragma solidity ^0.8.0;


interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: contracts/ERC165.sol



pragma solidity ^0.8.0;



abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
// File: contracts/IERC721.sol



pragma solidity ^0.8.0;


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

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// File: contracts/IERC721Metadata.sol



pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: contracts/Context.sol



pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: contracts/Ownable.sol



pragma solidity ^0.8.0;



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
// File: contracts/MRSC-Mainnet.sol


pragma solidity ^0.8.0;



contract knightstown is ERC165, IERC721, IERC721Metadata, Ownable{
    using Address for address;
    using Strings for uint256;

    string _name;

    string _symbol;

    string public metadataUri;

    uint256 private nextId = 1;

    mapping ( uint256 => address ) private owners;

    mapping ( address => uint256 ) private balances;

    mapping ( uint256 => address ) private tokenApprovals;

    mapping ( address => mapping( address => bool )) private operatorApprovals;

    mapping ( address => bool ) private administrators;

    mapping ( uint256 => bool ) public transferLocks;

    mapping(address => uint256) public ALAddressToCap;

    bool public PublicMintingPaused = true;
    bool public ALMintingPaused = true;

    uint256 public MAX_CAP = 6969;

    uint8 public MAX_MINT_PER_TX = 2;

    uint256 private _price = 0 ether;

    /**
      A modifier to see if a caller is an approved administrator.
    */
    modifier onlyAdmin () {
        if (_msgSender() != owner() && !administrators[_msgSender()]) {
          revert ("NotAnAdmin");
        }
        _;
    }

    constructor () {
        _name = "knightstown.wtf";
        _symbol = "KNIGHT";
        metadataUri = "https://knightstown.mypinata.cloud/ipfs/QmZQefQqKVFMXAEWZGPvUWKG3U3ib9Nx8t3vj54PEu2zv1";
    }

  function name() external override view returns (string memory name_ret){
      return _name;
  }

  function symbol() external override view returns (string memory symbol_ret){
      return _symbol;
  }

  
    function supportsInterface (
      bytes4 _interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return (  _interfaceId == type(IERC721).interfaceId)
                  || (_interfaceId == type(IERC721Metadata).interfaceId)
                  || (super.supportsInterface(_interfaceId)
                );
    }


    function totalSupply () public view returns (uint256) {
        return nextId - 1;
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
        if (!_exists(_id)) { revert ("URIQueryForNonexistentToken"); }
        return bytes(metadataUri).length != 0
        ? string(abi.encodePacked(metadataUri, _id.toString(), ".json"))
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

    function mintCommunityKnights(uint256 _mintAmount) external onlyOwner{
      uint256 supply = totalSupply();

      require( ( (!PublicMintingPaused) || ( msg.sender == owner() )), "Contract is paused");
      require(_mintAmount > 0, "Mint amount must be greater than 0");
      require(supply + _mintAmount <= MAX_CAP, "Mint amount exceeds max supply");

      cheapMint(msg.sender, _mintAmount);
    }

    function mintAllowList(uint256 _mintAmount) public {
        uint256 supply = totalSupply();
        require(!ALMintingPaused, "Private sale not active");
        require(PublicMintingPaused, "AL Finished, public sale active");
        require(_mintAmount > 0, "Mint amount must be greater than 0");
        require(_mintAmount <= MAX_MINT_PER_TX, "Mint amount exceeds max per transaction");
        require(supply + _mintAmount <= MAX_CAP, "Mint amount exceeds max supply");
        require(ALAddressToCap[msg.sender] > 0, "not eligible for allowlist mint");
        require(ALAddressToCap[msg.sender] >= _mintAmount, "can't mint that many");

        //Reduce number of allocation
        ALAddressToCap[msg.sender] -= _mintAmount;
        cheapMint(msg.sender, _mintAmount);
    }



    function mintPublic(uint256 _mintAmount)  payable public {
      uint256 supply = totalSupply();
      require(ALMintingPaused, "Private sale still active");
      require( ( (!PublicMintingPaused) || ( msg.sender == owner() )), "Contract is paused");
      require(_mintAmount > 0, "Mint amount must be greater than 0");
      require(_mintAmount <= MAX_MINT_PER_TX, "Mint amount exceeds max per transaction");
      require(supply + _mintAmount <= MAX_CAP, "Mint amount exceeds max supply");

      if (msg.sender != owner()) {
          require(msg.value >= _price * _mintAmount);
      }

      cheapMint(msg.sender, _mintAmount);
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

 
    function setAdmin (
      address _newAdmin,
      bool _isAdmin
    ) external onlyOwner {
        administrators[_newAdmin] = _isAdmin;
    }

   
    function setURI (
      string calldata _uri
    ) external virtual onlyOwner {
        metadataUri = _uri;
    }


  
    function lockKinght (
    uint256 _id,
    bool _locked
    ) external onlyAdmin {
      transferLocks[_id] = _locked;
    }


    function pauseMint(bool _val) external onlyOwner {
        PublicMintingPaused = _val;
    }

    function pauseALSale(bool _val) external onlyOwner {
        ALMintingPaused = _val;
    }


    /**
      Sets maximum mint per wallet / transaction

      @param _val True or false
    */
    function setMaxMintCapPerWallet(uint8 _val) external onlyOwner {
        MAX_MINT_PER_TX = _val;
    }

    
    function addToAllowListArray(address[] memory _allowlisted, uint256[] memory _allowedMintCnt) public onlyOwner {
      require(_allowlisted.length == _allowedMintCnt.length, "MRSC 400 - 2 arrays shall have the same length");
      for (uint256 i=0; i<_allowlisted.length; i++)
      {
          ALAddressToCap[_allowlisted[i]] = _allowedMintCnt[i];
      }
    }

    /**
      Checks how many WL mints are available for the given address

      @param _whitelistedAddr WhitelistedAddress
    */
    function getWlQuotaByAddress(address _whitelistedAddr) public view returns (uint256) {
        return ALAddressToCap[_whitelistedAddr];
    }

    /**
      Sets new price

      @param _newPrice New price
    */
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
}