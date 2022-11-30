// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./SafeMath.sol";
import "./IERC1155.sol";
import "./ERC165.sol";
import "./IHandlerCallback.sol";
import "./IsSerializedUpgradable.sol";
import "./Clonable.sol";
// import "./Stream.sol";
// import "./EventableERC1155.sol";
import "./ERC2981Royalties.sol";
import "./UpgradableERC1155.sol";

contract ERC1155Upgradable is ERC165, IERC1155MetadataURI, IsSerializedUpgradable, Clonable, ERC2981Royalties, UpgradableERC1155 {
    using SafeMath for uint256;
    address payable public streamAddress;

    mapping (uint256 => mapping(address => uint256)) private _balances;
    mapping (address => mapping(address => bool)) private _operatorApprovals;
    mapping (uint256 => bool) private usedTokenId;
    // uint256[] public tokenIds;

    string private name;
    string private symbol;

    string private _uri;

    mapping (address => mapping (uint => bool)) seenInBlock;
    

    constructor () {
        // __Ownable_init();
    }

    modifier oncePerBlock(address to) {
        require(!seenInBlock[to][block.number], 'already seen this block');
        _;
    }

    function upgradeFrom(address oldContract) public onlyOwner virtual override {
       UpgradableERC1155.upgradeFrom(oldContract);
    }

    // function  makeEvents(address[] calldata operators, uint256[] calldata tokenIds, address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) public onlyOwner override {
    //     EventableERC1155.makeEvents(operators, tokenIds, _from, _to, amounts);
    // }

    function initialize() public override initializer {
        __Ownable_init();
        _registerInterface(0xd9b67a26); //_INTERFACE_ID_ERC1155
        _registerInterface(0x0e89341c); //_INTERFACE_ID_ERC1155_METADATA_URI
        initializeERC165();
        _registerInterface(0x2a55205a); // ERC2981
        _uri = "https://api.emblemvault.io/s:evmetadata/meta/"; 
        serialized = true;
        overloadSerial = false;
        isClaimable = true;
        // initStream();
    }

    // function initStream() private onlyOwner {
    //     streamAddress = payable(address(new Stream()));
    //     Stream(streamAddress).initialize();
    //     OwnableUpgradeable(streamAddress).transferOwnership(_msgSender());
    //     Stream(streamAddress).addMember(Stream.Member(owner(), 1, 1)); // add owner as stream recipient
    //     IERC2981Royalties(this).setTokenRoyalty(0, streamAddress, 10000); // set contract wide royalties to stream
    // }

    function version() public pure override returns(uint256) {
        return 3;
    }

    function changeName(string calldata _name, string calldata _symbol) public onlyOwner {
      name = _name;
      symbol = _symbol;
    }

    function mint(address _to, uint256 _tokenId, uint256 _amount) public onlyOwner oncePerBlock(_to) {
        bytes memory empty = abi.encodePacked(uint256(0));
        
        mintWithSerial(_to, _tokenId, _amount, empty);
    }

    function mintWithSerial(address _to, uint256 _tokenId, uint256 _amount, bytes memory serialNumber) public onlyOwner oncePerBlock(_to) {
        _mint(_to, _tokenId, _amount, serialNumber);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes[] memory serialNumbers) public onlyOwner oncePerBlock(to) {
        _mintBatch(to, ids, amounts, serialNumbers);
    }

    function burn(address _from, uint256 _tokenId, uint256 _amount) public {
        require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()), 'Not Approved to burn');
        _burn(_from, _tokenId, _amount);
    }

    function setURI(string memory newuri) public onlyOwner {
        _uri = newuri;
    }
    
    function uri(uint256 _tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(_uri, toString(_tokenId)));
    }

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

    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return UpgradableERC1155.balanceOfHook(account, id, _balances);
    }
    
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = UpgradableERC1155.balanceOfHook(accounts[i], ids[i], _balances);
        }

        return batchBalances;
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }
    
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory) public virtual {
        bool _canBypass = canBypassForTokenId(id);
        uint256 pastSenderBalance = 0;
        uint256 pastRecipientBalance = 0;
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()) || _canBypass, "ERC1155: caller is not owner nor approved nor bypasser");

        address operator = _msgSender();

        // _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);
        (pastSenderBalance, pastRecipientBalance) = UpgradableERC1155.transferHook(from, to, id, _balances);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        if (isSerialized()) {
            for (uint i = 0; i < amount; i++) {            
                uint256 serialNumber = getFirstSerialByOwner(from, id);
                if (serialNumber != 0 ) {
                    transferSerial(serialNumber, from, to);
                }
            }
        }

        emit TransferSingle(operator, from, to, id, amount);
        UpgradableERC1155.transferEventHook(operator, from, to, id, pastSenderBalance, pastRecipientBalance);

        // _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            for (uint i = 0; i < amount; i++) {
                IHandlerCallback(registeredOfType[3][0]).executeCallbacks(from, to, id, IHandlerCallback.CallbackType.TRANSFER);
            }
        }
    }
    
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        // _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            safeTransferFrom(from, to, id, amount, data);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        // _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _mint(address account, uint256 id, uint256 amount, bytes memory serialNumber) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");
        address operator = _msgSender();
        amount = UpgradableERC1155.mintHook(account, id, amount);
        if (isSerialized()) {
            for (uint i = 0; i < amount; i++) {
                if (overloadSerial){
                    require(toUint256(serialNumber, 0) != 0, "Must provide serial number");
                    uint256 _serialNumber = amount > 1?  decodeUintArray(abi.encodePacked(serialNumber))[i]: decodeSingle(abi.encodePacked(serialNumber));
                    mintSerial(_serialNumber, account, id);
                } else {
                    mintSerial(id, account);
                }
            }            
        }
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] == _msgSender()) {
            for (uint i = 0; i < amount; i++) {
                IHandlerCallback(_msgSender()).executeCallbacks(address(0), account, id, IHandlerCallback.CallbackType.MINT);
            }
        }
        // usedTokenId[id] = true;
        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);
    }

    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes[] memory serialNumbers) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        for (uint i = 0; i < ids.length; i++) {
            bytes memory _serialNumber = amounts[i] > 1? abi.encode(decodeUintArray(serialNumbers[i])) : serialNumbers[i];
            _mint(to, ids[i], amounts[i], _serialNumber);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
    }

    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        if (isSerialized()) {
            uint256 serialNumber = getFirstSerialByOwner(account, id);
            if (serialNumber != 0 ) {
                burnSerial(serialNumber);
            }
        }
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            IHandlerCallback(registeredOfType[3][0]).executeCallbacks(account, address(0), id, IHandlerCallback.CallbackType.BURN);
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function toUint256(bytes memory _bytes, uint256 _start) private pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    // fallback (bytes calldata input) external returns (bytes memory) {
    //     // should allow registration of fallback functions
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function mint(address _to, uint256 _tokenId, uint256 _amount) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes[] memory serialNumbers) external;
    function burn(address _from, uint256 _tokenId, uint256 _amount) external;
    function mintWithSerial(address _to, uint256 _tokenId, uint256 _amount, bytes memory serialNumber) external;
}

