// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC721TokenReceiver.sol";

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

    function approve(address _approved, uint256 _tokenId) external;

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

contract ERC721Token is IERC721TokenReceiver, IERC721 {
    uint256 public nextTokenIDMint;
    address public contractOwner;

    //tokenid => owner
    mapping(uint256 => address) owner;

    //owner =>tokenBalance
    mapping(address => uint256) balance;

    //tokenid => approvedAdress
    mapping(uint256 => address) tokenApprovals;

    //owner =>(operator=> true/false)
    mapping(address => mapping(address => bool)) operatorApproval;

    constructor() {
        nextTokenIDMint = 0;
        contractOwner = msg.sender;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "ERC721Token: invalid address");
        return balance[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return owner[_tokenId];
    }

    function mint(address _to) public {
        require(_to != address(0), "ERC721Token: invalid address");
        owner[nextTokenIDMint] = _to;
        balance[_to] += 1;
        nextTokenIDMint += 1;
        emit Transfer(address(0), _to, nextTokenIDMint);
    }

    function burn(uint256 _tokenId) public {
        require(
            ownerOf(_tokenId) == msg.sender,
            "ERC721Token: You're not the token owner"
        );

        balance[msg.sender] -= 1;
        nextTokenIDMint -= 1;
        emit Transfer(msg.sender, address(0), _tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address, address, uint256, bytes)")
            );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        require(
            ownerOf(_tokenId) == msg.sender ||
                tokenApprovals[_tokenId] == msg.sender ||
                operatorApproval[ownerOf(_tokenId)][msg.sender],
            "ERC721Token: token owner doesn't match"
        );
        transfer(_from, _to, _tokenId);

        require(
            _to.code.length == 0 ||
                IERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    _data
                ) ==
                IERC721TokenReceiver.onERC721Received.selector,
            "ERC721Token: unsafe recepient"
        );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(
            ownerOf(_tokenId) == msg.sender ||
                tokenApprovals[_tokenId] == msg.sender ||
                operatorApproval[ownerOf(_tokenId)][msg.sender],
            "ERC721Token: token owner doesn't match"
        );
        transfer(_from, _to, _tokenId);
    }

    function transfer(address _from, address _to, uint256 _tokenId) internal {
        require(
            ownerOf(_tokenId) == _from,
            "ERC721Token: token owner doesn't match"
        );
        require(_to != address(0), "ERC721Token: unsafe recepient");

        delete tokenApprovals[_tokenId];

        balance[_from] -= 1;
        balance[_to] += 1;
        owner[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "ERC721Token: token owner doesn't match"
        );
        tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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