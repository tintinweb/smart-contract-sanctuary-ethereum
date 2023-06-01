// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721TokenReceiver.sol";
import "./IERC165.sol";

contract ERC721 is IERC721, IERC165 {
    string private _name;
    string private _symbol;
    uint256 public tokenId;
    // _owner => token count
    mapping(address => uint256) private _balances;

    // tokenId => _owner
    mapping(uint256 => address) private _owner;

    // tokenId => address approve
    mapping(uint256 => address) private _tokenApprovals;

    // _owner to operator approval
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 tokenIdStart // string memory baseURI
    ) {
        _name = name;
        _symbol = symbol;
        tokenId = tokenIdStart;
    }

    modifier tokenExist(uint256 id) {
        require(tokenId >= id, "ERC721: token not found");
        _;
    }

    function supportInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    function addressChecker(address checkAddress) private pure {
        require(checkAddress != address(0), "ERC721: Invalid address");
    }

    function mint(address to) external {
        _balances[to]++;
        _owner[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 id) external tokenExist(id) {
        address owners = _owner[id];
        require(
            msg.sender == owners ||
                isApprovedForAll(owners, msg.sender) ||
                msg.sender == getApproved(id),
            "ERC721: not authorized"
        );
        transferFrom(owners, address(0), id);
    }

    function balanceOf(address owners) external view returns (uint256) {
        return _balances[owners];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owners = _owner[_tokenId];
        return owners;
    }

    function setApprovalForAll(address _opeartor, bool _approved) external {
        addressChecker(_opeartor);
        _operatorApprovals[msg.sender][_opeartor] = _approved;
        emit ApprovalForAll(msg.sender, _opeartor, _approved);
    }

    function approve(address _to, uint256 _tokenId) external {
        address owners = _owner[_tokenId];
        require(msg.sender == owners, "ERC721: not authorized");
        require(msg.sender != _to, "ERC721: approve to caller");
        addressChecker(_to);
        _tokenApprovals[_tokenId] = _to;
        emit Approval(owners, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    // function tokenURI(
    //     uint256 id
    // ) external view tokenExist(id) returns (string memory) {}

    function getApproved(
        uint256 _tokenId
    ) public view tokenExist(_tokenId) returns (address) {
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(
        address owners,
        address _opeartor
    ) public view returns (bool) {
        return _operatorApprovals[owners][_opeartor];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(
            msg.sender == _owner[_tokenId] ||
                msg.sender == getApproved(_tokenId) ||
                isApprovedForAll(_owner[_tokenId], msg.sender),
            "ERC721: not authorized"
        );
        _balances[_from]--;
        _balances[_to]++;

        _owner[_tokenId] = _to;
        delete _tokenApprovals[_tokenId];
        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public {
        transferFrom(_from, _to, _tokenId);
        require(
            _to.code.length == 0 ||
                IERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    data
                ) ==
                IERC721TokenReceiver.onERC721Received.selector,
            "ERC721: unsafe recipient"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IERC721TokenReceiver.sol";

contract ERC721TR is IERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getonERC721Bytes() public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function approve(address _to, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC721TokenReceiver {
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
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}