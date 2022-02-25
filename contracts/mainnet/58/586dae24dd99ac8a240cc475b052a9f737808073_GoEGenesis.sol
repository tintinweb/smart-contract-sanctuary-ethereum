/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

/*
       .d8888b.                       8888888888            
      d88P  Y88b                      888                   
      888    888                      888                   
      888               .d88b.        8888888               
      888  88888       d88""88b       888                   
      888    888       888  888       888                   
      Y88b  d88P       Y88..88P       888                   
       "Y8888P88        "Y88P"        8888888888            
                                                            
                                                            
                                                            
 .d8888b.                                      d8b          
d88P  Y88b                                     Y8P          
888    888                                                  
888         .d88b.  88888b.   .d88b.  .d8888b  888 .d8888b  
888  88888 d8P  Y8b 888 "88b d8P  Y8b 88K      888 88K      
888    888 88888888 888  888 88888888 "Y8888b. 888 "Y8888b. 
Y88b  d88P Y8b.     888  888 Y8b.          X88 888      X88 
 "Y8888P88  "Y8888  888  888  "Y8888   88888P' 888  88888P' 
                                                            
                                                            
                                                            
*/
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

interface IGoEHelper {
    function isContract(address) external view returns (bool);
    function toString(uint256) external pure returns (string memory);
}

interface IGoE20Basic {
    function decimals() external view returns(uint256);
    function transferFrom(address,address,uint256) external returns (bool);    
    function allowance(address,address) external view returns (uint256);
    function transfer(address,uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256); 
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IGoE721Basic is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address ) external view returns (uint256 );
    function ownerOf(uint256 ) external view returns (address );
    function safeTransferFrom(address ,address ,uint256 ) external;
    function transferFrom(address ,address ,uint256 ) external;
    function approve(address , uint256 ) external;
    function getApproved(uint256 ) external view returns (address );
    function setApprovalForAll(address , bool ) external;
    function isApprovedForAll(address , address ) external view returns (bool);
    function safeTransferFrom(address , address ,uint256 , bytes calldata ) external;
    function exists(uint256) external view returns(bool);
}

interface IGoE721Meta is IGoE721Basic {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256) external view returns (string memory);
}

interface IGoEBridge {
    function formCrossChainGateRequest(uint256, uint256, address, bool) external view returns(bytes memory);
    function createCrossChainGateRequest(bytes memory _nRequest) external returns(bool);
}

contract ProxyData {
    // internal mapping for authorized address
    mapping(bytes32 => bool) internal authorized;
     // enum for authorization types
    enum AType {
        KEY,
        ADMIN,
        CONTRACT
    }
    address internal _owner;
}

