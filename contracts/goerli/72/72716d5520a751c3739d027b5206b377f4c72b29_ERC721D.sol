// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./DCall.sol";

contract ERC721D is ERC721, DCall { }

pragma solidity ^0.8.17;

// Basic ERC721 contract that supports minting a specific token ID.
contract ERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public constant name = 'TestERC721';
    string public constant symbol = 'TST721';
    string public constant tokenURI = '';

    mapping (uint256 => address) private _ownerOf;
    mapping (address => uint256) public balanceOf;
    mapping (uint256 => address) public getApproved;
    mapping (address => mapping (address => bool)) public isApprovedForAll;

    function _callReceiverHook(address owner, address to, uint256 tokenId, bytes memory data)
        private
    {
        bool isContract;
        assembly { isContract := eq(iszero(extcodesize(to)), 0) }
        if (isContract) {
            require(
                IERC721Receiver(to).onERC721Received(msg.sender, owner, tokenId, data)
                    == IERC721Receiver.onERC721Received.selector,
                'failed to receive NFT'
            );
        }
    }

    function safeMint(uint256 tokenId, address owner) public {
        require(owner != address(0), 'invalid owner');
        require(_ownerOf[tokenId] == address(0), 'already minted');
        _ownerOf[tokenId] = owner;
        ++balanceOf[owner];
        _callReceiverHook(address(0), owner, tokenId, "");
        emit Transfer(address(0), owner, tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        owner = _ownerOf[tokenId];
        require(owner != address(0), 'invalid token');
    }

    function transferFrom(address owner, address to, uint256 tokenId) public {
        require(to != address(0), 'invalid recipient');
        if (msg.sender != owner) {
            require(getApproved[tokenId] == msg.sender ||
                    isApprovedForAll[owner][msg.sender],
                'not approved'
            );
        }
        require(_ownerOf[tokenId] == owner, 'wrong owner');
        --balanceOf[owner];
        ++balanceOf[to];
        _ownerOf[tokenId] = to;
        getApproved[tokenId] = address(0);
        emit Transfer(owner, to, tokenId);
    }

    function safeTransferFrom(address owner, address to, uint256 tokenId) external {
        safeTransferFrom(owner, to, tokenId, "");
    }

    function safeTransferFrom(address owner, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(owner, to, tokenId);
        _callReceiverHook(owner, to, tokenId, data);
    }

    function approve(address spender, uint256 tokenId) public {
        require(_ownerOf[tokenId] == msg.sender, 'not owner');
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId);
    }

    function setApprovalForAll(address spender, bool approved) public {
        isApprovedForAll[msg.sender][spender] = approved;
        emit ApprovalForAll(msg.sender, spender, approved);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x780e9d63;
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DCall {
    function dcall(bytes[] memory deployments, bytes[] memory callDatas) external {
        for (uint256 i = 0; i < deployments.length; ++i) {
            bytes memory deployCode = deployments[i];
            address target;
            assembly {
                target := create(0, add(deployCode, 0x20), mload(deployCode))
            }
            require(target != address(0), 'deployment failed');
            (bool b, bytes memory r) = target.delegatecall(callDatas[i]);
            if (!b) {
                assembly { revert(add(r, 0x20), mload(r)) }
            }
        }
    }
}