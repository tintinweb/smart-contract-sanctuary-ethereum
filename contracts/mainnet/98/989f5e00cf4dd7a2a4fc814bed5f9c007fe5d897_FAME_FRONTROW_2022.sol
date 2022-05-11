/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
interface ERC1155 is ERC165 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
interface ERC1155TokenReceiver is ERC165 {
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}
interface ERC1155Metadata_URI is ERC165 {
    function uri(uint256 _id) external view returns (string memory);
}

abstract contract FAME_WHITELIST is ERC165, ERC1155, ERC1155Metadata_URI {
    function isWhitelist(address _account) public view virtual returns (uint256) {}
}

contract FAME_FRONTROW_2022 is FAME_WHITELIST {
    address payable public factory;
    
    string public constant name = "FAME FRONTROW 2022";
    address public constant owner = 0x4a3E0107381252519ee681e58616810508656a14;
    uint256 public volume = 0;
    uint256 public maxVolume = 10_000;
    mapping(uint256 => address) private owners;
    mapping(uint256 => bytes32) private types;
    mapping(address => uint256) private totalBalances;
    mapping(address => mapping(address => bool)) private operatorApprovals;
    string private baseURI = "https://xfame.app/metadata/frontrow-2022/";
    
    modifier onlyFAME() {
        require(msg.sender == owner, "FAME_FRONTROW_2022: caller is not approved");
        _;
    }
    modifier onlyFactory() {
        require(msg.sender == factory, "FAME_FRONTROW_2022: caller is not approved");
        _;
    }

    constructor() {
        factory = payable(address(new FAME_FACTORY_FRONTROW_2022(this)));
        _mint(msg.sender, owner, '');
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(ERC1155).interfaceId || interfaceId == type(ERC1155Metadata_URI).interfaceId || interfaceId == type(ERC165).interfaceId;
    }
    function uri(uint256 _id) external view override returns (string memory) {
        require(owners[_id] != address(0), "FAME_FRONTROW_2022: uri query for unregistered token");

        return string(abi.encodePacked(baseURI, _toString(_id)));
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) public override {
        require(_from == msg.sender || isApprovedForAll(_from, msg.sender), "FAME_FRONTROW_2022: transfer caller is not owner nor approved");
        require(_to != address(0), "FAME_FRONTROW_2022: transfer to the zero address");
        require(_from == ownerOf(_id), "FAME_FRONTROW_2022: insufficient balance for transfer");
        require(_amount == 1, "FAME_FRONTROW_2022: amount is not 1");

        owners[_id] = _to;
        totalBalances[_from]--;
        totalBalances[_to]++;
        emit TransferSingle(msg.sender, _from, _to, _id, 1);

        _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, 1, _data);
    }
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external override {
        require(_from == msg.sender || isApprovedForAll(_from, msg.sender), "FAME_FRONTROW_2022: transfer caller is not owner nor approved");
        require(_ids.length == _amounts.length, "FAME_FRONTROW_2022: ids and amounts length mismatch");
        require(_to != address(0), "FAME_FRONTROW_2022: transfer to the zero address");

        for (uint256 i = 0; i < _ids.length; i++) {
            require(_from == ownerOf(_ids[i]), "FAME_FRONTROW_2022: insufficient balance for transfer");
            require(_amounts[i] == 1, "FAME_FRONTROW_2022: amount is not 1");

            owners[_ids[i]] = _to;
        }
        totalBalances[_from] -= _ids.length;
        totalBalances[_to] += _ids.length;
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _amounts, _data);
    }
    function balanceOf(address _account, uint256 _id) public view override returns (uint256) {
        require(_account != address(0), "FAME_FRONTROW_2022: balance query for the zero address");

        return owners[_id] == _account ? 1 : 0;
    }
    function balanceOfBatch(address[] memory _accounts, uint256[] memory _ids) external view override returns (uint256[] memory) {
        require(_accounts.length == _ids.length, "FAME_FRONTROW_2022: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](_accounts.length);
        for (uint256 i = 0; i < _accounts.length; i++) {
            batchBalances[i] = balanceOf(_accounts[i], _ids[i]);
        }

        return batchBalances;
    }
    function setApprovalForAll(address _operator, bool _approved) external override {
        require(msg.sender != _operator, "FAME_FRONTROW_2022: setting approval status for self");
        
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function isApprovedForAll(address _account, address _operator) public view override returns (bool) {
        return operatorApprovals[_account][_operator];
    }
    
    function ownerOf(uint256 _id) public view returns (address) {
        address tokenOwner = owners[_id];
        require(tokenOwner != address(0), "FAME_FRONTROW_2022: owner query for unregistered token");

        return tokenOwner;
    }
    function typeOf(uint256 _id) external view returns (bytes32) {
        require(owners[_id] != address(0), "FAME_FRONTROW_2022: owner query for unregistered token");

        return types[_id];
    }
    function isWhitelist(address _account) public view override returns (uint256) {
        return totalBalances[_account];
    }

    function setFactory(address _factory) external onlyFAME {
        factory = payable(_factory);
    }
    function setURI(string memory _uri) external onlyFAME {
        baseURI = _uri;
    }
    function setMaxVolume(uint256 _maxVolume) external onlyFAME {
        require(_maxVolume > volume, "FAME_FRONTROW_2022: max volume is too small");

        maxVolume = _maxVolume;
    }
    function setType(uint256 _id, bytes32 _type) public onlyFAME {
        require(owners[_id] != address(0), "FAME_FRONTROW_2022: query for unregistered token");

        types[_id] = _type;
    }
    function setTypeBatch(uint256[] memory _ids, bytes32[] memory _types) external onlyFAME {
        require(_ids.length == _types.length, "FAME_FRONTROW_2022: ids and types length mismatch");

        for (uint256 i = 0; i < _ids.length; i++) {
            setType(_ids[i], _types[i]);
        }
    }

    function mint(address _operator, address _to, uint256 _amount, bytes memory _data) external onlyFactory() {
        if (_amount == 1) {
            _mint(_operator, _to, _data);
        } else {
            _mintBatch(_operator, _to, _amount, _data);
        }
    }
    function _mint(address _operator, address _to, bytes memory _data) private {
        require(_operator != address(0), "FAME_FRONTROW_2022: operator is zero address");
        require(_to != address(0), "FAME_FRONTROW_2022: transfer to the zero address");
        require(volume < maxVolume, "FAME_FRONTROW_2022: cannot mint more");

        uint256 id = volume;
        owners[id] = _to;
        volume++;
        totalBalances[_to]++;
        emit TransferSingle(msg.sender, address(0), _to, id, 1);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), _to, id, 1, _data);
    }
    function _mintBatch(address _operator, address _to, uint256 _amount, bytes memory _data) private {
        require(_operator != address(0), "FAME_FRONTROW_2022: operator is zero address");
        require(_to != address(0), "FAME_FRONTROW_2022: transfer to the zero address");
        require(volume + _amount <= maxVolume, "FAME_FRONTROW_2022: cannot mint more");

        uint256[] memory ids = new uint256[](_amount);
        uint256[] memory amounts = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            ids[i] = volume;
            amounts[i] = 1;
            owners[volume] = _to;
            volume++;
        }
        totalBalances[_to] += _amount;
        emit TransferBatch(_operator, address(0), _to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(_operator, address(0), _to, ids, amounts, _data);
    }

    function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 id, uint256 amount, bytes memory _data) private {
        if (_to.code.length > 0) {
            try ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, id, amount, _data) returns (bytes4 response) {
                if (response != ERC1155TokenReceiver.onERC1155Received.selector) {
                    revert("FAME_FRONTROW_2022: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("FAME_FRONTROW_2022: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) private {
        if (_to.code.length > 0) {
            try ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _amounts, _data) returns (bytes4 response) {
                if (response != ERC1155TokenReceiver.onERC1155BatchReceived.selector) {
                    revert("FAME_FRONTROW_2022: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("FAME_FRONTROW_2022: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    function _toString(uint256 value) internal pure returns (string memory) {
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
}

contract FAME_FACTORY_FRONTROW_2022 {
    address payable private constant FAME_UNIVERSE = payable(0x4a3E0107381252519ee681e58616810508656a14);
    FAME_FRONTROW_2022 private frontrow;

    mapping(address => uint256) public whitelist;
    mapping(address => uint256) private mintedAmounts;
    uint256 private constant MaxMintableAmount = 3;

    struct Sale {
        uint256 open;
        uint256 limit;
        uint256 price;
        uint256 minWhitelistLevel;
    }
    mapping(uint256 => Sale) public sales;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = 1;

    event Mint(uint256 indexed _id, address indexed _operator);

    modifier nonReentrant() {
        require(_status != _ENTERED, "FAME_FACTORY_FRONTROW_2022: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    modifier onlyFAME() {
        require(msg.sender == FAME_UNIVERSE, "FAME_FACTORY_FRONTROW_2022: caller is not approved");
        _;
    }

    constructor(FAME_FRONTROW_2022 _frontrow) {
        frontrow = _frontrow;

        // Pre Sales
        sales[0] = Sale({
            open: 1651150800, // April 28, 2022 13:00:00 GMT
            limit: 400, // #0 ~ #399
            price: 0.08 ether,
            minWhitelistLevel: 1 // Whitelist only
        });
    }

    function mintableAmountOf(address _owner) public view returns (uint256) {
        return MaxMintableAmount - mintedAmounts[_owner];
    }

    function mint(uint256 _salesId, uint256 _amount) external payable nonReentrant {
        Sale memory sale = sales[_salesId];
        uint256 volume = frontrow.volume();
        require(_amount > 0 && _amount <= mintableAmountOf(msg.sender), "FAME_FACTORY_FRONTROW_2022: invalid minting amount");
        require(msg.value == _amount * sale.price, "FAME_FACTORY_FRONTROW_2022: wrong value");
        require(block.timestamp >= sale.open, "FAME_FACTORY_FRONTROW_2022: market not open");
        require(volume + _amount <= sale.limit, "FAME_FACTORY_FRONTROW_2022: market closed");
        require(whitelist[msg.sender] >= sale.minWhitelistLevel, "FAME_FACTORY_FRONTROW_2022: only available for whitelist members");

        frontrow.mint(msg.sender, msg.sender, _amount, '');
        mintedAmounts[msg.sender] += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            emit Mint(volume + i, msg.sender);
        }
    }
    function privateInvitations(address[] memory _to) external onlyFAME {
        for (uint256 i = 0; i < _to.length; i++) {
            frontrow.mint(msg.sender, _to[i], 1, '');
        }
    }

    function addWhitelist(address _account) public onlyFAME {
        whitelist[_account] = 1;
    }
    function addWhitelistBatch(address[] memory _accounts) external onlyFAME {
        for(uint256 i = 0; i < _accounts.length; i++) {
            addWhitelist(_accounts[i]);
        }
    }
    function setWhitelist(address _account, uint256 _value) public onlyFAME {
        whitelist[_account] = _value;
    }
    function setWhitelistBatch(address[] memory _accounts, uint256 _value) external onlyFAME {
        for(uint256 i = 0; i < _accounts.length; i++) {
            setWhitelist(_accounts[i], _value);
        }
    }
    function setSales(uint256 _salesId, uint256 _open, uint256 _limit, uint256 _price, uint256 _minWhitelistLevel) external onlyFAME {
        sales[_salesId] = Sale({
            open: _open,
            limit: _limit,
            price: _price,
            minWhitelistLevel: _minWhitelistLevel
        });
    }
    function withdraw() external {
        FAME_UNIVERSE.transfer(address(this).balance);
    }
}