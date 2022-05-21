//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
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

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface ISKCollection {
    function mintItem(
        address account,
        uint256 tokenId,
        uint256 supply,
        string memory tokenURI_
    ) external;


    function setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) external;
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Hatman(Address): insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Hatman(Address): unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Hatman(Address): low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Hatman(Address): low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Hatman(Address): insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Hatman(Address): call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);

        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "Hatman(SafeERC20): approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "Hatman(SafeERC20): decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "Hatman(SafeERC20): low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "Hatman(SafeERC20): ERC20 operation did not succeed");
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

contract Trustable is Context {
    address private _owner;
    mapping (address => bool) private _isTrusted;

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner {
        require(_owner == _msgSender(), "SKMarketPlace: Caller is not the owner");
        _;
    }

    modifier isTrusted {
        require(_isTrusted[_msgSender()] == true || _owner == _msgSender(), "SKMarketPlace: Caller is not trusted");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "SKMarketPlace: New owner is the zero address");
        _owner = newOwner;
    }

    function addTrusted(address user) public onlyOwner {
        _isTrusted[user] = true;
    }

    function removeTrusted(address user) public onlyOwner {
        _isTrusted[user] = false;
    }
}

contract Pausable is Trustable {
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused || _msgSender() == owner());
        _;        
    }

    modifier whenPaused() {
        require(paused || _msgSender() == owner());
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }
}

