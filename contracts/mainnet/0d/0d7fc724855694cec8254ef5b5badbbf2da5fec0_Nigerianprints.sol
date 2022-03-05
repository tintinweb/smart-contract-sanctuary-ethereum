/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;                                                                                                                                

// NNNNNNNN        NNNNNNNN  iiii                                                               iiii                                     
// N:::::::N       N::::::N i::::i                                                             i::::i                                    
// N::::::::N      N::::::N  iiii                                                               iiii                                     
// N:::::::::N     N::::::N                                                                                                              
// N::::::::::N    N::::::Niiiiiii    ggggggggg   ggggg    eeeeeeeeeeee    rrrrr   rrrrrrrrr  iiiiiii   aaaaaaaaaaaaa  nnnn  nnnnnnnn    
// N:::::::::::N   N::::::Ni:::::i   g:::::::::ggg::::g  ee::::::::::::ee  r::::rrr:::::::::r i:::::i   a::::::::::::a n:::nn::::::::nn  
// N:::::::N::::N  N::::::N i::::i  g:::::::::::::::::g e::::::eeeee:::::eer:::::::::::::::::r i::::i   aaaaaaaaa:::::an::::::::::::::nn 
// N::::::N N::::N N::::::N i::::i g::::::ggggg::::::gge::::::e     e:::::err::::::rrrrr::::::ri::::i            a::::ann:::::::::::::::n
// N::::::N  N::::N:::::::N i::::i g:::::g     g:::::g e:::::::eeeee::::::e r:::::r     r:::::ri::::i     aaaaaaa:::::a  n:::::nnnn:::::n
// N::::::N   N:::::::::::N i::::i g:::::g     g:::::g e:::::::::::::::::e  r:::::r     rrrrrrri::::i   aa::::::::::::a  n::::n    n::::n
// N::::::N    N::::::::::N i::::i g:::::g     g:::::g e::::::eeeeeeeeeee   r:::::r            i::::i  a::::aaaa::::::a  n::::n    n::::n
// N::::::N     N:::::::::N i::::i g::::::g    g:::::g e:::::::e            r:::::r            i::::i a::::a    a:::::a  n::::n    n::::n
// N::::::N      N::::::::Ni::::::ig:::::::ggggg:::::g e::::::::e           r:::::r           i::::::ia::::a    a:::::a  n::::n    n::::n
// N::::::N       N:::::::Ni::::::i g::::::::::::::::g  e::::::::eeeeeeee   r:::::r           i::::::ia:::::aaaa::::::a  n::::n    n::::n
// N::::::N        N::::::Ni::::::i  gg::::::::::::::g   ee:::::::::::::e   r:::::r           i::::::i a::::::::::aa:::a n::::n    n::::n
// NNNNNNNN         NNNNNNNiiiiiiii    gggggggg::::::g     eeeeeeeeeeeeee   rrrrrrr           iiiiiiii  aaaaaaaaaa  aaaa nnnnnn    nnnnnn
//                                             g:::::g                                                                                   
//                                 gggggg      g:::::g                                                                                   
//                                 g:::::gg   gg:::::g                                                                                   
//                                  g::::::ggg:::::::g                                                                                   
//                                   gg:::::::::::::g                                                                                    
//                                     ggg::::::ggg                                                                                      
//                                        gggggg                                                                                         
                                                                                                                                      
                                                                                                                                      
// PPPPPPPPPPPPPPPPP                        iiii                            tttt                                                         
// P::::::::::::::::P                      i::::i                        ttt:::t                                                         
// P::::::PPPPPP:::::P                      iiii                         t:::::t                                                         
// PP:::::P     P:::::P                                                  t:::::t                                                         
//   P::::P     P:::::Prrrrr   rrrrrrrrr  iiiiiiinnnn  nnnnnnnn    ttttttt:::::ttttttt        ssssssssss                                 
//   P::::P     P:::::Pr::::rrr:::::::::r i:::::in:::nn::::::::nn  t:::::::::::::::::t      ss::::::::::s                                
//   P::::PPPPPP:::::P r:::::::::::::::::r i::::in::::::::::::::nn t:::::::::::::::::t    ss:::::::::::::s                               
//   P:::::::::::::PP  rr::::::rrrrr::::::ri::::inn:::::::::::::::ntttttt:::::::tttttt    s::::::ssss:::::s                              
//   P::::PPPPPPPPP     r:::::r     r:::::ri::::i  n:::::nnnn:::::n      t:::::t           s:::::s  ssssss                               
//   P::::P             r:::::r     rrrrrrri::::i  n::::n    n::::n      t:::::t             s::::::s                                    
//   P::::P             r:::::r            i::::i  n::::n    n::::n      t:::::t                s::::::s                                 
//   P::::P             r:::::r            i::::i  n::::n    n::::n      t:::::t    ttttttssssss   s:::::s                               
// PP::::::PP           r:::::r           i::::::i n::::n    n::::n      t::::::tttt:::::ts:::::ssss::::::s                              
// P::::::::P           r:::::r           i::::::i n::::n    n::::n      tt::::::::::::::ts::::::::::::::s                               
// P::::::::P           r:::::r           i::::::i n::::n    n::::n        tt:::::::::::tt s:::::::::::ss                                
// PPPPPPPPPP           rrrrrrr           iiiiiiii nnnnnn    nnnnnn          ttttttttttt    sssssssssss  

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error AuxQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
    }

    struct AddressData {
        uint64 balance;
        uint64 numberMinted;
        uint64 numberBurned;
        uint64 aux;
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
        _currentIndex = _startTokenId();
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function totalSupply() public view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    function _totalMinted() internal view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
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

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        unchecked {
            _addressData[to].balance += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);

                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        _approve(address(0), tokenId, prevOwnership.addr);
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
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

    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
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

contract Nigerianprints is ERC721A {
    bool _revealed = false;

    string private baseURI = "ipfs://QmbydyuYbqbzNpeoLZnebFfo4Si7dfA1LbC7pWmXxoFhEM/1.json";

    constructor() ERC721A("Nigerianprints", "PRINCE") {}

    function mint(uint256 numberOfTokens) external payable {
        require(
            numberOfTokens + totalSupply() <= 6969,
            "Not enough supply"
        );
        require(msg.value >= (0.01 ether) * numberOfTokens, "Not enough ETH");
        _safeMint(msg.sender, numberOfTokens);
    }

    function reveal(bool revealed, string calldata _baseURI) external {
        require(
            msg.sender == 0x05ee4701712a1Ef5f8C6566C4aaf9B807D63092c || msg.sender == 0x3c73Dcfa22f9A8D677750ad983E79dA747E880BC
        , "It aint ez bein breeeshy");
        _revealed = revealed;
        baseURI = _baseURI;
    }

    function withdraw() external {
        require(
            msg.sender == 0x05ee4701712a1Ef5f8C6566C4aaf9B807D63092c || msg.sender == 0x3c73Dcfa22f9A8D677750ad983E79dA747E880BC
        , "It aint ez bein breeeshy");
        payable(0x3c73Dcfa22f9A8D677750ad983E79dA747E880BC).transfer((address(this).balance * 5000) / 69690);
        payable(0x05ee4701712a1Ef5f8C6566C4aaf9B807D63092c).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (_revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }
}