// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract FakeSuperSneak  {
    


    address internal owner;

    constructor () {
        owner = msg.sender;

        emit Transfer(address(0), msg.sender, 1);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == owner) {
            return 1;
        }
        else {
            return 0;
        }
    }

  
    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(_tokenId == 1, "Non-existing token");

        return owner;
    }

   function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        require(_tokenId == 1, "Non-existing token");

        owner = _to;

        emit Transfer(_from, _to, 1);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable {
        safeTransferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        safeTransferFrom(_from, _to, _tokenId);
    }


    function approve(address _approved, uint256 _tokenId) external payable {
        require(_tokenId == 1, "Non-existing token");
    }

    
    function setApprovalForAll(address _operator, bool _approved) external { }

    
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_tokenId == 1, "Non-existing token");
        return owner;
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return false;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return true;
    }
    
    function name() external view returns (string memory _name) {
        return "Fake Super Sneak";
    }

    function symbol() external view returns (string memory _symbol) {
        return "FSS";
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(_tokenId == 1, "Non-existing token");
        return "ipfs://QmcEfAcsyVNRNfy9Buc3zz4aDNXP7NWshvc67XH6KmeK3i/1";
    }
}