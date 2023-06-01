// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC721TokenReceiver.sol";

interface IERC721 {
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

    function setApprovalForAll(address operator, bool approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

contract ERC721 is IERC721, IERC721TokenReceiver {
    string public name;
    string public symbol;
    uint256 public tokenId;
    address public contractOwner;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        contractOwner = msg.sender;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "ERC721: Invalid Address");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return _owners[_tokenId];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        require(ownerOf(_tokenId) == _from, "ERC721: Not owner");
        require(_to != address(0), "ERC721: Invalid Receiver address");
        delete _tokenApprovals[_tokenId];
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(
            ownerOf(_tokenId) == msg.sender ||
                _tokenApprovals[_tokenId] == msg.sender ||
                _operatorApprovals[ownerOf(_tokenId)][msg.sender],
            "ERC721: You are not allowed"
        );
        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public {
        require(
            ownerOf(_tokenId) == msg.sender ||
                _tokenApprovals[_tokenId] == msg.sender ||
                _operatorApprovals[ownerOf(_tokenId)][msg.sender],
            "ERC721: You are not allowed"
        );
        _transfer(_from, _to, _tokenId);
        require(
            _to.code.length == 0 ||
                IERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    data
                ) ==
                IERC721TokenReceiver.onERC721Received.selector,
            "ERC721:unsafe recipient"
        );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function approve(address _to, uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "ERC721: not owner");
        require(_to!=address(0),"ERC721:invalid spender address");
        _tokenApprovals[_tokenId] = _to;
        emit Approval(ownerOf(_tokenId), _to, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator!=address(0),"ERC721:invalid spender address");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId)
        external
        view
        returns (address operator)
    {
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }

    function mintTo(address _to) public {
        require(contractOwner == msg.sender, "ERC721: Only owner can mint");
        require(_to != address(0), "ERC721Token: zero address cannot be owner");
        // require(
        //     _to.code.length == 0,
        //     "ERC721Token: do not mint in contract address "
        // );
        tokenId++;
        _owners[tokenId] = _to;
        _balances[_to] += 1;
        emit Transfer(address(0), _to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721TokenReceiver
{

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}