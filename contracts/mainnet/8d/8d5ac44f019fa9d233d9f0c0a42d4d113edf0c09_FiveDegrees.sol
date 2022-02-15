pragma solidity >= 0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./IPayProxy.sol";

contract FiveDegrees is ERC1155, Ownable {

    using Strings for uint256;

    struct TokenURIInfo {
        string name;
        string image;
        uint256 maxSupply;
        string properties;
    }

    mapping(uint256 => TokenURIInfo) private _uri;
    //followers: token => supply
    mapping(uint256 => uint256) private _tokenSupply;
    //followings: address(token) => balances
    mapping(uint256 => uint256) private _totalBalance;

    //Web3 Ascii code 87+101+98+51 = 8195
    uint256 private _max_supply = 8195;
    address public PAY_PROXY;

    event Mint(address indexed account, address indexed owner, uint256 tokenId);
    event MintBatch(address[] indexed accounts, address indexed owner, uint256[] tokenIds);
    event Burn(address indexed account, address indexed owner, uint256 tokenId);
    event BurnBatch(address[] indexed accounts, address indexed owner, uint256[] tokenIds);

    constructor() ERC1155("") Ownable() public {
        uint256 tokenId = uint256(uint160(address(this)));
        _uri[tokenId].maxSupply = 2022;
    }

    function setProtocolInfo(string memory name, string memory image, string memory properties) public onlyOwner {
        uint256 tokenId = uint256(uint160(address(this)));
        _uri[tokenId].name = name;
        _uri[tokenId].image = image;
        _uri[tokenId].properties = properties;
        emit URI(uri(tokenId), tokenId);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        TokenURIInfo memory info = _uri[tokenId];
        if (info.maxSupply == 0) {
            info.maxSupply = _max_supply;
        }
        uint256 followers = _tokenSupply[tokenId];
        uint256 followings = _totalBalance[tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        info.name,
                        '", ',
                        '"image": "',
                        info.image,
                        '", ',
                        '"maxSupply": "',
                        info.maxSupply.toString(),
                        '", ',
                        '"tokenSupply": "',
                        followers.toString(),
                        '", ',
                        '"totalBalance": "',
                        followings.toString(),
                        '", ',
                        '"properties": "',
                        info.properties,
                        '" }'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function baseInfo(address account) public view returns (string memory name, string memory image) {
        TokenURIInfo memory info = _uri[uint256(uint160(account))];
        name = info.name;
        image = info.image;
    }

    function metrics(address account) public view virtual returns (uint256 tokenSupply, uint256 totalBalance) {
        tokenSupply = _tokenSupply[uint256(uint160(account))];
        totalBalance = _totalBalance[uint256(uint160(account))];
    }

    /** transaction */

    function setPayProxy(address proxy) public onlyOwner {
        PAY_PROXY = proxy;
    }

    function setInfo(string memory name, string memory image, string memory properties) public {
        uint256 tokenId = uint256(uint160(msg.sender));
        _uri[tokenId].name = name;
        _uri[tokenId].image = image;
        _uri[tokenId].properties = properties;
        emit URI(uri(tokenId), tokenId);
    }

    function increaseMaxSupply(uint256 newMax) public payable {
        uint256 tokenId = uint256(uint160(msg.sender));
        TokenURIInfo memory info = _uri[tokenId];
        if (info.maxSupply == 0) {
            info.maxSupply = _max_supply;
        }
        uint256 theMax = info.maxSupply;
        require(theMax < newMax, "5Degrees: support increase only");
        if (PAY_PROXY != address(0)) {
            (address token, address receiver, uint256 amount) = IPayProxy(PAY_PROXY).queryPay(msg.sender, newMax, theMax);
            if (amount > 0) {
                if (token == address(0)) {
                    require(msg.value >= amount, "5Degrees: invalid msg.value");
                    payable(receiver).transfer(msg.value);
                } else {
                    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, msg.sender, receiver, amount));
                    require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer_from_failed');
                }
            }
        }
        _uri[tokenId].maxSupply = newMax;
        emit URI(uri(tokenId), tokenId);
    }

    function decreaseMaxSupply(uint256 newMax) public {
        uint256 tokenId = uint256(uint160(msg.sender));
        TokenURIInfo memory info = _uri[tokenId];
        if (info.maxSupply == 0) {
            info.maxSupply = _max_supply;
        }
        require(newMax >= _tokenSupply[tokenId], "5Degrees: must be larger than the supply");
        require(info.maxSupply > newMax, "5Degrees: support decrease only");
        _uri[tokenId].maxSupply = newMax;
        emit URI(uri(tokenId), tokenId);
    }

    function mint(address account) public {
        address operator = msg.sender;
        _internal_mint(account, operator);
    }

    function mintByOrigin(address account) public {
        address operator = tx.origin;
        _internal_mint(account, operator);
    }

    function _internal_mint(address account, address operator) internal {
        uint256 tokenId = uint256(uint160(account));
        require(operator != account, "5Degrees: cannot mint your own NFT");
        require(super.balanceOf(operator, tokenId) == 0, "5Degrees: already minted");
        if (_uri[tokenId].maxSupply == 0) {
            _uri[tokenId].maxSupply = _max_supply;
        } else {
            require(_tokenSupply[tokenId] + 1 <= _uri[tokenId].maxSupply, "5Degrees: larger than max supply");
        }
        _mint(operator, tokenId, 1, "");
        _totalBalance[uint256(uint160(operator))] += 1;
        _tokenSupply[tokenId] += 1;
        emit Mint(account, operator, tokenId);
    }

    function mintBatch(address[] memory accounts) public {
        address operator = msg.sender;
        _internal_mintBatch(operator, accounts);
    }

    function mintBatchByOrigin(address[] memory accounts) public {
        address operator = tx.origin;
        _internal_mintBatch(operator, accounts);
    }

    function _internal_mintBatch(address operator, address[] memory accounts) internal {
        uint256[] memory ids = new uint256[](accounts.length);
        uint256[] memory amounts = new uint256[](accounts.length);
        for (uint256 i; i < accounts.length; i++) {
            uint256 tokenId = uint256(uint160(accounts[i]));
            if (operator == accounts[i] || super.balanceOf(operator, tokenId) > 0 || _tokenSupply[tokenId] + 1 > _uri[tokenId].maxSupply) {
                continue;
            }
            if (_uri[tokenId].maxSupply == 0) {
                _uri[tokenId].maxSupply = _max_supply;
            }
            _totalBalance[uint256(uint160(operator))] += 1;
            _tokenSupply[tokenId] += 1;
            ids[i] = tokenId;
            amounts[i] = 1;
        }
        _mintBatch(operator, ids, amounts, "");
        emit MintBatch(accounts, operator, ids);
    }

    function burn(address account) public {
        address operator = msg.sender;
        _internal_burn(account, operator);
    }

    function burnOrigin(address account) public {
        address operator = tx.origin;
        _internal_burn(account, operator);
    }

    function _internal_burn(address account, address operator) internal {
        uint256 tokenId = uint256(uint160(account));
        require(super.balanceOf(operator, tokenId) > 0, "5Degrees: token not existed");
        _burn(operator, tokenId, 1);
        _totalBalance[uint256(uint160(operator))] -= 1;
        _tokenSupply[tokenId] -= 1;
        emit Burn(account, operator, tokenId);
    }

    function burnBatch(address[] memory accounts) public {
        address operator = msg.sender;
        _internal_brunBatch(operator, accounts);
    }

    function burnBatchByOrigin(address[] memory accounts) public {
        address operator = tx.origin;
        _internal_brunBatch(operator, accounts);
    }

    function _internal_brunBatch(address operator, address[] memory accounts) internal {
        uint256[] memory ids = new uint256[](accounts.length);
        uint256[] memory amounts = new uint256[](accounts.length);
        for (uint256 i; i < accounts.length; i++) {
            uint256 tokenId = uint256(uint160(accounts[i]));
            if (super.balanceOf(operator, tokenId) == 0) {
                continue;
            }
            _totalBalance[uint256(uint160(operator))] -= 1;
            _tokenSupply[tokenId] -= 1;
            ids[i] = tokenId;
            amounts[i] = 1;
        }
        _burnBatch(operator, ids, amounts);
        emit BurnBatch(accounts, operator, ids);
    }

    //check transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override {
        require(super.balanceOf(to, id) == 0, "5Degrees: already minted");
        require(super.balanceOf(to, uint256(uint160(msg.sender))) > 0, "5Degrees: receiver hasn't minted sender's NFT");
        super.safeTransferFrom(from, to, id, amount, data);
        _totalBalance[uint256(uint160(from))] -= amount;
        _totalBalance[uint256(uint160(to))] += amount;
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override {
        require(ids.length == amounts.length, "5Degrees: length of ids and amounts mismatch");
        uint256 amount = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            require(super.balanceOf(to, ids[i]) == 0, "5Degrees: already minted");
            amount += amounts[i];
        }
        require(super.balanceOf(to, uint256(uint160(msg.sender))) > 0, "5Degrees: receiver hasn't minted sender's NFT");
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        _totalBalance[uint256(uint160(from))] -= amount;
        _totalBalance[uint256(uint160(to))] += amount;
    }

    function toString(bytes memory data) private pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}