/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

contract NFT {
    uint256 private _price = 0.002 ether;
    uint256 private _maxNftsPerTx = 10;
    uint256 private _totalNftSupply = 6160;
    uint256 private _currentIndex = 1;
    string private _nftBaseURI = "ar://bXQ43hxgaenN2FZY9UMtrcvyK3y_cQaJ_IRktmWQ_1Y";
    string private _nftName = "Sudonymous";
    string private _nftSymbol = "SUDO";
    address payable _contractOwner;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _approvals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    event Transfer(address indexed from, address indexed to, uint indexed id);
    event Approval(address indexed owner, address indexed spender, uint indexed id);
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    constructor() {
        _contractOwner = payable(msg.sender);
    }
    function owner() public view returns (address) {
        return _contractOwner;
    }
    function mint(uint256 quantity) public payable {
        address to = msg.sender;
        uint256 currentIndex = _currentIndex;
        require(
            quantity <= _maxNftsPerTx && 
            currentIndex + quantity <= _totalNftSupply && 
            msg.value >= quantity * _price &&
            to == tx.origin && 
            quantity != 0);
        unchecked {
            _balances[to] += quantity;
            for(uint256 i = 0; i < quantity; i++){
                uint256 id = currentIndex + i;
                _owners[id] = to;
                emit Transfer(address(0), to, id);
            }
            _currentIndex = currentIndex + quantity;
            if(msg.value > quantity * _price){
                payable(msg.sender).transfer(msg.value - quantity * _price);
            }
        }
    }
    function collectFee() public {
        _contractOwner.transfer(address(this).balance);
    }
    function totalSupply() public view returns (uint256) {
        return _currentIndex;
    }
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return uint256(_balances[owner]);
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownershipOf(tokenId);
    }
    function name() public view returns (string memory) {
        return _nftName;
    }
    function symbol() public view returns (string memory) {
        return _nftSymbol;
    }
    function tokenByIndex(uint256 index) public pure returns (uint256) {
        return index;
    }
    function baseURI() public view returns (string memory) {
        return _nftBaseURI;
    }
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId));
        return string(abi.encodePacked(_nftBaseURI, "/", _toString(tokenId), ".json"));
    }
    function approve(address to, uint256 tokenId) public {
        address owner = _ownershipOf(tokenId);
        address caller = msg.sender;
        require(to != owner);
        require(caller == owner || isApprovedForAll(owner, caller));
        _approve(to, tokenId, owner);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        return _getApproved(tokenId);
    }
    function setApprovalForAll(address operator, bool approved) public  {
        address caller = msg.sender;
        require(operator != caller);
        _operatorApprovals[caller][operator] = approved;
        emit ApprovalForAll(caller, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        _safeTransferFrom(from, to, tokenId);
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        _safeTransferFrom(from, to, tokenId);
    }
    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        address sender = msg.sender;
        address currentOwner = _ownershipOf(tokenId);
        require(to != address(0));
        require(sender == currentOwner || _getApproved(tokenId) == sender || isApprovedForAll(currentOwner, sender));
        require(currentOwner == from);
        _approve(address(0), tokenId, currentOwner);
        unchecked {
            _balances[from]--;
            _balances[to]++;
            _owners[tokenId] = to;
        }
        emit Transfer(from, to, tokenId);
    }
    function _ownershipOf(uint256 tokenId) internal view returns (address) {
        require(_exists(tokenId));
        return _owners[tokenId];
    }
    function _getApproved(uint256 tokenId) internal view returns (address) {
        require(_exists(tokenId));
        return _approvals[tokenId];
    }
    function _approve(address to, uint256 tokenId, address owner) internal {
        _approvals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId > 0 && tokenId <= _currentIndex;
    }
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            ptr := add(mload(0x40), 128)
            mstore(0x40, ptr)
            let end := ptr
            for { 
                let temp := value
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                temp := div(temp, 10)
            } { 
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            let length := sub(end, ptr)
            ptr := sub(ptr, 32)
            mstore(ptr, length)
        }
    }
}