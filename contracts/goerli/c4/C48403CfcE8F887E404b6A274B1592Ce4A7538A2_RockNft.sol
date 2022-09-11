/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
interface ERC721 {
    // Events
    event Transfer(address indexed _from, address indexed _to, uint indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    //Methods
    function balanceOf(address _owner) external view returns (uint);

    function ownerOf(uint _tokenId) external view returns (address);

    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes calldata data) external payable;

    function safeTransferFrom(address _from, address _to, uint _tokenId) external payable;

    function transferFrom(address _from, address _to, uint _tokenId) external payable;

    function approve(address _approved, uint _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract RockNft is ERC721 {

    mapping(uint => address) tokenToOwner;
    mapping(address => uint) ownerToBalance;
    mapping(uint => address) tokenToApproved;
    mapping(address => mapping(address => bool)) ownerToOperators;


    modifier hasPermission(address _caller, uint _tokenId) {
        require(_caller == tokenToOwner[_tokenId]
        || _caller == getApproved(_tokenId)
            || isApprovedForAll(tokenToOwner[_tokenId], _caller));
        _;
    }

    // Minting involves creating new token, i.e transfer of token from address 0 to the address who requested for minting.
    function mint(uint _tokenId) public {
        // To ensure that this token-id is not owned by anyone.
        require(tokenToOwner[_tokenId] == address(0), "this token already belongs to someone else already");
        tokenToOwner[_tokenId] = msg.sender;
        ownerToBalance[msg.sender] += 1;
        emit Transfer(address(0), msg.sender, _tokenId);
    }

    function balanceOf(address _owner) external view returns (uint) {
        require(_owner != address(0), "cannot ask for balance for Address 0");
        return ownerToBalance[_owner];
    }

    function ownerOf(uint _tokenId) external view returns (address) {
        return tokenToOwner[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory data) external payable {
        this.transferFrom(_from, _to, _tokenId);
        require(this.checkOnERC721Received(_from, _to, _tokenId, data));
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId) external payable {
        this.safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint _tokenId) external payable hasPermission(msg.sender, _tokenId) {
        tokenToOwner[_tokenId] = _to;
        ownerToBalance[_from] -= 1;
        //        ownerToBalance[_to] += 1;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint _tokenId) external payable {
        require(msg.sender == tokenToOwner[_tokenId]);
        tokenToApproved[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getApproved(uint _tokenId) public view returns (address) {
        return tokenToApproved[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    function checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) public returns (bool) {
        if (!isContract(to)) {
            return true;
        }
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 ret_val) {
            return ret_val == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory) {
            revert("ERC721: transfer to non ERC721Receiver implementer");
        }
    }

    // https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/extcodesize-checks/
    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}