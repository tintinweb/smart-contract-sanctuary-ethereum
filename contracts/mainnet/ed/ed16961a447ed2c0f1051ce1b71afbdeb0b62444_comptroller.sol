/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// safe

interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// safe

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// safe

interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// safe

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
// safe

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}
// safe oSEA

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}
// safe oSEA

contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        nonces[userAddress]++;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}
// safe oSEA

abstract contract Ownable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// safe

contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
// safe oSEA

contract PATRICIA is IERC721, IERC721Metadata, ERC165, NativeMetaTransaction{
    address proxyRegistryAddress;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    string private _name;
    string private _symbol;
    string private _baseURI;
    bool private isJson = false;

    struct Holder{
        uint128 _balances;
        uint128 _points; 
    }
    struct Token{
        uint32 key;
        uint64 _lastseen;
        address _owners;
    }

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => Holder) private holder;
    mapping(uint256 => Token) private token;

    constructor(string memory name_, string memory symbol_, address _proxyRegistryAddress) {
        _name = name_;
        _symbol = symbol_;
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return holder[owner]._balances;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = token[tokenId]._owners;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(!isJson){
            return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, toString(tokenId))) : "";
        }
        else{
            return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, toString(tokenId), ".json")) : "";
        }
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = PATRICIA.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        virtual
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId), 
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function sweepPoint(uint256 _tokenId) public virtual {
        address owner = PATRICIA.ownerOf(_tokenId);
        unchecked{
            uint128 points = (uint64(block.timestamp) - token[_tokenId]._lastseen) / 10;
            holder[owner]._points += points;
            token[_tokenId]._lastseen = uint64(block.timestamp);
        } 
    }

    function _switchJ() internal virtual {
        isJson = !isJson;
    }

    function _setbaseURI(string memory xyz) internal virtual {
        _baseURI = xyz;
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return token[tokenId]._owners != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = PATRICIA.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        holder[to]._balances++;
        unchecked{
            
            token[tokenId]._owners = to;
            token[tokenId]._lastseen = uint64(block.timestamp);
        }
        

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(PATRICIA.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        sweepPoint(tokenId);

        holder[from]._balances--;
        holder[to]._balances++;
        token[tokenId]._owners = to;


        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(PATRICIA.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}


    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function getToken(uint256 _id) public view returns(Token memory){
        return(token[_id]);
    }
    function getHolder(address account) public view returns (Holder memory) {
        return(holder[account]);
    }
    function _keyI(uint256 _id) internal {
        token[_id].key++;
    }
    function _sweep(address _user) internal {
        holder[_user]._points = 0;
    }
    function _credit(address _user, uint128 _point) internal {
        holder[_user]._points += _point;
    }
}
// safe oSEA-native

contract NFT is PATRICIA, Ownable {
    
    uint256 _nextTokenId;
    uint256 constant public _MAX_TOKEN = 9999;

    constructor() PATRICIA("KONGDO CLUB OFFICIAL", "KDC", 0xa5409ec958C83C3f309868babACA7c86DCB077c1)
    {
        _setbaseURI("https://api.kongdoclub.com/v1/token/");
        _mintTo(msg.sender);
    }

    function _mintTo(address _to) internal {
        //uint256 currentTokenId = _nextTokenId.current();
        //_nextTokenId.increment();
        require(_nextTokenId <= _MAX_TOKEN, "NO MORE");
        _mint(_to, _nextTokenId);
        _nextTokenId++;
    }

    function totalSupply() public view returns (uint256) {
        return(_nextTokenId);
    }

}
// safe

contract comptroller is NFT {

    bool public isOpen = false;
    bool public isU    = false;
    bool public isH = true;

    address public _3D_ADDRESS;
    address public _COIN_ADDRESS;

    uint256 public constant _PRICE = 77   *1e15;
    uint256 public constant _WHITE_PRICE = 55  *1e15;

    uint256 private _threshold = 20 * 1e18;
    address private immutable contributor;
    address private constant contributor2 = 0x0D08CBEF5671b9CB685FC34cd0562C012f8eBC57;
    address private constant Asigner = 0x5050efFf71c7DbEb50173bFbCdF87720905B8e05;

    event unboxEvent(uint256 id, address unboxer, uint256 luckyNumber, string wish);

    constructor(){
        contributor = msg.sender;
    }

    function withdraw() public {
        uint256 _local_threshold = _threshold;

        if(_local_threshold > 0){
            uint256 balance = address(this).balance;
                if(balance >= _local_threshold) {
                    (bool success0,) = contributor.call{value: _local_threshold}("");
                    require(success0, "Transfer failed");
                    _threshold = 0;
                }
                else{
                    (bool success2,) = contributor.call{value: balance}("");
                    require(success2, "Transfer failed");
                    _threshold -= balance;
                }
        }

        uint256 ubalance = address(this).balance;
        uint _amt1 = (ubalance * 750) / 1000;
        uint _amt2 = ubalance - _amt1;

        (bool success,) = contributor.call{value: _amt1}("");
        require(success, "Transfer failed");
        (bool success1,) = contributor2.call{value: _amt2}("");
        require(success1, "Transfer failed");
    }
    
    function regular(uint _amt) external payable {
        require(isOpen, "Closed");
        require(msg.value >= _PRICE*_amt, "Insufficient");
        for(uint i = 0; i < _amt; i++){
            _mintTo(msg.sender);
        }
    }

    function whitelister(uint8 _v, bytes32 _r, bytes32 _s) external payable {
        Holder memory wl = getHolder(msg.sender);
        require(wl._points == 0 && isWhite(_v,_r,_s), "Not whitelist");
        require(msg.value >= _WHITE_PRICE, "insufficient");
        _mintTo(msg.sender);
        _credit(msg.sender, 10000);
    }

    function unbox(uint256 _tokenId, string memory _wish) external {
        Token memory tk = getToken(_tokenId);
        require(isU, "Cannot unbox now");
        require(tk._owners == msg.sender, "Unauthorized");
        require(tk.key == 0, "Already unboxed");
        _keyI(_tokenId);
        emit unboxEvent(_tokenId,msg.sender, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _tokenId, _wish))) % 100000000000000000000000,_wish);
    }

    function redeem() external {
        Holder memory hd = getHolder(msg.sender);
        require( _COIN_ADDRESS != address(0), "Closed");
        uint256 currentP = hd._points;
        _sweep(msg.sender);
        ICOIN(_COIN_ADDRESS).exchange(currentP, msg.sender);
    }

    function get3D(uint256 _tokenId) external {
        Token memory tk = getToken(_tokenId);
        require( _3D_ADDRESS != address(0), "Closed");
        require(tk._owners == msg.sender, "Unauthorize Access");
        require(tk.key == 1, "Unopen or already used");
        _keyI(_tokenId);
        I3D(_3D_ADDRESS).exchange3(_tokenId, msg.sender);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(isH){
            return "https://api.kondoclub.com/hidden.json";
        }
        return PATRICIA.tokenURI(tokenId);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        uint256 maxSupply = totalSupply();

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    } // Hashlips/hashlips_nft_contract/contract/SimpleNftLowerGas.sol >> Line 66

    function isWhite(uint8 _v, bytes32 _r, bytes32 _s) internal view returns (bool)
    {
        return ecrecover(ethSigned(), _v, _r, _s) == Asigner;
    }
    function ethSigned() internal view returns(bytes32){
        return(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32", 
                        keccak256(
                            abi.encodePacked(msg.sender)
                        )
                    )
                )
            );
    }

    function aUnbox(uint256 _tokenId, string memory _wish) external onlyOwner {
        Token memory tk = getToken(_tokenId);
        require(tk.key == 0, "Already unboxed");
        _keyI(_tokenId);
        emit unboxEvent(_tokenId,msg.sender, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _tokenId, _wish))) % 100000000000000000000000,_wish);
    }
    function aCredit(address _a, uint _p) external onlyOwner {
        _credit(_a, uint128(_p));
    }
    function setCoin(address _xyz) external onlyOwner{
        _COIN_ADDRESS = _xyz;
    }
    function set3D(address _xyz) external onlyOwner{
        _3D_ADDRESS = _xyz;
    }
    function airdrop(address[] memory _target) external onlyOwner {
        for(uint i = 0; i < _target.length; i++){
            _mintTo(_target[i]);
        }
    }
    function xCUR(address _curate, uint _amt) external onlyOwner {
        for(uint i = 0; i < _amt; i++){
            _mintTo(_curate);
        }
    }
    function switchO() external onlyOwner {
        isOpen = !isOpen;
    }
    function switchU() external onlyOwner {
        isU = !isU;
    }
    function switchH() external onlyOwner {
        isH = !isH;
    }
    function setbaseURI(string memory abc) external onlyOwner {
        _setbaseURI(abc);
    }
}

interface ICOIN {
    function exchange(uint256 _points, address _target) external;
}
interface I3D {
    function exchange3(uint256 _tokenId, address _target) external;
}