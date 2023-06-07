/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract NFT {
    string public name;
    string public symbol;
    address public contractOwner;
    uint public nextTokenIdToMint;

    constructor (string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
        contractOwner = msg.sender;
    }

    mapping (uint => address) internal _owners;
    mapping(address => uint ) internal _balances;
    mapping(uint => address) internal _tokenApprovals;
    mapping(uint256 => string) internal _tokenUris;
    mapping(address => mapping(address=>bool) ) internal _operatorApprovals;

    function balanceOf(address _owner) public view returns (uint256)
{
    return _balances[_owner];
}

  function ownerOf(uint256 _tokenId) public view returns (address){
        return _owners[_tokenId];
    }

 function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable{
        require( (msg.sender==ownerOf(_tokenId)) || (_tokenApprovals[_tokenId]==msg.sender)  || _operatorApprovals[ownerOf(_tokenId)][msg.sender]);
        _transfer(_from,_to,_tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, data));
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
        safeTransferFrom(_from,_to,_tokenId,"");
    }

function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
          require( (msg.sender==_from) || (_tokenApprovals[_tokenId]==msg.sender)  || _operatorApprovals[ownerOf(_tokenId)][msg.sender]);
        _transfer(_from,_to,_tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external payable{
        require(ownerOf(_tokenId)==msg.sender,"Caller is not owner of the token!");
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    
    function setApprovalForAll(address _operator, bool _approved) external{
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        // check if to is an contract, if yes, to.code.length will always > 0
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    function _transfer (address _from , address _to ,uint _tokenId) internal {
        require(_owners[_tokenId]==_from);
        _owners[_tokenId] = _to;
        delete _tokenApprovals[_tokenId];
        _balances[_from]--;
        _balances[_to]++;
    }

    function mintTo(address _to, string memory _uri) public {
        _owners[nextTokenIdToMint] = _to;
        _tokenUris[nextTokenIdToMint] = _uri;
        _balances[_to]++;
        emit Transfer(address(0), _to, nextTokenIdToMint);
        nextTokenIdToMint++;
    }

function tokenURI(uint256 _tokenId) public view returns(string memory) {
        return _tokenUris[_tokenId];
    }

    function totalSupply() public view returns(uint256) {
        return nextTokenIdToMint;
    }

}