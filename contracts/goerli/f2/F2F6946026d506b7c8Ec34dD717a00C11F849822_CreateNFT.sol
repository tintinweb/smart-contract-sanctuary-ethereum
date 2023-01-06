//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./ERC721.sol";
import "./ERC721Metadata.sol";

contract CreateNFT is ERC721, ERC721Metadata {
    uint256 private tokenCounts;
    mapping(uint256 => string) private tokenUrls;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721Metadata(_name, _symbol) {}

    function getTokenCounts() public view returns (uint256) {
        return tokenCounts;
    }

    ///@dev Hàm này sẽ trả về cái url của cái tokenId;

    function minNft(string memory _tokenUrl) public {
        unchecked {
            tokenCounts++;
            balances[msg.sender]++;
        }
        owners[tokenCounts] = msg.sender;
        tokenUrls[tokenCounts] = _tokenUrl;
        emit Transfer(address(0), msg.sender, tokenCounts);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error ERC721_AddressIsZero();
error ERC721_AddressIsNotExist();
error ERC721_NotAuthorized();
error ERC721_TokenIdNotExist();
error ERC721_WrongFrom();
error ERC721_UnsafeRecipient();
error ERC721_InvalidRecipient();
error ERC721_AlreadyMinted();
error ERC721_NotMinted();

contract ERC721 {
    // event
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
    event ApprovalForAll(address owner, address operator, bool approved);

    mapping(address => uint256) internal balances;
    mapping(uint256 => address) internal owners;
    ///@dev address owner => address operator => bool;
    mapping(address => mapping(address => bool)) private operatorApprivalAll;
    ///@dev tokenId => address operator;
    mapping(uint256 => address) private operatorApprival;

    ///@dev return a number nft's of user
    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == address(0)) {
            revert ERC721_AddressIsZero();
        }
        return balances[_owner];
    }

    ///@dev find the owner's of nft;
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = owners[_tokenId];
        if (owner == address(0)) {
            revert ERC721_AddressIsNotExist();
        }
        return owner;
    }

    ///@dev Hàm ủy quyền tất cả các nft cho bên thứ 3 như (opensea, ...)
    function setApprovalForAll(address _operator, bool _approved) external {
        if (_operator == address(0)) {
            revert ERC721_AddressIsZero();
        }
        operatorApprivalAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    ///@dev Hàm kiểm tra xem chủ sở hữu đã ủy quyền nft collection cho bên thứ 3 hay chưa
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view returns (bool) {
        bool approval = operatorApprivalAll[_owner][_operator];
        return approval;
    }

    ///@dev Hàm ủy quyền 1 nft cho bên thứ 3.
    function approve(address _to, uint256 _tokenId) external {
        if (_to == address(0)) {
            revert ERC721_AddressIsZero();
        }
        address owner = ownerOf(_tokenId);
        if (owner != msg.sender || !operatorApprivalAll[owner][msg.sender]) {
            revert ERC721_NotAuthorized();
        }
        operatorApprival[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        if (owners[_tokenId] == address(0)) {
            revert ERC721_TokenIdNotExist();
        }
        return operatorApprival[_tokenId];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        if (_from == address(0) || _to == address(0)) {
            revert ERC721_AddressIsZero();
        }
        address owner = ownerOf((_tokenId));
        if (owner != _from) {
            revert ERC721_WrongFrom();
        }
        if (
            owner != msg.sender ||
            isApprovedForAll(owner, msg.sender) ||
            getApproved(_tokenId) != msg.sender
        ) {
            revert ERC721_NotAuthorized();
        }
        unchecked {
            balances[_from]--;
            balances[_to]++;
        }
        owners[_tokenId] = _to;
        delete operatorApprival[_tokenId];
        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        transferFrom(_from, _to, _tokenId);
        if (
            _to.code.length == 0 ||
            ERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                ""
            ) ==
            ERC721TokenReceiver.onERC721Received.selector
        ) {
            revert ERC721_UnsafeRecipient();
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) public {
        transferFrom(_from, _to, _tokenId);

        if (
            _to.code.length == 0 ||
            ERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            ) ==
            ERC721TokenReceiver.onERC721Received.selector
        ) {
            revert ERC721_UnsafeRecipient();
        }
    }

    function _mint(address _to, uint256 _tokenId) internal virtual {
        if (_to != address(0)) {
            revert ERC721_InvalidRecipient();
        }

        if (owners[_tokenId] == address(0)) {
            revert ERC721_AlreadyMinted();
        }

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balances[_to]++;
        }

        owners[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal virtual {
        address owner = ownerOf(_tokenId);

        unchecked {
            balances[owner]--;
        }

        delete owners[_tokenId];
        delete operatorApprival[_tokenId];

        emit Transfer(owner, address(0), _tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address _to, uint256 _tokenId) internal virtual {
        _mint(_to, _tokenId);

        if (
            _to.code.length == 0 ||
            ERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                address(0),
                _tokenId,
                ""
            ) ==
            ERC721TokenReceiver.onERC721Received.selector
        ) {
            revert ERC721_UnsafeRecipient();
        }
    }

    function _safeMint(
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(_to, _tokenId);

        if (
            _to.code.length == 0 ||
            ERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                address(0),
                _tokenId,
                _data
            ) ==
            ERC721TokenReceiver.onERC721Received.selector
        ) {
            revert ERC721_UnsafeRecipient();
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }
}

abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ERC721Metadata {
    string private name;
    string private symbol;

    ///@dev dùng để lưu token url của từng cái tokenId

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    function getSymbol() external view returns (string memory) {
        return symbol;
    }
}