contract GoEAccess is ProxyData {

    constructor(){

        authorized[_getKec(msg.sender, AType.KEY)] = true;
        _owner = 0xd928775286848A0624342252167c3FFc459bADed;
    }

    function _msgSender() internal view returns (address) {

        return msg.sender;
    }

    function _getKec(address a, AType t) internal pure returns(bytes32){

        return(keccak256(abi.encode(a, t)));
    }

    function _isAuthorized(address _addr) internal view returns(uint8){
        require(_addr != address(0), "GoEAccess: No Zero Addresses allowed");
        if(authorized[_getKec(_addr, AType.KEY)]){
            return 3;
        }
        else if(authorized[_getKec(_addr, AType.ADMIN)]){
            return 2;
        }
        else if(authorized[_getKec(_addr, AType.CONTRACT)]){
            return 1;
        }else{
            return 0;
        }
    }

    function authorizeAddress(AType addressType, address authorizedAddress) public keyAllowed {
        require(_isAuthorized(authorizedAddress) == 0, "GoEAccess: This address is already authorized");
        _authorizeAddress(addressType, authorizedAddress);
    }

    function _authorizeAddress(AType _at, address _a) internal {

        authorized[_getKec(_a, _at)] = true;
    }

    function _unauthorizeAddress(AType _at, address _a) internal {

        authorized[_getKec(_a, _at)] = false;
    }

    modifier keyAllowed() {
        require(_isAuthorized(_msgSender()) == 3, "GoEAccess: Key person only.");
        _;
    }

    modifier adminsAllowed() {
        require(_isAuthorized(_msgSender()) >= 2, "GoEAccess: Only allowed admins have access");
        _;
    }

    modifier contractsAllowed() {
        require(_isAuthorized(_msgSender()) >= 1, "GoEAccess: Only allowed contracts have access");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function changeOwner(address _newOwner) public keyAllowed {
        _owner = _newOwner;
    }

}

contract GoE20Transactions { 
    /**
     * boring ERC20 function to send compliant tokens
     */
    function send20Token(address token, address reciever, uint256 amount) internal returns(bool){
        require(IGoE20Basic(token).balanceOf(address(this)) > amount, "GoE20Transactions: No enough balance");
        require(IGoE20Basic(token).transfer(reciever, amount), "GoE20Transactions: Cannot currently transfer");
        return true;
    }
    /**
     * boring ERC20 function to recieve compliant tokens
     */
    function recieve20Token(address token, address sender, uint256 amount) internal returns(bool) {
        require(IGoE20Basic(token).allowance(sender, address(this)) >= amount, "GoE20Transactions: Need to approve the token");
        require(IGoE20Basic(token).transferFrom(sender, address(this), amount), "GoE20Transactions: Need to transfer tokens ");
        return true;
    }
}

contract GoE721Data {
    /**
     * events required by Non-Fungible tokens implementation
     * more info @ https://eips.ethereum.org/EIPS/eip-721[EIP]
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /**
     * variables used by ERC721 standard contracts with additional params : 
     * 
     * 1. `_attribProxy` parameter which provides onChain data attributes
     * for all Non-Fungible tokens produced by proxy implemented contracts.
     * 
     * 2. `_reservedAmount` a certain pre-specified amount of Non-Fungible tokens
     * for the contract to reserve.
     * 
     * 3. `_paused` a control variable for ERC721 {mint} function.
     */
    address _attribProxy;
    string  _name;
    string  _symbol;
    string  _baseUrl;
    string  _baseExtention;
    uint256  _mintIdx;
    uint256 _maxSupply;
    uint256 _reservedAmount;
    uint256 _nativeMintCost;
    bool _paused;

    /**
     * variables required by Non-Fungible tokens implementation
     * more info @ https://eips.ethereum.org/EIPS/eip-721[EIP]
     * to adhere to functionality requested by the EIP. Main fork from OpenZepplin
     * more info @ https://docs.openzeppelin.com/contracts/2.x/api/token/erc721
     */
    mapping(uint256 => address) _owners;
    mapping(address => uint256) _balances;
    mapping(uint256 => address) _tokenApprovals;
    mapping(address => mapping(address => bool)) _operatorApprovals;

    mapping(uint256 => uint256) _bridged;
    mapping(uint256 => address) _bridgeReference;
}

contract GoEGenesis is GoE721Data, GoE20Transactions, GoEAccess {

     constructor (address attribProxy_, string memory name_, string memory symbol_, string memory baseUri_, string memory baseExt_, uint256 maxSupply_, uint256 reservedAmount_, uint256 nativeMintCost_)  {
        _name = name_;
        _symbol = symbol_;
        _baseUrl = baseUri_;
        _baseExtention = baseExt_;
        _maxSupply = maxSupply_;
        _reservedAmount = reservedAmount_;
        _nativeMintCost = nativeMintCost_;
        _mintIdx = 1;
        _paused = true;
        _attribProxy = attribProxy_;
    }

    /**
     * @dev Less gas consumption if `_mintIdx` starts at 
     * a non-zero value, thus minting starts with tokenId = 1
     */
    function totalSupply() public view returns(uint256){

        return _mintIdx-1;
    }

    function maxSupply() public view returns(uint256) {
        
        return _maxSupply;
    }

    function mintCost() public view returns(uint256) {

        return _nativeMintCost;
    }

    function name() public view returns (string memory) {

        return _name;
    }

    function symbol() public view returns (string memory) {

        return _symbol;
    }

    function paused() public view returns (bool) {

        return _paused;
    }

    function tokenChain(uint256 tokenId) public view returns(uint256) {
        if(_bridged[tokenId] == 0){
            return block.chainid;
        }else{
            return _bridged[tokenId];
        }
    }

    function walletOfOwner(address wallet) public view returns(uint256[] memory walletNFTs){
        uint256 amnt = 0;
        for(uint256 i=1; i<_mintIdx; i++){
            if(ownerOf(i) == wallet){
                amnt += 1;
            }
        }
        walletNFTs = new uint256[](amnt);
        uint256 _idx = 0;
        for(uint256 i=1; i<_mintIdx; i++){
            if(ownerOf(i) == wallet){
                walletNFTs[_idx] = i;
                _idx += 1;
            }
        }
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "GoE721Basic: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        string memory _strId = IGoEHelper(0x53Eb3E1E02C8Eb8d185a074520BD52ECe09F7A43).toString(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI , _strId , _baseExtention)) : "";
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI , "Genesis", _baseExtention));
    }
    
    function mint(address to, address) external payable  {
        require(!_paused, "GoE721Basic: minting is paused");
        require(_mintIdx <= (_maxSupply-_reservedAmount), "GoE721Basic: no more mints");
        require(msg.value >= _nativeMintCost, "GoE721Basic: Min payment of minting cost is required");
        _mint(to, _mintIdx);
        _mintIdx += 1;
    }

    function supportsInterface(bytes4 _interface) public pure returns (bool) {

        return (_interface == type(IGoE721Basic).interfaceId
                || 
                _interface == type(IGoE721Meta).interfaceId);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "GoE721Basic: balance query for the zero address");
        return _balances[owner];
    }
 
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "GoE721Basic: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public{
        address owner = ownerOf(tokenId);
        require(to != owner, "GoE721Basic: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "GoE721Basic: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "GoE721Basic: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "GoE721Basic: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {

        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from,address to,uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "GoE721Basic: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from,address to,uint256 tokenId) public {

        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "GoE721Basic: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _baseURI() public view returns (string memory) {

        return _baseUrl;
    }

    function _safeTransfer(address from,address to,uint256 tokenId,bytes memory) internal  {

        _transfer(from, to, tokenId);
    }

    function exists(uint256 tokenId) external view returns(bool){
        return _exists(tokenId);
    }

    function _exists(uint256 tokenId) internal view  returns (bool) {

        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view  returns (bool) {
        require(_exists(tokenId), "GoE721Basic: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal  {
        // require(to != address(0), "GoE: mint to the zero address");
        // require(!_exists(tokenId), "GoE: token already minted");
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal  {
        address owner = ownerOf(tokenId);
        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from,address to,uint256 tokenId) internal  {
        require(ownerOf(tokenId) == from, "GoE721Basic: transfer of token that is not own");
        require(to != address(0), "GoE721Basic: transfer to the zero address");

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal  {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * onChain attributes contract for all Non-Fungible tokens "minted" by
     * the `_proxied` contract
     */
    function changeAttribProxy(address attribProxy_) external adminsAllowed {
        _attribProxy = attribProxy_;
    }

    function changeURLParams(string memory baseUri_, string memory baseExt_) external adminsAllowed {
        _baseUrl = baseUri_;
        _baseExtention = baseExt_;
    }

    function pauseToggle() external adminsAllowed {
        _paused = !_paused;
    }

    function changeMintCost(uint256 cost) external adminsAllowed {
        _nativeMintCost = cost;
    }

    function withdraw(address token, address to, uint256 amount) external keyAllowed {
        if(token == address(0)){
            require(payable(to).send(amount));
        }else{
            send20Token(token, to, amount);
        }
    }

    function policyMint(address _to, uint256 _amount) external contractsAllowed {
        require(_mintIdx+_amount <= _maxSupply, "GoE721Proxy: Total amounts more than reserved");
        for(uint256 i=0; i<_amount; i++){
            _mint(_to, _mintIdx);
            _mintIdx += 1;
        }
    }

    function switchToChain(uint256 tokenId, uint256 chainId) external contractsAllowed {
        address oldOwner = ownerOf(tokenId);
        require(_bridged[tokenId] == block.chainid || _bridged[tokenId] == 0, "GoE721Proxy: This token is already not on this chain");
        require(IGoEBridge(msg.sender).createCrossChainGateRequest(IGoEBridge(msg.sender).formCrossChainGateRequest(chainId, tokenId, oldOwner, true)), "GoE721Proxy: Cannot switch chains currently");
        _burn(tokenId);
        _bridged[tokenId] = chainId;
        _bridgeReference[tokenId] = oldOwner;
    }

    function switchFromChain(uint256 tokenId, address tokenOwner) external contractsAllowed {
        require(_bridged[tokenId] != block.chainid, "GoE721Proxy: This token is already on this chain");
        require(!_exists(tokenId), "GoE721Proxy: Bridge minting does not allow tokens that are already minted");
        _mint(tokenOwner, tokenId);
        _bridgeReference[tokenId] = tokenOwner;
        _bridged[tokenId] = block.chainid;
    }
   
    fallback () external payable {
        address addr = _attribProxy;
        assembly {
            let freememstart := mload(0x40)
            calldatacopy(freememstart, 0, calldatasize())
            let success := delegatecall(not(0), addr, freememstart, calldatasize(), freememstart, 0)
            returndatacopy(freememstart, 0, returndatasize())
            switch success
            case 0 { revert(freememstart, returndatasize()) }
            default { return(freememstart, returndatasize()) }
        }
    }

    receive() external payable {

    }
}