pragma solidity ^0.4.19;

contract ERC721 {
   // ERC20 compatible functions
   function name() public view returns (string _name);
   function symbol() public view returns (string _symbol);
   function totalSupply() public view returns (uint256 _totalSupply);
   function balanceOf(address _owner) public view returns (uint _balance);
   // Functions that define ownership
   function ownerOf(uint256) public view returns (address owner);
   function approve(address, uint256) public returns (bool);
   function takeOwnership(uint256) public returns (bool);
   function transfer(address, uint256) public returns (bool);
   function setApprovalForAll(address _operator, bool _approved) public returns (bool);
   function getApproved(uint256 _tokenId) public view returns (address);
   function isApprovedForAll(address _owner, address _operator) public view returns (bool);
   // Token metadata
   function tokenMetadata(uint256 _tokenId) public view returns (string info);
   // Events
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
   event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

/* taking ideas from FirstBlood token */
contract RpSafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      require((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
      require(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x * y;
      require((x == 0)||(z/x == y));
      return z;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) { 
          return a;
        } else { 
          return b; 
        }
    }
    
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) { 
          return a;
        } else { 
          return b; 
        }
    }
}



contract TestERC721 is RpSafeMath, ERC721 {
    NFT[] public nfts;
    struct NFT{
        bytes32 name;
        uint nftId;
    }

    mapping (uint => uint) nftIdToIndex;

    mapping (uint => address) nftToOwner;
    mapping (uint => address) nftIdToApproved;
    mapping (address => uint) ownerNftCount;

    function totalSupply() public view returns (uint256){ return nfts.length; }
    function balanceOf(address _owner) public view returns (uint) { return ownerNftCount[_owner]; }
    function ownerOf(uint _nftId) public view returns (address) { return nftToOwner[_nftId]; }
    function name() public view returns (string){ return "test_erc721"; }
    function symbol() public view returns (string){ return "TEST"; }
    function getApproved(uint _nftId) public view returns (address) { return nftIdToApproved[_nftId]; }
    function tokenMetadata(uint256) public view returns (string) { return ""; }

    function setApprovalForAll(address, bool) public returns (bool) { return false; }
    function isApprovedForAll(address, address) public view returns (bool) { return false; }

    function getNftsByOwner(address _owner) external view returns(uint[]) {
        uint[] memory result = new uint[](ownerNftCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < nfts.length; i++) {
            if (nftToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function addNtf(bytes32 _name, uint _nftId, address _owner) public {
        require(nftToOwner[_nftId] == 0x0);
        require(_owner != 0x0);

        nftIdToIndex[_nftId] = nfts.push(NFT(_name, _nftId)) - 1;
        ownerNftCount[_owner] = safeAdd(ownerNftCount[_owner], 1);
        nftToOwner[_nftId] = _owner;
    }

    function _transfer(address _from, address _to, uint _nftId) private returns(bool) {
        ownerNftCount[_from ] = safeSubtract(ownerNftCount[_from], 1);
        ownerNftCount[_to] = safeAdd(ownerNftCount[_to], 1);
        nftToOwner[_nftId] = _to;

        emit Transfer(msg.sender, _to, _nftId);

        return true;
    }

    function transfer(address _to, uint _nftId) public  returns(bool) {
        require(nftToOwner[_nftId] != 0x0);
        require(msg.sender == nftToOwner[_nftId]);
        require(msg.sender != _to);
        require(_to != address(0));

        _transfer(msg.sender, _to, _nftId);

        return true;
    }

    function approve(address _to, uint _nftId) public returns(bool) {
        require(msg.sender == nftToOwner[_nftId]);
        require(msg.sender != _to);

        nftIdToApproved[_nftId] = _to;

        emit Approval(msg.sender, _to, _nftId);

        return true;
    }

    function takeOwnership(uint _nftId) public returns(bool) {
        require(nftToOwner[_nftId] != 0x0);
        address oldOwner = nftToOwner[_nftId];

        require(nftIdToApproved[_nftId] == msg.sender);

        delete nftIdToApproved[_nftId];

        _transfer(oldOwner, msg.sender, _nftId);

        return true;
    }
}