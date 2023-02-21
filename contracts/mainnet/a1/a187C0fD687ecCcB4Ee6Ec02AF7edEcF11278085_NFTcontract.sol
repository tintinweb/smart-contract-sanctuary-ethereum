// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "IOperatorFilterRegistry.sol";
import "ERC721Enumerable.sol";
import "ReentrancyGuard.sol";

contract NFTcontract is ERC721Enumerable, ReentrancyGuard {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    mapping(uint256 => uint256) private stageTime;

    uint256 public maxPublicMint;
    uint256 private transferOwnerTime;
    uint256 private updateValidTime;
    string private validKey;
    string public baseURI;
    bool private updateBaseURIStatus;
    bool public putCap;
    address public collectAddress;
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenMinted(uint256 indexed firstId, uint256 mintQty, address indexed contractAddress, address indexed minter);

    error OperatorNotAllowed(address operator);
    error CallNotAllowed(uint256 times);
    error MintNotAvailable();
    error InputInvalidData();
    error TransferETHFailed();
    error InvalidKey();
    error Unauthorized(address caller);
    error NotExistedToken(uint256 tokenid);

    constructor(
        address _collectAddress,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxPublicMint
    ) ERC721(_tokenName, _tokenSymbol) {
        OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), DEFAULT_SUBSCRIPTION);
        maxPublicMint = _maxPublicMint;
        collectAddress = _collectAddress;
        _transferOwnership(_collectAddress);
        baseURI = "https://montage.infura-ipfs.io/ipfs/QmPaYH7MVVoUGHzF8yK1Gp6isBqqZprMUoEjpEQXvn6Xk8";
    }

    modifier isCorrectPayment(string calldata _valid, uint256 _stage) {
        if (keccak256(abi.encodePacked(_valid)) != keccak256(abi.encodePacked(validKey))) {
            revert InvalidKey();
        }
        uint256 currTime = block.timestamp;
        if (_stage == 1) {
            if (stageTime[_stage] > currTime) {
                revert MintNotAvailable();
            }
        }
        if (_stage == 0) {
            if (stageTime[_stage] > currTime) {
                revert MintNotAvailable();
            }
        }
        _;
    }

    modifier canMint(uint256 numberOfTokens, uint256 tokenId) {
        _canMint(numberOfTokens, tokenId);
        _;
    }

    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    modifier onlyOwner() {
		_checkOwner();
		_;
    }

    function _checkOwner() internal view virtual {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
    }

    function _canMint(uint256 _numberOfTokens, uint256 _tokenId) internal view virtual {
        uint256 temp = totalSupply() + _numberOfTokens + 1;
        uint256 maxId = maxPublicMint + 1;
        if (temp > maxId) {
            revert MintNotAvailable();
        }
        if (_tokenId > maxPublicMint) {
            revert MintNotAvailable();
        }
    }

    function _checkFilterOperator(address operator) internal view virtual {
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721, ERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function updateOperatorsFilter(address[] calldata _operators, bool[] calldata _allowed) external onlyOwner {
        uint256 lengthAllowed = _allowed.length;
        if (_operators.length != lengthAllowed) {
            revert InputInvalidData();
        }

        for (uint256 i; i < lengthAllowed; i++) {
            if (_allowed[i] == OPERATOR_FILTER_REGISTRY.isOperatorFiltered(address(this), _operators[i])) {
                OPERATOR_FILTER_REGISTRY.updateOperator(address(this), _operators[i], !_allowed[i]);
            }
        }
    }
    
    // ============ PUBLIC MINT FUNCTION FOR NORMAL USERS ============
    function mintWithQTY(string calldata _valid, uint256 _numberOfTokens, uint256 _stage)
        public
        payable
        isCorrectPayment(_valid, _stage)
        canMint(_numberOfTokens, 0)
        nonReentrant
    {
        uint256 temp = totalSupply() + 1;
        uint256 firstId = temp;
        for (uint256 i; i < _numberOfTokens; i++) {
            _mint(msg.sender, temp);
            temp++;
        }
        _transfer(collectAddress, msg.value);
        emit TokenMinted(firstId, _numberOfTokens, address(this), msg.sender);
    }

    // ============ PUBLIC MINT FUNCTION FOR NORMAL USERS ============
    function mintWithID(string calldata _valid, uint256 _tokenId, uint256 _stage)
        public
        payable
        isCorrectPayment(_valid, _stage)
        canMint(1, _tokenId)
        nonReentrant
    {
        uint256 firstId = _tokenId;
        _mint(msg.sender, firstId);
        _transfer(collectAddress, msg.value);
        emit TokenMinted(firstId, 1, address(this), msg.sender);
    }

    // ============ MINT FUNCTION FOR ONLY OWNER ============
    function selfMint(uint256 _numberOfTokens)
        public
        canMint(_numberOfTokens, 0)
        nonReentrant
        onlyOwner
    {
        uint256 temp = totalSupply() + 1;
        uint256 firstId = temp;
        for (uint256 i; i < _numberOfTokens; i++) {
            _mint(msg.sender, temp);
            temp++;
        }
        emit TokenMinted(firstId, _numberOfTokens, address(this), msg.sender);
    }

    // ============ FUNTION TO READ TOKENRUI ============
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (_exists(_tokenId) == false) {
            revert NotExistedToken(_tokenId);
        }
        if (updateBaseURIStatus == false) {
            return string(abi.encodePacked(baseURI));
        }
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    // ============ FUNCTION TO UPDATE ETH COLLECTADDRESS ============
    function setCollectAddress(address _collectAddress) external onlyOwner {
        collectAddress = _collectAddress;
    }

    // ============ FUNCTION TO UPDATE BASEURIS ============
    function updateBaseURI(string calldata _baseURI) external onlyOwner {
        if (putCap == true) {
            revert InputInvalidData();
        }
        updateBaseURIStatus = true;
        baseURI = _baseURI;
    }

    // ============ FUNCTION TO UPDATE STAGE SCHEDULED TIME ============
    function updateScheduledTime(uint256[] calldata _stageTimes)
        external
        onlyOwner
    {
        uint256 lengthStages = _stageTimes.length;
        if (lengthStages > 2) {
            revert InputInvalidData();
        }
        for (uint256 i; i < lengthStages; i++) {
            stageTime[i] = _stageTimes[i];
        }
    }

    // ============ FUNCTION TO TRIGGER TO CAP THE SUPPLY ============
    function capTrigger(bool _putCap) external onlyOwner {
        putCap = _putCap;
    }

    //============ FUNCTION TO UPDATE VALID KEY ============
    function updateValidation(string calldata _valid) external onlyOwner {
        uint256 updateTime = updateValidTime;
        if (updateTime != 0) {
            revert CallNotAllowed(updateTime);
        }
        validKey = _valid;
        updateValidTime = 1;
    }

    //============ FUNCTION TO TRANSFER OWNERSHIP ============
    function transferOwnership(address _newOwner) external onlyOwner {
        uint256 transferTime = transferOwnerTime;
        if (transferTime != 0) {
            revert CallNotAllowed(transferTime);
        }
        _transferOwnership(_newOwner);
        transferOwnerTime = 1;
    }
    
    function _transferOwnership(address _newOwner) internal virtual {
        address _oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferETHFailed();
    }
}