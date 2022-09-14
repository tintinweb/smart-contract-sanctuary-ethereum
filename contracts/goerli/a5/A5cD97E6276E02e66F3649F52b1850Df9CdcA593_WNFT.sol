/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

pragma solidity ^0.8.0;


interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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





            



pragma solidity ^0.8.0;




abstract contract ERC165 is IERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}





            



pragma solidity ^0.8.0;


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





            



pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}





            



pragma solidity ^0.8.1;


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




interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

interface IERC5496 {
    event PrivilegeAssigned(uint tokenId, uint privId, address user, uint64 expires);
    event PrivilegeTransfer(uint tokenId, uint privId, address from, address to);
    event PrivilegeTotalChanged(uint newTotal, uint oldTotal);
    function setPrivilege(uint256 tokenId, uint privId, address user, uint64 expires) external;
    function hasPrivilege(uint256 tokenId, uint256 privId, address user) external view returns(bool);
    function privilegeExpires(uint256 tokenId, uint256 privId) external view returns(uint256);
}




            



pragma solidity ^0.8.0;










contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    
    string private _name;

    
    string private _symbol;

    
    mapping(uint256 => address) private _owners;

    
    mapping(address => uint256) private _balances;

    
    mapping(uint256 => address) private _tokenApprovals;

    
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}





            

pragma solidity ^0.8.0;

interface IERC5496Cloneable {
    event PrivilegeCloned(uint tokenId, uint privId, address from, address to);
    function clonePrivilege(uint tokenId, uint privId, address referrer) external returns (bool);
}




            

pragma solidity ^0.8.0; 




contract ERC5496 is ERC721, IERC5496 {
    struct PrivilegeRecord {
        address user;
        uint256 expiresAt;
    }
    struct PrivilegeStorage {
        uint lastExpiresAt;
        
        mapping(uint => PrivilegeRecord) privilegeEntry;
    }

    uint public privilegeTotal;
    
    mapping(uint => PrivilegeStorage) public privilegeBook;
    mapping(address => mapping(address => bool)) public privilegeDelegator;

    constructor(string memory name_, string memory symbol_)
    ERC721(name_,symbol_)
    {
    
    }

    function setPrivilege(
        uint tokenId,
        uint privId,
        address user,
        uint64 expires
    ) external virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId) || _isDelegatorOrHolder(msg.sender, tokenId, privId), "ERC721: transfer caller is not owner nor approved");
        require(expires < block.timestamp + 30 days, "expire time invalid");
        require(privId < privilegeTotal, "invalid privilege id");
        privilegeBook[tokenId].privilegeEntry[privId].user = user;
        if (_isApprovedOrOwner(msg.sender, tokenId)) {
            privilegeBook[tokenId].privilegeEntry[privId].expiresAt = expires;
            if (privilegeBook[tokenId].lastExpiresAt < expires) {
                privilegeBook[tokenId].lastExpiresAt = expires;
            }
        }
        emit PrivilegeAssigned(tokenId, privId, user, uint64(privilegeBook[tokenId].privilegeEntry[privId].expiresAt));
    }

    function hasPrivilege(
        uint256 tokenId,
        uint256 privId,
        address user
    ) public virtual view returns(bool) {
        if ( privilegeBook[tokenId].privilegeEntry[privId].expiresAt >=  block.timestamp ){
            return privilegeBook[tokenId].privilegeEntry[privId].user == user;
        }
        return ownerOf(tokenId) == user;
    }

    function privilegeExpires(
        uint256 tokenId,
        uint256 privId
    ) public virtual view returns(uint256){
        return privilegeBook[tokenId].privilegeEntry[privId].expiresAt;
    }

    function _setPrivilegeTotal(
        uint total
    ) internal {
        emit PrivilegeTotalChanged(total, privilegeTotal);
        privilegeTotal = total;
    }

    function getPrivilegeInfo(uint tokenId, uint privId) external view returns(address user, uint256 expiresAt) {
        return (privilegeBook[tokenId].privilegeEntry[privId].user, privilegeBook[tokenId].privilegeEntry[privId].expiresAt);
    }

    function setDelegator(address delegator, bool enabled) external {
        privilegeDelegator[msg.sender][delegator] = enabled;
    }

    function _isDelegatorOrHolder(address delegator, uint256 tokenId, uint privId) internal virtual view returns (bool) {
        address holder = privilegeBook[tokenId].privilegeEntry[privId].user;
        return (delegator == holder || isApprovedForAll(holder, delegator) || privilegeDelegator[holder][delegator]);
    }

    function supportsInterface(bytes4 interfaceId) public override virtual view returns (bool) {
        return interfaceId == type(IERC5496).interfaceId || super.supportsInterface(interfaceId);
    }
}




            



