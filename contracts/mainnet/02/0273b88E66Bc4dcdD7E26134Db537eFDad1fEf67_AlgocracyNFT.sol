// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./iAlgocracyNFT.sol";

/// @title Algocracy NFT
/// @author jolan.eth

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator, address from, uint256 tokenId, bytes calldata data
    ) external returns (bytes4);
}

contract AlgocracyNFT {
    uint256 public REGISTRY_IDENTIFIER;
    
    iAlgocracyNFT public DAO;
    iAlgocracyNFT public Provider;

    uint256 supply;
    mapping (uint256 => address) owners;
    mapping (address => uint256) balances;
    
    mapping (uint256 => address) approvals;
    mapping (address => mapping(address => bool)) operatorApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    constructor(
        address _DAO,
        address _Provider,
        uint256 _REGISTRY_IDENTIFIER
    ) {
        DAO = iAlgocracyNFT(_DAO);
        Provider = iAlgocracyNFT(_Provider);
        REGISTRY_IDENTIFIER = _REGISTRY_IDENTIFIER;
    }

    function owner()
    public view returns (address) {
        iAlgocracyNFT CollectionNFT = iAlgocracyNFT(DAO.CollectionNFT());
        return CollectionNFT.ownerOf(REGISTRY_IDENTIFIER);
    }

    function name()
    public view returns (string memory) {
        iAlgocracyNFT CollectionNFT = iAlgocracyNFT(DAO.CollectionNFT());
        return CollectionNFT.getCollectionData(REGISTRY_IDENTIFIER).name;
    }

    function symbol()
    public view returns (string memory) {
        iAlgocracyNFT CollectionNFT = iAlgocracyNFT(DAO.CollectionNFT());
        return CollectionNFT.symbol();
    }

    function maxSupply()
    public view returns (uint256) {
        iAlgocracyNFT CollectionNFT = iAlgocracyNFT(DAO.CollectionNFT());
        return CollectionNFT.getCollectionData(REGISTRY_IDENTIFIER).maxSupply;
    }

    function mintSequentialNFT(address to, uint256 quantity)
    public {
        iAlgocracyNFT CollectionNFT = iAlgocracyNFT(DAO.CollectionNFT());
        
        require(
            CollectionNFT.getCollectionContract(REGISTRY_IDENTIFIER).Prime == msg.sender,
            "AlgocracyNFT::mintNFT() - msg.sender is not the prime contract"
        );

        require(
            supply < maxSupply(),
            "AlgocracyNFT::mintNFT() - supply exceeds maxSupply"
        );

        _mintSequential(to, quantity);
    }

    function mintRandomNFT(address to, uint256[] memory tokenIds)
    public {
        iAlgocracyNFT CollectionNFT = iAlgocracyNFT(DAO.CollectionNFT());
        
        require(
            CollectionNFT.getCollectionContract(REGISTRY_IDENTIFIER).Prime == msg.sender,
            "AlgocracyNFT::mintNFT() - msg.sender is not the prime contract"
        );

        require(
            supply < maxSupply(),
            "AlgocracyNFT::mintNFT() - supply exceeds maxSupply"
        );

        _mintRandom(to, tokenIds);
    }

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function tokenURI(uint256 id)
    public view returns (string memory) {
        require(
            exist(id),
            "AlgocracyNFT::tokenUri() - id do not exist"
        );

        return Provider.generateMetadata(id);
    }

    function exist(uint256 id)
    public view returns (bool) {
        return owners[id] != address(0);
    }

    function totalSupply()
    public view returns (uint256) {
        return supply == 0 ? 0 : supply - 1;
    }

    function balanceOf(address _owner)
    public view returns (uint256) {
        require(
            _owner != address(0),
            "AlgocracyNFT::balanceOf() - _owner is address(0)"
        );

        return balances[_owner];
    }

    function ownerOf(uint256 id)
    public view returns (address) {
        require(
            exist(id),
            "AlgocracyNFT::ownerOf() - id do not exist"
        );

        return owners[id];
    }

    function isApprovedForAll(address _owner, address operator)
    public view returns (bool) {
        return operatorApprovals[_owner][operator];
    }

    function getApproved(uint256 id)
    public view returns (address) {
        require(
            exist(id),
            "AlgocracyNFT::getApproved() - id do not exist"
        );

        return approvals[id];
    }

    function approve(address to, uint256 id)
    public {
        address _owner = owners[id];
        require(
            to != _owner,
            "AlgocracyNFT::approve() - to is _owner"
        );
        require(
            _owner == msg.sender ||
            operatorApprovals[_owner][msg.sender],
            "AlgocracyNFT::approve() - msg.sender is not _owner or approved"
        );

        approvals[id] = to;
        emit Approval(_owner, to, id);
    }

    function setApprovalForAll(address operator, bool approved)
    public {
        require(
            operator != msg.sender,
            "AlgocracyNFT::setApprovalForAll() - msg.sender is operator"
        );

        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id)
    public {
        address _owner = owners[id];
        
        require(
            exist(id),
            "AlgocracyNFT::transferFrom() - id do not exist"
        );

        require(
            msg.sender == _owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[_owner][msg.sender],
            "AlgocracyNFT::transferFrom() - msg.sender is not _owner or approved"
        );

        _transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id)
    public {
        address _owner = owners[id];
        
        require(
            exist(id),
            "AlgocracyNFT::safeTransferFrom() - id do not exist"
        );

        require(
            msg.sender == _owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[_owner][msg.sender],
            "AlgocracyNFT::safeTransferFrom() - msg.sender is not _owner or approved"
        );

        _safeTransfer(from, to, id, '');
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data)
    public {
        address _owner = owners[id];

        require(
            exist(id),
            "AlgocracyNFT::safeTransferFrom() - id do not exist"
        );
        
        require(
            msg.sender == _owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[_owner][msg.sender],
            "AlgocracyNFT::safeTransferFrom() - msg.sender is not _owner or approved"
        );

        _safeTransfer(from, to, id, data);
    }

    function _mintSequential(address to, uint256 quantity)
    private {
        uint256 i = 0;
        if (supply == 0) supply = 1;
        unchecked {
            while (i < quantity) {
                balances[to]++;
                owners[supply] = to;
                emit Transfer(address(this), to, supply++);
                i++;
            }
        }
    }

    function _mintRandom(address to, uint256[] memory tokenIds)
    private {
        uint256 i = 0;
        if (supply == 0) supply = 1;
        unchecked {
            while (i < tokenIds.length) {
                balances[to]++;
                owners[tokenIds[i]] = to;
                emit Transfer(address(this), to, tokenIds[i]);
                supply++;
                i++;
            }
        }
    }

    function _transfer(address from, address to, uint256 id)
    private {
        require(
            address(0) != to,
            "AlgocracyNFT::_transferFrom() - to is address(0)"
        );

        approve(address(0), id);
        balances[from]--;
        balances[to]++;
        owners[id] = to;
        
        emit Transfer(from, to, id);
    }

    function _safeTransfer(address from, address to, uint256 id, bytes memory data)
    private {
        _transfer(from, to, id);
        
        require(
            _checkOnERC721Received(from, to, id, data),
            "AlgocracyNFT::_safeTransfer() - to is not ERC721 receiver"
        );
    }

    function _checkOnERC721Received(address from, address to, uint256 id, bytes memory _data)
    internal returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(to)
        }

        if (size > 0)
            try ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, _data) returns (bytes4 retval) {
                return retval == ERC721TokenReceiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert("error ERC721Receiver");
                else assembly {
                        revert(add(32, reason), mload(reason))
                    }
            }
        else return true;
    }
}