interface IERC1155Receiver {
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4);
}

interface IERC1155MetadataURI  {
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

contract ERC165 {

    mapping(bytes4 => bool) private supportedInterfaces;

    function initializeERC165() internal {
        require(supportedInterfaces[0x01ffc9a7] == false, "Already Registered");
        _registerInterface(0x01ffc9a7);
    }
    
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return supportedInterfaces[interfaceId];
    }
    
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        supportedInterfaces[interfaceId] = true;
    }
}

// interface IERC1155Receiver {
//     function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);
//     function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4);
// }

// interface IERC1155MetadataURI  {
//     function uri(uint256 id) external view returns (string memory);
// }

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

interface IHandlerCallback {
    enum CallbackType {
        MINT, TRANSFER, CLAIM, BURN, FALLBACK
    }

    struct Callback {
        address vault;
        address registrant;
        address target;
        bytes4 targetFunction;
        bool canRevert;
    }
    function executeCallbacksInternal(address _from, address _to, uint256 tokenId, CallbackType _type) external;
    function executeCallbacks(address _from, address _to, uint256 tokenId, CallbackType _type) external;
    function executeStoredCallbacksInternal(address _nftAddress, address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) external;
    
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./HasRegistration.sol";

contract IsSerializedUpgradable is HasRegistration {
    bool internal serialized;
    bool internal hasSerialized;
    bool internal overloadSerial;
    uint256 serialCount;
    mapping(uint256 => uint256[]) internal tokenIdToSerials;
    mapping(uint256 => uint256) internal serialToTokenId;
    mapping(uint256 => address) internal serialToOwner;
    // mapping(address => uint256) public ownerSerialCount;

    function isSerialized() public view returns (bool) {
        return serialized;
    }

    function isOverloadSerial() public view returns (bool) {
        return overloadSerial;
    }

    function toggleSerialization() public onlyOwner {
        require(!hasSerialized, "Already has serialized items");
        serialized = !serialized;
    }

    function toggleOverloadSerial() public onlyOwner {
        overloadSerial = !overloadSerial;
    }

    function mintSerial(uint256 tokenId, address _owner) internal onlyOwner {
        uint256 serialNumber = uint256(keccak256(abi.encode(tokenId, _owner, serialCount)));
        _mintSerial(serialNumber, _owner, tokenId);
    }

    function mintSerial(uint256 serialNumber, address _owner, uint256 tokenId) internal onlyOwner {
        _mintSerial(serialNumber, _owner, tokenId);
    }

    function _mintSerial(uint256 serialNumber, address _owner, uint256 tokenId)internal onlyOwner {
        require(serialToTokenId[serialNumber] == 0 && serialToOwner[serialNumber] == address(0), "Serial number already used");
        tokenIdToSerials[tokenId].push(serialNumber);
        serialToTokenId[serialNumber] = tokenId;
        serialToOwner[serialNumber] = _owner;
        // ownerSerialCount[_owner]++;
        // if (!hasSerialized) {
        //     hasSerialized = true;
        // }
        hasSerialized = true;
        serialCount++;
    }

    function transferSerial(uint256 serialNumber, address from, address to) internal {
        require(serialToOwner[serialNumber] == from, 'Not correct owner of serialnumber');
        serialToOwner[serialNumber] = to;
        // ownerSerialCount[to]++;
        // ownerSerialCount[from]--;
        // if (to == address(0)) {
        // serialToTokenId[serialNumber] = 0;
        //     uint256 tokenId = serialToTokenId[serialNumber];
        //     serialToTokenId[serialNumber] = 0;
        //     for(uint i=0; i<tokenIdToSerials[tokenId].length; i++) {
        //         if (tokenIdToSerials[tokenId][i] == serialNumber) {
        //             tokenIdToSerials[tokenId][i] = tokenIdToSerials[tokenId][tokenIdToSerials[tokenId].length - 1];
        //             tokenIdToSerials[tokenId].pop();
        //         }
        //     }
        // }
    }

function burnSerial(uint256 serialNumber) internal {
    uint256 tokenId = serialToTokenId[serialNumber];
    // serialToTokenId[serialNumber] = 0;
    serialToOwner[serialNumber] = address(0);
    // serialCount--;
    for(uint i=0; i<tokenIdToSerials[tokenId].length; i++) {
        if (tokenIdToSerials[tokenId][i] == serialNumber) {
            tokenIdToSerials[tokenId][i] = tokenIdToSerials[tokenId][tokenIdToSerials[tokenId].length - 1];
            tokenIdToSerials[tokenId].pop();
        }
    }
}


    function getSerial(uint256 tokenId, uint256 index) public view returns (uint256) {
        if(tokenIdToSerials[tokenId].length == 0) {
            return 0;
        } else {
            return tokenIdToSerials[tokenId][index];
        }
    }

    function getFirstSerialByOwner(address _owner, uint256 tokenId) public view returns (uint256) {
        for (uint256 i = 0; i < tokenIdToSerials[tokenId].length; ++i) {
           uint256 serialNumber = tokenIdToSerials[tokenId][i];
           if (serialToOwner[serialNumber] == _owner) {
               return serialNumber;
           }
        }
        return 0;
    }

    function getSerialByOwnerAtIndex(address _owner, uint256 tokenId, uint256 index) public view returns (uint256) {
        uint seen = 0;
        for (uint256 i = 0; i < tokenIdToSerials[tokenId].length; ++i) {
            uint256 serialNumber = tokenIdToSerials[tokenId][i];
            if (serialToOwner[serialNumber] == _owner) {
                if (seen == index) {
                    return serialNumber;
                } else {
                    seen++;
                }
            }
        }
        return 0;
    }

    function getOwnerOfSerial(uint256 serialNumber) public view returns (address) {
        return serialToOwner[serialNumber];
    }

    function getTokenIdForSerialNumber(uint256 serialNumber) public view returns (uint256) {
        return serialToTokenId[serialNumber];
    }

    function decodeUintArray(bytes memory encoded) internal pure returns(uint256[] memory ids){
        ids = abi.decode(encoded, (uint256[]));
    }

    function decodeSingle(bytes memory encoded) internal pure returns(uint256 id) {
        id = abi.decode(encoded, (uint));
    }
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

interface IClonable {
    function initialize() external;
    function version() external returns(uint256);  
}
abstract contract Clonable {

    function initialize() public virtual;

    function version() public pure virtual returns (uint256) {
        return 1;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './ERC2981Base.sol';
import './OwnableUpgradeable.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981Royalties is ERC2981Base {
    RoyaltyInfo private _contractRoyalties;
    mapping(uint256 => RoyaltyInfo) private _individualRoyalties;

    
    /// @dev Sets token royalties
    /// @param tokenId the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function setTokenRoyalty(uint256 tokenId, address recipient, uint256 value) public override {
        require(msg.sender == OwnableUpgradeable(address(this)).owner(), "Not Owner");
        require(value <= 10000, 'ERC2981Royalties: Too high');
        if (tokenId == 0) {
            _contractRoyalties = RoyaltyInfo(recipient, uint24(value));
        } else {
            _individualRoyalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
        }
    }

    function royaltyInfo(uint256 tokenId, uint256 value) public view override returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalties = _individualRoyalties[tokenId].recipient != address(0)? _individualRoyalties[tokenId]: _contractRoyalties;
        
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

import "./IERC1155.sol";
import "./SafeMath.sol";
import "./EventableERC1155.sol";

interface IUpgradableERC1155 {
    function upgradeFrom(address oldContract) external;
}

abstract contract UpgradableERC1155 is IUpgradableERC1155, EventableERC1155  {
    using SafeMath for uint256;

    bool internal _isUpgrade;
    address public upgradedFrom;
    uint256 internal _totalMoved;
    mapping(address => uint256) internal _supplyMoved;
    mapping(address => bool) public seen;

    function isUpgrade() public view returns (bool) {
        return _isUpgrade;
    }

    function upgradeFrom(address oldContract) public virtual override {
        require(!_isUpgrade, "Contract already an upgrade");
        require(oldContract != address(0), "Invalid Upgrade");
        _isUpgrade = true;
        upgradedFrom = oldContract;
    }

    function transferHook(address sender, address recipient, uint256 tokenId, mapping(uint256 => mapping(address => uint256)) storage _balances) internal returns (uint256, uint256) {
        uint256 pastSenderBalance = 0;
        uint256 pastRecipientBalance = 0;
        if (!seen[sender]) {
            seen[sender] = true;
        }
        if (!seen[recipient]) {
            seen[recipient] = true;
        }
        address seenSenderAddress = tokenIdToAddress(sender, tokenId);
        address seenRecipientAddress = tokenIdToAddress(recipient, tokenId);
        if (isUpgrade()) {
            if (!seen[seenSenderAddress]) {
                seen[seenSenderAddress] = true;
                pastSenderBalance = IERC1155(upgradedFrom).balanceOf(sender, tokenId);
                _supplyMoved[sender] = _supplyMoved[sender].add(pastSenderBalance);
                _balances[tokenId][sender] = _balances[tokenId][sender].add(pastSenderBalance);
                _totalMoved = _totalMoved.add(pastSenderBalance);
            }
            if (!seen[seenRecipientAddress]) {
                seen[seenRecipientAddress] = true;
                pastRecipientBalance = IERC1155(upgradedFrom).balanceOf(recipient, tokenId);
                _supplyMoved[sender] = _supplyMoved[sender].add(pastRecipientBalance);
                _balances[tokenId][recipient] = _balances[tokenId][recipient].add(pastRecipientBalance);
            }
        } else {
            if (!seen[seenSenderAddress]) {
                seen[seenSenderAddress] = true;
            }
            if (!seen[seenRecipientAddress]) {
                seen[seenRecipientAddress] = true;
            }
        }
        return (pastSenderBalance, pastRecipientBalance);
    }

    function transferEventHook(address operator, address sender, address recipient, uint256 tokenId, uint256 pastSenderBalance, uint256 pastRecipientBalance) internal {
        if (pastSenderBalance > 0) {
                emit TransferSingle(operator, address(0), sender, tokenId, pastSenderBalance);
            }
            if (pastRecipientBalance >0) {
                emit TransferSingle(operator, address(0), recipient, tokenId, pastRecipientBalance);
            }
    }

    function balanceOfHook(address account, uint256 tokenId, mapping(uint256 => mapping(address => uint256)) storage _balances) internal view returns(uint256) {
        uint256 oldBalance = 0;
        if (isUpgrade()) {
            oldBalance = IERC1155(upgradedFrom).balanceOf(account, tokenId);
        }
        return (isUpgrade() && !seen[account]) ? IERC1155(upgradedFrom).balanceOf(account, tokenId):  _balances[tokenId][account];
    }

    function mintHook(address account, uint256 tokenId, uint256 amount) internal returns (uint256) {
        if (!seen[account]) {
            seen[account] = true;
        }
        address seenAddress = tokenIdToAddress(account, tokenId);
        if (isUpgrade()) {
            if (!seen[seenAddress]) {
                seen[seenAddress] = true;
                uint256 pastBalance = IERC1155(upgradedFrom).balanceOf(account, tokenId);
                _supplyMoved[account] = _supplyMoved[account].add(pastBalance);
                amount = amount.add(pastBalance);
                _totalMoved = _totalMoved.add(pastBalance);
            }
        } else {
            if (!seen[account]) {
                seen[account] = true;
            }
        }
        return amount;
    }

    function tokenIdToAddress(address account, uint256 tokenId) internal pure returns (address) {
        bytes32 seenHash = keccak256(abi.encodePacked(account, tokenId));
        return address(uint160(uint256(seenHash)));
    }
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./IsBypassable.sol";

contract HasRegistration is IsBypassable {

    mapping(address => uint256) public registeredContracts; // 0 EMPTY, 1 ERC1155, 2 ERC721, 3 HANDLER, 4 ERC20, 5 BALANCE, 6 CLAIM, 7 UNKNOWN, 8 FACTORY, 9 STAKING, 10 BYPASS
    mapping(uint256 => address[]) internal registeredOfType;

    modifier isRegisteredContract(address _contract) {
        require(registeredContracts[_contract] > 0, "Contract is not registered");
        _;
    }

    modifier isRegisteredContractOrOwner(address _contract) {
        require(registeredContracts[_contract] > 0 || owner() == _msgSender(), "Contract is not registered nor Owner");
        _;
    }

    function registerContract(address _contract, uint _type) public isRegisteredContractOrOwner(_msgSender()) {
        registeredContracts[_contract] = _type;
        registeredOfType[_type].push(_contract);
    }

    function unregisterContract(address _contract, uint256 index) public onlyOwner isRegisteredContract(_contract) {
        address[] storage arr = registeredOfType[registeredContracts[_contract]];
        arr[index] = arr[arr.length - 1];
        arr.pop();
        delete registeredContracts[_contract];
    }

    function isRegistered(address _contract, uint256 _type) public view returns (bool) {
        return registeredContracts[_contract] == _type;
    }

    function getAllRegisteredContractsOfType(uint256 _type) public view returns (address[] memory) {
        return registeredOfType[_type];
    }
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

import "./IsClaimable.sol";

abstract contract IsBypassable is IsClaimable {

    bool byPassable;
    mapping(address => mapping(bytes4 => bool)) byPassableFunction;
    mapping(address => mapping(uint256 => bool)) byPassableIds;

    modifier onlyOwner virtual override {
        bool _canBypass = byPassable && byPassableFunction[_msgSender()][msg.sig];
        require(owner() == _msgSender() || _canBypass, "Not owner or able to bypass");
            _;
    }

    modifier onlyOwnerOrBypassWithId(uint256 id) {
        require (owner() == _msgSender() || (id != 0 && byPassableIds[_msgSender()][id] ), "Invalid id");
            _;
    }

    function canBypass() internal view returns(bool) {
        return (byPassable && byPassableFunction[_msgSender()][msg.sig]);
    }

    function canBypassForTokenId(uint256 id) internal view returns(bool) {
        return (byPassable && canBypass() && byPassableIds[_msgSender()][id]);
    }

    function toggleBypassability() public onlyOwner {
      byPassable = !byPassable;
    }

    function addBypassRule(address who, bytes4 functionSig, uint256 id) public onlyOwner {
        byPassableFunction[who][functionSig] = true;
        if (id != 0) {
            byPassableIds[who][id] = true;
        }        
    }

    function removeBypassRule(address who, bytes4 functionSig, uint256 id) public onlyOwner {
        byPassableFunction[who][functionSig] = false;
        if (id !=0) {
            byPassableIds[who][id] = true;
        }
    }
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./OwnableUpgradeable.sol";
abstract contract IsClaimable is OwnableUpgradeable {

    bool public isClaimable;

    function toggleClaimable() public onlyOwner {
        isClaimable = !isClaimable;
    }
   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    modifier onlyOwner() virtual {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
pragma solidity ^0.8.0;
import './IERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is IERC2981Royalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC2981Royalties {
   function setTokenRoyalty(uint256 tokenId, address recipient, uint256 value) external;
   function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

interface IEventableERC1155 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    // function makeEvents(address[] calldata operators, uint256[] calldata tokenIds, address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) external;
}

abstract contract EventableERC1155 is IEventableERC1155 {
    // function makeEvents(address[] calldata operators, uint256[] calldata tokenIds, address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) public virtual override {
    //     _handleEventOperatorLoops(operators, tokenIds, _from, _to, amounts);
    // }    
    // function _handleEventOperatorLoops(address[] calldata operators, uint256[] calldata tokenIds, address[] calldata _from, address[] calldata _to, uint256[] calldata  amounts) internal {
    //     for (uint i=0; i < operators.length; i++) {
    //         if (amounts.length == operators.length && amounts.length == _from.length && amounts.length == _to.length && amounts.length == tokenIds.length) {
    //             _handleEventEmits(operators[i], tokenIds[i], _from[i], _to[i], makeSingleArray(amounts, i));
    //         } else {
    //             _handleEventTokenIdLoops(operators[i], tokenIds, _from, _to, amounts);
    //         }
    //     }
    // }
    // function _handleEventTokenIdLoops(address operator, uint256[] calldata tokenIds, address[] calldata _from, address[] calldata _to, uint256[] calldata  amounts) internal {
    //     for (uint i=0; i < tokenIds.length; i++) {
    //         if (amounts.length == tokenIds.length && tokenIds.length == amounts.length && _from.length == amounts.length && _to.length == amounts.length) {
    //             _handleEventEmits(operator, tokenIds[i], _from[i], _to[i], makeSingleArray(amounts, i));
    //         } else {
    //             _handleEventFromLoops(operator, tokenIds[i], _from, _to, amounts);
    //         }
    //     }
    // }
    // function _handleEventFromLoops(address operator, uint256 tokenId, address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) internal {
    //     for (uint i=0; i < _from.length; i++) {
    //         if (amounts.length == _from.length && amounts.length == _to.length) {
    //             _handleEventEmits(operator, tokenId, _from[i], _to[i], makeSingleArray(amounts, i));
    //         } else if (amounts.length == _from.length && amounts.length != _to.length) {
    //             _handleEventToLoops(operator, tokenId, _from[i], _to, makeSingleArray(amounts, i));
    //         } else {
    //             _handleEventToLoops(operator, tokenId, _from[i], _to, amounts);
    //         }
    //     }
    // }
    // function _handleEventToLoops(address operator, uint256 tokenId, address _from, address[] calldata _to, uint256[] memory amounts) internal {
    //     for (uint i=0; i < _to.length; i++) {
    //         if (amounts.length == _to.length) {
    //             _handleEventEmits(operator, tokenId, _from, _to[i], makeSingleArray(amounts, i));
    //         } else {
    //             _handleEventEmits(operator, tokenId,_from, _to[i], amounts);
    //         }
    //     }
    // }
    // function _handleEventEmits(address operator, uint256 tokenId, address _from, address _to, uint256[] memory amounts) internal {
    //     for (uint i=0; i < amounts.length; i++) {
    //         emit TransferSingle(operator, _from, _to, tokenId, amounts[i]);
    //     }
    // }
    // function makeSingleArray(uint256[] memory amount, uint index) internal pure returns (uint256[] memory) {
    //     uint256[] memory arr = new uint256[](1);
    //     arr[0] = amount[index];
    //     return arr;
    // }
}