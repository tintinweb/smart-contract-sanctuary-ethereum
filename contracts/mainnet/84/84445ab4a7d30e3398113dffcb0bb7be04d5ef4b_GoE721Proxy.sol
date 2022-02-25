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
`7MM"""Mq.        A'                                                
  MM   `MM.                                                       
  MM   ,M9     `7Mb,od8      ,pW"Wq.      `7M'   `MF'    `7M'   `MF'
  MMmmdM9        MM' "'     6W'   `Wb       `VA ,V'        VA   ,V  
  MM             MM         8M     M8         XMX           VA ,V   
  MM             MM         YA.   ,A9       ,V' VA.          VVV    
.JMML.         .JMML.        `Ybmd9'      .AM.   .MA.        ,V     
                                                            ,V      
                                                         OOb"      
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

interface IGoE721Basic {
    function exists(uint256) external view returns(bool);
    function ownerOf(uint256) external view returns (address);
}

interface IGoEBridge {
    function formCrossChainGateRequest(uint256, uint256, address, bool) external view returns(bytes memory);
    function createCrossChainGateRequest(bytes memory _nRequest) external returns(bool);
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

contract Proxy is ProxyData, GoEAccess {
    constructor(address _proxied) {

        proxied = _proxied;
    }
    /**
     * @notice proxy implementation of {address contract}
     */
    function implementation() public view returns (address) {

        return proxied;
    }
    /**
     * @notice EIP-897 "Forwarding Proxy" implementation
     */
    function proxyType() public pure returns (uint256) {

        return 1; 
    }

    receive() external payable {

    }
   
    fallback () external payable {
        address addr = proxied;
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
}

contract GoE721Proxy is Proxy, GoE721Data, GoE20Transactions {

    /**
     * @dev creates a new {GoE721Basic} contract with the passed attributes
     */
    constructor (address proxied, address attribProxy_, string memory name_, string memory symbol_, string memory baseUri_, string memory baseExt_, uint256 maxSupply_, uint256 reservedAmount_, uint256 nativeMintCost_, uint256[] memory mintCosts_, address[] memory mintTokens_) Proxy(proxied) {
        _name = name_;
        _symbol = symbol_;
        _baseUrl = baseUri_;
        _baseExtention = baseExt_;
        _maxSupply = maxSupply_;
        _reservedAmount = reservedAmount_;
        _mintCost[address(0)] = nativeMintCost_;
        _mintIdx = 1;
        require(mintTokens_.length == mintCosts_.length, "GoE721Proxy: Tokens and Costs need to be the same length");
        for(uint256 i=0; i<mintTokens_.length; i++){
            _mintCost[mintTokens_[i]] = mintCosts_[i];
        }
        _paused = true;
        _attribProxy = attribProxy_;
    }

    /**
     * @dev upgradable proxy, change the calls to another implementation
     * 
     * Still EIP-897 compliant for forwarding proxy
     */
    function changeProxy(address _proxied) external adminsAllowed {
        proxied = _proxied;
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

    function changeMintCost(address token, uint256 cost) external adminsAllowed {
        _mintCost[token] = cost;
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
            _bridgeMint(_to, _mintIdx);
            _mintIdx += 1;
        }
    }

    function switchToChain(uint256 tokenId, uint256 chainId) external contractsAllowed {
        address oldOwner = IGoE721Basic(proxied).ownerOf(tokenId);
        require(_bridged[tokenId] == block.chainid || _bridged[tokenId] == 0, "GoE721Proxy: This token is already not on this chain");
        require(IGoEBridge(msg.sender).createCrossChainGateRequest(IGoEBridge(msg.sender).formCrossChainGateRequest(chainId, tokenId, oldOwner, true)), "GoE721Proxy: Cannot switch chains currently");
        _bridgeBurn(oldOwner, tokenId);
        _bridged[tokenId] = chainId;
        _bridgeReference[tokenId] = oldOwner;
    }

    function switchFromChain(uint256 tokenId, address tokenOwner) external contractsAllowed {
        require(_bridged[tokenId] != block.chainid, "GoE721Proxy: This token is already on this chain");
        _bridgeMint(tokenOwner, tokenId);
        _bridgeReference[tokenId] = tokenOwner;
        _bridged[tokenId] = block.chainid;
    }

    function _bridgeMint(address to, uint256 tokenId) internal {
        require(!IGoE721Basic(proxied).exists(tokenId), "GoE721Proxy: Bridge minting does not allow tokens that are already minted");
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _bridgeBurn(address from, uint256 tokenId) internal {
        address oldOwner = IGoE721Basic(proxied).ownerOf(tokenId);
        require(oldOwner == from, "GoE721Proxy: Bridge burning does not allow unowned tokens");
        _tokenApprovals[tokenId] = address(0);
        _balances[oldOwner] -= 1;
        delete _owners[tokenId];
        emit Approval(oldOwner, address(0), tokenId);
        emit Transfer(oldOwner, address(0), tokenId);
    }

}