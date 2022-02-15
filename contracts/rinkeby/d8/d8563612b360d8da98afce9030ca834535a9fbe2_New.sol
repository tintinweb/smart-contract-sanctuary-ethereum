// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;





import "./IVoiceStreetNft.sol" ;
import "./Context.sol" ;
import "./ERC165.sol" ;
import "./IERC721.sol" ;
import "./IERC721Metadata.sol" ;
import "./Ownable.sol" ;
import "./Address.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./IERC721Receiver.sol";
import "./SafeMath.sol";
import "./ISaleContract.sol";



contract New is IVoiceStreetNft, Context, ERC165, IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint256 => TokenMeta) public tokenOnChainMeta;

    uint256 public current_supply = 0;
    uint256 public MAX_SUPPLY = 12000;
    uint256 public current_sold = 0;
    string public baseURI;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint public price;

    uint public buy_limit_per_address = 10;

    uint public sell_begin_time = 0;

    constructor()
    {
        _name = "MetaRim";
        _symbol = "MetaRim";
        setBaseURI("https://www.metarim.io/token/");
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSupplies(uint _current_supply, uint _max_supply) public onlyOwner {
        require(_current_supply <= MAX_SUPPLY, "CAN_NOT_EXCEED_MAX_SUPPLY");
        current_supply = _current_supply;
        MAX_SUPPLY = _max_supply;
    }

    function setNames(string memory name_, string memory symbol_) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
    }

    function totalSupply() public override view returns(uint256) {
        return _tokenIds.current();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address tokenOwner = _owners[tokenId];
        return tokenOwner == address(0) ? owner() : tokenOwner;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId <= current_supply;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId, true);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId, bool emitting) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        if (emitting) {
            emit Transfer(address(0), to, tokenId);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

    function tokenMeta(uint256 _tokenId) public override view returns (TokenMeta memory) {
        return tokenOnChainMeta[_tokenId];
    }

    function mintAndPricing(uint256 _num, uint256 _price, uint256 _limit, uint256 _time) public onlyOwner {
        uint supply = SafeMath.add(current_supply, _num);
        require(supply <= MAX_SUPPLY, "CAN_NOT_EXCEED_MAX_SUPPLY");

        current_supply = supply;
        price = _price;
        buy_limit_per_address = _limit;
        sell_begin_time = _time;
    }

    function setTokenAsset(uint256 _tokenId, string memory _uri, string memory _hash, address _minter) public override onlyOwner {
        require(_exists(_tokenId), "Vsnft_setTokenAsset_notoken");
        TokenMeta storage meta = tokenOnChainMeta[_tokenId];
        meta.uri = _uri;
        meta.hash = _hash;
        meta.minter = _minter;
        tokenOnChainMeta[_tokenId] = meta;
    }

    function setSale(uint256 _tokenId, address _contractAddr, uint256[] memory _settings, address[] memory _addrs) public {
        require(_exists(_tokenId), "Vsnft_setTokenAsset_notoken");
        address sender = _msgSender();
        require(owner() == sender || ownerOf(_tokenId) == sender, "Invalid_Owner");
        
        ISaleContract _contract = ISaleContract(_contractAddr);
        _contract.sale(_tokenId, _settings, _addrs);   
        _transfer(sender, _contractAddr, _tokenId);
    }

    function increaseSoldTimes(uint256 /* _tokenId */) public override {
    }

    function getSoldTimes(uint256 _tokenId) public override view returns(uint256) {
        TokenMeta memory meta = tokenOnChainMeta[_tokenId];
        return meta.soldTimes;
    }

    function buy() public payable {
        uint amount = 1;
        require(block.timestamp >= sell_begin_time, "Purchase_Not_Enabled");
        require(SafeMath.add(balanceOf(msg.sender), amount) <= buy_limit_per_address, "Exceed_Purchase_Limit");
        uint requiredValue = SafeMath.mul(amount, price);
        require(msg.value >= requiredValue, "Not_Enough_Payment");
        require(current_supply >= SafeMath.add(current_sold, amount), "Not_Enough_Stock");

        for (uint i = 0; i < amount; ++i) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId, true);

            TokenMeta memory meta = TokenMeta(
                newItemId, 
                "", 
                "",
                "",
                1,
                owner());

            tokenOnChainMeta[newItemId] = meta;
        }

        current_sold = SafeMath.add(current_sold, amount);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}