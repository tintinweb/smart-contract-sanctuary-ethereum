/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

/*
                                                           
                                                           
      .g8"""bgd                    `7MM"""YMM              
    .dP'     `M                      MM    `7              
    dM'       `       ,pW"Wq.        MM   d                
    MM               6W'   `Wb       MMmmMM                
    MM.    `7MMF'    8M     M8       MM   Y  ,             
    `Mb.     MM      YA.   ,A9       MM     ,M             
      `"bmmmdPY       `Ybmd9'      .JMMmmmmMMM             
                                       __,                 
            M******A'     pd*"*b.     `7MM                 
            Y     A'     (O)   j8       MM                 
                 A'          ,;j9       MM                 
                A'        ,-='          MM                 
               A'        Ammmmmmm     .JMML.               
              A'                          ,,               
`7MM"""Yp,   A'                           db               
  MM    Yb                                                 
  MM    dP      ,6"Yb.      ,pP"Ybd     `7MM       ,p6"bo  
  MM"""bg.     8)   MM      8I   `"       MM      6M'  OO  
  MM    `Y      ,pm9MM      `YMMMa.       MM      8M       
  MM    ,9     8M   MM      L.   I8       MM      YM.    , 
.JMMmmmd9      `Moo9^Yo.    M9mmmP'     .JMML.     YMbmd'  
                                                           
                                                           
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


contract ProxyData {
    // internal address of proxy
    address internal proxied;
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

contract GoE721Data is ProxyData {
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
    bool _paused;

    /**
     * variables required by Non-Fungible tokens implementation
     * more info @ https://eips.ethereum.org/EIPS/eip-721[EIP]
     * to adhere to functionality requested by the EIP. Main fork from OpenZepplin
     * more info @ https://docs.openzeppelin.com/contracts/2.x/api/token/erc721
     */
    mapping(address => uint256) _mintCost;
    mapping(uint256 => address) _owners;
    mapping(address => uint256) _balances;
    mapping(uint256 => address) _tokenApprovals;
    mapping(address => mapping(address => bool)) _operatorApprovals;

    mapping(uint256 => uint256) _bridged;
    mapping(uint256 => address) _bridgeReference;
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


contract GoE721Basic is GoE721Data, GoE20Transactions {

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

        return _mintCost[address(0)];
    }

    function mintCostPerToken(address tokenAddress) public view returns(uint256){
        require(_mintCost[tokenAddress] != 0, "GoE721Basic: This token is not supported");
        return _mintCost[tokenAddress];
    }

    function name() public view returns (string memory) {

        return _name;
    }

    function symbol() public view returns (string memory) {

        return _symbol;
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _strId , _baseExtention)) : "";
    }
    
    function mint(address to, address token) external payable  {
        require(!_paused, "GoE721Basic: minting is paused");
        require(_mintIdx <= (_maxSupply-_reservedAmount), "GoE721Basic: no more mints");
        if(token == address(0)){
            require(msg.value >= _mintCost[token], "GoE721Basic: Min payment of minting cost is required");
        }else{
            require(recieve20Token(token, msg.sender, mintCostPerToken(token)), "GoE721Basic: Cannot confirm payment");
        }
        _mint(to, _mintIdx);
        _mintIdx += 1;
    }

    function supportsInterface(bytes4) public pure returns (bool) {
        // need to check interfaces
        return true;
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