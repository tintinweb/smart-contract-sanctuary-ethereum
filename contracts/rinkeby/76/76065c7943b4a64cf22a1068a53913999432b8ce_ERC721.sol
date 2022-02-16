/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract ERC721{
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _owners;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;

    function balanceOf(address _owner) external view returns (uint256){
        require(_owner != address(0), "Address is zero");
		return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address){
        address owner = _owners[_tokenId];
		require(owner != address(0), "TokenId does not exist");
		return owner;
    }

    function setApprovalForAll(address _operator, bool _approved) external {
		_operatorApprovals[msg.sender][_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	function isApprovedForAll(address _owner, address operator) public view returns(bool) {
		return  _operatorApprovals[_owner][operator];
    }

    function approve(address to, uint256 tokenId) public {
		address owner = ownerOf(tokenId);
		require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Msg.sender is not the curent owner or operator");

		_tokenApprovals[tokenId] = to;
		emit Approval(owner, to, tokenId);
	}

	function getApproved(uint256 tokenId) public view returns(address){
		require(_owners[tokenId] != address(0), "Token ID does not exist");
		return _tokenApprovals[tokenId];
	}

    function transferFrom(address from, address to, uint256 tokenId) public {
		address owner = ownerOf(tokenId);
		require(msg.sender == owner || getApproved(tokenId) == msg.sender || isApprovedForAll(owner, msg.sender), "msg.sender is not owner or approved for transfer");
		require(owner == from, "From address is not the owner");
		require(to == address(0), "to address cannot be zero address");
		require(_owners[tokenId] != address(0), "TokenId Does not exist");

		approve(address(0), tokenId);
	
		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenId] = to;
	
		emit Transfer(from, to, tokenId);
	}
	
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
		transferFrom(from, to, tokenId);
		require(_checkOnERC721Recieved(), "Reciever not implemented");
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) external payable {
		safeTransferFrom(from, to, tokenId, "");
	}
	
	function _checkOnERC721Recieved() private pure returns(bool) {
			return true;
	}

    function supportsInterface(bytes4 interfaceId) public pure virtual returns(bool) {
		return interfaceId == 0x80ac58cd;
    }
}