pragma solidity ^0.8.0;





abstract contract ERC5496Cloneable is ERC5496, IERC5496Cloneable {
    struct CloneableRecord {
        
        mapping(address => bool) shared;
        
        mapping(address => address) referrer;
    }

    
    mapping(uint => bool) public cloneable;
    
    mapping(uint => mapping(uint => CloneableRecord)) cloneableSetting;

    function supportsInterface(bytes4 interfaceId) public override virtual view returns (bool) {
        return interfaceId == type(IERC5496Cloneable).interfaceId || super.supportsInterface(interfaceId);
    }

    function hasPrivilege(
        uint256 tokenId,
        uint256 privId,
        address user
    ) public override virtual view returns(bool) {
        if ( privilegeBook[tokenId].privilegeEntry[privId].expiresAt >=  block.timestamp ){
            return cloneableSetting[tokenId][privId].shared[user] || super.hasPrivilege(tokenId, privId, user);
        }
        return ownerOf(tokenId) == user;
    }

    function clonePrivilege(uint tokenId, uint privId, address referrer) external returns (bool) {
        require(cloneable[privId], "privilege not cloneable");
        return _clonePrivilege(tokenId, privId, referrer);
    }

    function _clonePrivilege(uint tokenId, uint privId, address referrer) internal returns (bool) {
        require(privilegeBook[tokenId].privilegeEntry[privId].user == referrer || cloneableSetting[tokenId][privId].shared[referrer], "referrer not exists");
        if (cloneableSetting[tokenId][privId].referrer[msg.sender] == address(0)) {
            cloneableSetting[tokenId][privId].shared[msg.sender] = true;
            cloneableSetting[tokenId][privId].referrer[msg.sender] = referrer;
            emit PrivilegeCloned(tokenId, privId, referrer, msg.sender);
            return true;
        }
        return false;
    }
    
}





pragma solidity ^0.8.0; 






contract WNFT is ERC5496Cloneable, IERC721Receiver {
    event Wrap(address indexed nft, uint tokenId, address sender, address receiver);
    event Unwrap(address indexed nft, uint tokenId, address sender, address receiver);
    address public factory;
    address public nft;
    bool private initialized;

    constructor() ERC5496("WNFT.one", "WNFT") {
        factory = msg.sender;
    }

    function initialize(address _nft) external {
        require(msg.sender == factory, 'FORBIDDEN');
        require(!initialized, "already initialized");
        nft = _nft;
        initialized = true;
    }

    function wrap(uint256 tokenId, address to) external {
        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);
        _mint(to, tokenId);
        emit Wrap(nft, tokenId, msg.sender, to);
    }

    function unwrap(uint256 tokenId, address to) external {
        require(getBlockTimestamp() >= privilegeBook[tokenId].lastExpiresAt, "any privilege in renting");
        require(ownerOf(tokenId) == msg.sender, "not owner");
        _burn(tokenId);
        IERC721(nft).transferFrom(address(this), to, tokenId);
        emit Unwrap(nft, tokenId, msg.sender, to);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function getBlockTimestamp() internal view returns (uint) {
        
        return block.timestamp;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        return IERC721Metadata(nft).tokenURI(tokenId);
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    

    function increasePrivileges(bool _cloneable) external returns(uint) {
        require(msg.sender == factory, 'FORBIDDEN');
        uint privId = privilegeTotal;
        _setPrivilegeTotal(privilegeTotal + 1);
        cloneable[privId] = _cloneable;
        return privId;
    }

}