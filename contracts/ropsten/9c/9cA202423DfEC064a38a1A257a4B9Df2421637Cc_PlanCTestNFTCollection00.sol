/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library AddressGasOptimized {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using AddressGasOptimized for address;
    using Strings for uint256;
    
    string private _name;
    string private _symbol;

    address[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) 
        public 
        view 
        virtual 
        override 
        returns (uint) 
    {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint count;
        for( uint i; i < _owners.length; ++i ){
          if( owner == _owners[i] )
            ++count;
        }
        return count;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);
        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

library MerkleProof {

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract PlanCTestNFTCollection00 is ERC721, Ownable, ReentrancyGuard {

    bool public IS_PUBLIC_SALE_ACTIVE = false;

    uint256 public constant FREE_MINT_MAPPING_ID = 0;
    uint256 public constant PRESALE_MAPPING_ID = 1;
    uint256 public constant PUBLIC_MAPPING_ID = 2;

    uint256 public constant MAX_PER_FREE_MINT = 1; 
    uint256 public MAX_PER_PS_SPOT = 2;
    uint256 public MAX_PER_PUBLIC_MINT = 5;
    uint256 public PRESALE_MINT_PRICE = 0.05 ether;
    uint256 public PUBLIC_MINT_PRICE = 0.08 ether;
    uint256 public MAX_SUPPLY = 1000;
    uint256 public PHASE_ID = 1;

    bytes32 public presaleMerkleRoot;
    bytes32 public freeMintMerkleRoot;

    string public baseURI;

    mapping(uint => mapping(uint => mapping(address => uint))) public phaseToMappingIdToSupplyMap;

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier hasAvailableSupply(uint256 potentialNewBalance, uint256 limit) {
        require(potentialNewBalance <= limit, 
            "Exceeds allocated supply for this user via attempted mint function.");
        _;
    }

    modifier isValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
        require(_verify(msg.sender, root, proof), "Sender not in MerkleTree");
        _;
    }

    constructor(string memory _baseURI) ERC721("PlanCTest00", "PC00") {
        baseURI = _baseURI;
        address purgatory = 0x0000000000000000000000000000000000000000;
        _owners.push(purgatory);
    }

    /******** Read-only Functions *********/

    function totalSupply() external view virtual returns (uint256) {
        return _owners.length - 1;
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function getMintProgress(address userWallet, bytes32[] calldata freeMintProof, bytes32[] calldata presaleProof) 
        external 
        view 
        returns (uint, uint, uint, uint, uint) 
    {
        uint totalMinted = _owners.length - 1;
        uint freeMintsRemaining = 0;
        uint psMintsRemaining = 0;
        uint publicMintsRemaining = MAX_PER_PUBLIC_MINT 
            - phaseToMappingIdToSupplyMap[PHASE_ID][PUBLIC_MAPPING_ID][userWallet];

        if (_verify(userWallet, freeMintMerkleRoot, freeMintProof)) {
            freeMintsRemaining += (MAX_PER_FREE_MINT 
                - phaseToMappingIdToSupplyMap[PHASE_ID][FREE_MINT_MAPPING_ID][userWallet]);
        }
        if (_verify(userWallet, presaleMerkleRoot, presaleProof)) { 
            psMintsRemaining += (MAX_PER_PS_SPOT 
                - phaseToMappingIdToSupplyMap[PHASE_ID][PRESALE_MAPPING_ID][userWallet]);
        }

        return (
            freeMintsRemaining, 
            psMintsRemaining, 
            publicMintsRemaining, 
            totalMinted, 
            MAX_SUPPLY - totalMinted
        );
    }


    /******** Minting Functions *********/

    function omegaMint(bytes32[] calldata freeMintProof, bytes32[] calldata presaleProof) 
        external 
        payable
        isCorrectPayment(PRESALE_MINT_PRICE, MAX_PER_PS_SPOT)
        hasAvailableSupply(
            phaseToMappingIdToSupplyMap[PHASE_ID][FREE_MINT_MAPPING_ID][msg.sender] + MAX_PER_FREE_MINT, 
            MAX_PER_FREE_MINT)
        hasAvailableSupply(
            phaseToMappingIdToSupplyMap[PHASE_ID][PRESALE_MAPPING_ID][msg.sender] + MAX_PER_PS_SPOT, 
            MAX_PER_PS_SPOT)
        isValidMerkleProof(presaleMerkleRoot, presaleProof)
        isValidMerkleProof(freeMintMerkleRoot, freeMintProof)
        nonReentrant
    {
        uint256 totalSupplySaveFunctionGas = _owners.length - 1;
        require(
            totalSupplySaveFunctionGas + MAX_PER_PS_SPOT + MAX_PER_FREE_MINT <= MAX_SUPPLY, 
            "Exceeds max supply, collection is sold out!"
        );

        phaseToMappingIdToSupplyMap[PHASE_ID][FREE_MINT_MAPPING_ID][msg.sender] += MAX_PER_FREE_MINT;
        phaseToMappingIdToSupplyMap[PHASE_ID][PRESALE_MAPPING_ID][msg.sender] += MAX_PER_PS_SPOT;

        for(uint i; i < MAX_PER_FREE_MINT + MAX_PER_PS_SPOT; i++) {
            _mint(msg.sender, totalSupplySaveFunctionGas + i + 1);
        }
    }

    function claimFreeMint(bytes32[] calldata proof) 
        external 
        hasAvailableSupply(
            phaseToMappingIdToSupplyMap[PHASE_ID][FREE_MINT_MAPPING_ID][msg.sender] + 1,
            MAX_PER_FREE_MINT)
        isValidMerkleProof(freeMintMerkleRoot, proof)
        nonReentrant
    {
        uint256 totalSupplySaveFunctionGas = _owners.length - 1;
        require(
            totalSupplySaveFunctionGas + 1 <= MAX_SUPPLY, 
            "Exceeds max supply, should've claimed sooner :/"
        );

        phaseToMappingIdToSupplyMap[PHASE_ID][FREE_MINT_MAPPING_ID][msg.sender] += 1;
        _mint(msg.sender, totalSupplySaveFunctionGas + 1);
    }
    
    function presaleMint(uint256 amount, bytes32[] calldata proof) 
        external 
        payable 
        isCorrectPayment(PRESALE_MINT_PRICE, amount)
        hasAvailableSupply(
            phaseToMappingIdToSupplyMap[PHASE_ID][PRESALE_MAPPING_ID][msg.sender] + amount, 
            MAX_PER_PS_SPOT)
        isValidMerkleProof(presaleMerkleRoot, proof)
        nonReentrant
    {
        uint256 totalSupplySaveFunctionGas = _owners.length - 1;
        require(totalSupplySaveFunctionGas + amount <= MAX_SUPPLY, "Exceeds Max supply, Pixl Pets are sold out!");
        
        phaseToMappingIdToSupplyMap[PHASE_ID][PRESALE_MAPPING_ID][msg.sender] += amount;
        for(uint i; i < amount; i++) {
            _mint(msg.sender, totalSupplySaveFunctionGas + i + 1);
        }
    }
    
    function publicMint(uint256 amount) 
        external 
        payable
        isCorrectPayment(PUBLIC_MINT_PRICE, amount)
        hasAvailableSupply(
            phaseToMappingIdToSupplyMap[PHASE_ID][PUBLIC_MAPPING_ID][msg.sender] + amount, 
            MAX_PER_PUBLIC_MINT)
        nonReentrant
    {
        uint256 totalSupplySaveFunctionGas = _owners.length - 1;
        require(IS_PUBLIC_SALE_ACTIVE, 'Public sale is inactive! pls stop');
        require(totalSupplySaveFunctionGas + amount <= MAX_SUPPLY, "Exceeds max supply, Pixl Pets are sold out!");

        phaseToMappingIdToSupplyMap[PHASE_ID][PUBLIC_MAPPING_ID][msg.sender] += amount;
        for(uint i; i < amount; i++) { 
            _mint(msg.sender, totalSupplySaveFunctionGas + i + 1);
        }
    }

    function burn(uint256 tokenId) external { 
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    /*********** ADMIN FUNCTIONS ************/

    function adminMint(uint256 amount, address _to) 
        external
        onlyOwner
    {
        uint256 totalSupplySaveFunctionGas = _owners.length - 1;
        require(totalSupplySaveFunctionGas + amount <= MAX_SUPPLY, "Exceeds max supply.");
    
        for(uint i; i < amount; i++) { 
            _mint(_to, totalSupplySaveFunctionGas + i + 1);
        }
    }

    function setPresaleMerkleRoot(bytes32 _presaleMerkleRoot) external onlyOwner {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    function setFreeMintMerkleRoot(bytes32 _freeMintMerkleRoot) external onlyOwner {
        freeMintMerkleRoot = _freeMintMerkleRoot;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function updateMaxSupply(uint256 _MAX_SUPPLY) external onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function toggleIsPublicSaleActive() external onlyOwner {
        IS_PUBLIC_SALE_ACTIVE = !IS_PUBLIC_SALE_ACTIVE;
    }

    function updateMaxPresaleSupply(uint256 _MAX_PER_PS_SPOT) external onlyOwner {
        MAX_PER_PS_SPOT = _MAX_PER_PS_SPOT;
    }

    function updateMaxPublicSupply(uint256 _MAX_PER_PUBLIC_MINT) external onlyOwner {
        MAX_PER_PUBLIC_MINT = _MAX_PER_PUBLIC_MINT;
    }

    function updatePresaleMintPrice(uint256 _PRESALE_MINT_PRICE) external onlyOwner {
        PRESALE_MINT_PRICE = _PRESALE_MINT_PRICE;
    }

    function updatePublicMintPrice(uint256 _PUBLIC_MINT_PRICE) external onlyOwner {
        PUBLIC_MINT_PRICE = _PUBLIC_MINT_PRICE;
    }

    function incrementPhaseVersion()
        external
        onlyOwner
    {
        PHASE_ID += 1;
    }

    function decrementPhaseVersion()
        external
        onlyOwner
    {
        PHASE_ID -= 1;
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) 
        external 
        onlyOwner
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = (msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to send ETH.");
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
    
    function _verify(
        address _buyerAddress, 
        bytes32 _merkleRoot, 
        bytes32[] memory _proof) internal pure returns (bool) {
        return _merkleRoot != 0 
            && MerkleProof.verify(_proof, _merkleRoot, keccak256(abi.encodePacked(_buyerAddress)));
    }

}