contract SKMarketPlace is Pausable {
    using SafeERC20 for IERC20;
    
    IERC20 private vxlToken; // Voxel Token Address

    bytes32 public DOMAIN_SEPARATOR;
    string constant public domainName = "SuperKluster";
    string constant public version = "1";

    uint256 private feeDecimals = 2;
    uint256 private serviceFee = 0; // decimal 2
    address private skTeamWallet;

    address private signer; // Marketplace public key

    mapping (address => bool) public skCollection;
    mapping (address => uint256) public nonces;

    bytes32 constant public ADDITEM_TYPEHASH = keccak256("AddItem(address collection,address account,uint256 tokenId,uint256 supply,string memory tokenURI,uint256 nonce,uint256 deadline)");
    bytes32 constant public BUYITEM_TYPEHASH = keccak256("BuyItem(address collection,address buyer,address seller,uint256 tokenId,uint256 quantity,uint256 price,uint256 nonce,uint256 deadline)");
    bytes32 constant public ACCEPTITEM_TYPEHASH = keccak256("AcceptItem(address collection,address buyer,address seller,uint256 tokenId,uint256 quantity,uint256 price,uint256 nonce,uint256 deadline)");
    bytes32 constant public UPDATEITEMMETADATA_TYPEHASH = keccak256("UpdateItemMetaData(address collection,address account,uint256 tokenId,string memory tokenURI,uint256 nonce,uint256 deadline)");

    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
    bytes4 private constant InterfaceId_ERC1155 = 0xd9b67a26;

    event SetVxlTokenAddress(address indexed newVxlToken);
    
    event AddSKCollection(address newCollection);
    event RemoveSKCollection(address collection);
    event AddItem(address collection, address from, uint256 tokenId, uint256 quantity, string tokenURI, uint256 timestamp);
    event BuyItem(address collection, address buyer, address seller, uint256 tokenId, uint256 quantity, uint256 price, uint256 timestamp);
    event AcceptItem(address collection, address seller, address buyer, uint256 tokenId, uint256 quantity, uint256 price, uint256 timestamp);

    event UpdateItemMetaData(address collection, address from, uint256 tokenId, string tokenURI, uint256 timestamp);

    constructor(
        address _vxlToken,
        address _signer,
        address _skTeamWallet
    ) {
        vxlToken = IERC20(_vxlToken);
        signer = _signer;
        skTeamWallet = _skTeamWallet;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(domainName)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )       
        );
    }

    modifier collectionCheck(address _collection) {
        require(IERC721(_collection).supportsInterface(InterfaceId_ERC721) || IERC1155(_collection).supportsInterface(InterfaceId_ERC1155),
        "SKMarketPlace: This is not ERC721/ERC1155 collection");
        _;
    }

    function getSigner() public view isTrusted returns(address) {
        return signer;
    }

    function getServiceFee() public view isTrusted returns (uint256) {
        return serviceFee;
    }
    
    function getSKTeamWallet() public view isTrusted returns(address) {
        return skTeamWallet;
    }

    function changeVxlToken(address _newVxlToken) external isTrusted {
        require(_newVxlToken != address(0x0), "SKMarketPlace: Invalid new vxltoken address");
        vxlToken = IERC20(_newVxlToken);
        emit SetVxlTokenAddress(_newVxlToken);
    }

    function addSKCollection(address _newCollection) external isTrusted whenNotPaused collectionCheck(_newCollection) {
        require(_newCollection != address(0x0), "SKMarketPlace: Invalid new collection address");
        skCollection[_newCollection] = true;

        emit AddSKCollection(_newCollection);
    }

    function removeSKCollection(address _collection) external isTrusted whenNotPaused {
        require(_collection != address(0x0), "SKMarketPlace: Invalid collection address");
        require(skCollection[_collection], "SKMarketPlace: This collection is not included in SKCollection");

        delete skCollection[_collection];

        emit RemoveSKCollection(_collection);
    }

    function addItem(
        address _collection,
        uint256 _tokenId,
        uint256 _supply,
        string memory _tokenURI,
        uint256 deadline //,
        // uint8 v, bytes32 r, bytes32 s
    ) external whenNotPaused {
        require(_collection != address(0x0), "SKMarketPlace: Invalid collection address");
        require(skCollection[_collection], "SKMarketPlace: This collection is not SKCollection");

        require(block.timestamp <= deadline, "SKMarketPlace: Invalid expiration in addItem");      

        uint256 currentValidNonce = nonces[_msgSender()];
        /*
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(ADDITEM_TYPEHASH, _collection, _msgSender(), _tokenId, _supply, _tokenURI, currentValidNonce, deadline))
            )
        ); */

        // require(signer == ecrecover(digest, v, r, s), "SKMarketPlace: Invalid Signature in addItem");
        nonces[_msgSender()] = currentValidNonce + 1;

        ISKCollection(_collection).mintItem(_msgSender(), _tokenId, _supply, _tokenURI);

        emit AddItem(_collection, _msgSender(), _tokenId, _supply, _tokenURI, block.timestamp);
    }

    function acceptItem(
        address _collection,
        address _buyer,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        uint256 deadline //,
        // uint8 v, bytes32 r, bytes32 s
    ) external whenNotPaused collectionCheck(_collection) {
        require(_collection != address(0x0), "SKMarketPlace: Invalid collection address");
        require(_buyer != address(0x0), "SKMarketPlace: Invalid buyer address");
        require(_quantity > 0, "SKMarketPlace: Quantity should be greater than zero");
        require(block.timestamp <= deadline, "SKMarketPlace: Invalid expiration in buyItem");

        uint256 currentValidNonce = nonces[_msgSender()];

        /* bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(ACCEPTITEM_TYPEHASH, _collection, _buyer, _msgSender(), _tokenId, _quantity, _price, currentValidNonce, deadline))
            )
        );
        require(signer == ecrecover(digest, v, r, s), "SKMarketPlace: Invalid Signature in acceptItem"); */

        nonces[_msgSender()] = currentValidNonce + 1;

        uint256 tokenAmount = _price;   
        uint256 feeAmount = 0;

        if(serviceFee > 0) {
            feeAmount = tokenAmount * serviceFee / (100 * 10**feeDecimals);
            tokenAmount = tokenAmount - feeAmount;
        }

        vxlToken.safeTransferFrom(_buyer, _msgSender(), tokenAmount);
        if(feeAmount > 0) {
            vxlToken.safeTransferFrom(_buyer, skTeamWallet, feeAmount);
        }
        
        //ERC721
        if(IERC721(_collection).supportsInterface(InterfaceId_ERC721)) {
            IERC721(_collection).safeTransferFrom(_msgSender(), _buyer, _tokenId);
        }
        else {
            IERC1155(_collection).safeTransferFrom(_msgSender(), _buyer, _tokenId, _quantity, "");
        }

        emit AcceptItem(_collection, _msgSender(), _buyer, _tokenId, _quantity, _price, block.timestamp);
    }

    function buyItem(
        address _collection,
        address _seller,
        uint256 _tokenId,
        uint256 _quantity,      // amount
        uint256 _price,         // item price
        uint256 deadline //,
        // uint8 v, bytes32 r, bytes32 s
    ) external whenNotPaused collectionCheck(_collection) {    
        require(_collection != address(0x0), "SKMarketPlace: Invalid collection address");
        require(_seller != address(0x0), "SKMarketPlace: Invalid seller address");
        require(_quantity > 0, "SKMarketPlace: Quantity should be greater than zero");
        require(block.timestamp <= deadline, "SKMarketPlace: Invalid expiration in buyItem");      

        uint256 currentValidNonce = nonces[_msgSender()];

        /* bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(BUYITEM_TYPEHASH, _collection, _msgSender(), _seller, _tokenId, _quantity, _price, currentValidNonce, deadline))
            )
        );

        require(signer == ecrecover(digest, v, r, s), "SKMarketPlace: Invalid Signature in buyItem"); */
        nonces[_msgSender()] = currentValidNonce + 1;

        //tranfer vxl token from buyer to seller account
        uint256 tokenAmount = _price;
        uint256 feeAmount = 0;
        if(serviceFee > 0) {
            feeAmount = tokenAmount * serviceFee / (100 * 10**feeDecimals);
            tokenAmount = tokenAmount - feeAmount;
        }
        
        vxlToken.safeTransferFrom(_msgSender(), _seller, tokenAmount);

        if(feeAmount > 0) {
            vxlToken.safeTransferFrom(_msgSender(), skTeamWallet, feeAmount);
        }

        //ERC721
        if(IERC721(_collection).supportsInterface(InterfaceId_ERC721)) {
            IERC721(_collection).safeTransferFrom(_seller, _msgSender(), _tokenId);
        }
        else {
            IERC1155(_collection).safeTransferFrom(_seller, _msgSender(), _tokenId, _quantity, "");
        }

        emit BuyItem(_collection, _msgSender(), _seller, _tokenId, _quantity, _price, block.timestamp);
    }

    function updateItemMetaData(
        address _collection, 
        uint256 _tokenId, 
        string memory _tokenURI,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s        
    ) external whenNotPaused collectionCheck(_collection) {
        
        require(_collection != address(0x0), "SKMarketPlace: Invalid collection address");            
        require(block.timestamp <= deadline, "SKMarketPlace: Invalid expiration in addItem");

        uint256 currentValidNonce = nonces[_msgSender()];

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(UPDATEITEMMETADATA_TYPEHASH, _collection, _msgSender(), _tokenId, _tokenURI, currentValidNonce, deadline))
            )
        );

        require(signer == ecrecover(digest, v, r, s), "SKMarketPlace: Invalid Signature in buyItem");
        nonces[_msgSender()] = currentValidNonce + 1;

        // update metadata
        ISKCollection(_collection).setTokenURI(_tokenId, _tokenURI);

        emit UpdateItemMetaData(_collection, _msgSender(), _tokenId, _tokenURI, block.timestamp);
    }

    function setSigner(address _signer) external isTrusted {
        require(_signer != address(0x0), "SKMarketPlace: Invalid signer");
        signer = _signer;
    }

    function setServiceFee(uint256 _serviceFee) external isTrusted {
        serviceFee = _serviceFee;
    }

    function setSKTeamWallet(address _skTeamWallet) external isTrusted {
        require(_skTeamWallet != address(0x0), "SKMarketPlace: Invalid admin team wallet address");
        skTeamWallet = _skTeamWallet;
    }
}