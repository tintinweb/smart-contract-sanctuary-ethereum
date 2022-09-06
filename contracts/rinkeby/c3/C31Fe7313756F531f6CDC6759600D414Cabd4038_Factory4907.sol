// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import "./Factory721.sol";
import "./Vault4907.sol";

contract Factory4907 is Factory721 {
    using Detector for address;

    constructor(address market) Factory721(market) {}

    function deployVault(
        string memory _name,
        string memory _symbol,
        address _collection,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _collectionOwnerFeeRatio, // 1000 = 1%
        uint256[] memory _minPrices, // wei
        address[] memory _paymentTokens,
        uint256[] calldata _allowedTokenIds
    ) external override {
        require(_collection.is4907(), "OnlyERC4907");

        address _vault = address(
            new Vault4907(
                _name,
                _symbol,
                _collection,
                msg.sender,
                _market,
                _minDuration * 1 days, // day -> sec
                _maxDuration * 1 days, // day -> sec
                _collectionOwnerFeeRatio, // bps: 1000 => 1%
                _minPrices, // wei
                _paymentTokens,
                _allowedTokenIds
            )
        );

        emit VaultDeployed(_vault, _collection);
    }
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import "./Vault721.sol";
import "./ERC4907/IERC4907.sol";

contract Vault4907 is Vault721 {
    constructor(
        string memory _name,
        string memory _symbol,
        address _collection,
        address _collectionOwner,
        address _marketContract,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _collectionOwnerFeeRatio,
        uint256[] memory _minPrices,
        address[] memory _paymentTokens, // 'Stack too deep' error because of too many args!
        uint256[] memory _allowedTokenIds
    )
        Vault721(
            _name,
            _symbol,
            _collection,
            _collectionOwner,
            _marketContract,
            _minDuration,
            _maxDuration,
            _collectionOwnerFeeRatio,
            _minPrices,
            _paymentTokens,
            _allowedTokenIds
        )
    {}

    function _deployWrap() internal pure override {
        return;
    }

    function _mintWNft(address _renter, uint256 _lockId) internal override {
        IMarket.LendRent memory _lendRent = IMarket(marketContract).getLendRent(_lockId);
        uint256 _tokenId = _lendRent.lend.tokenId;
        uint256 _rentalExpireTime = _lendRent.rent[0].rentalExpireTime;
        IERC4907(originalCollection).setUser(_tokenId, _renter, uint64(_rentalExpireTime));
    }
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import "./Vault721.sol";
import "./IMarket.sol";
import "./Detector.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Factory721 is Ownable {
    using Detector for address;

    address internal _market;

    event VaultDeployed(address indexed vault, address indexed collection);

    constructor(address market) {
        _market = market;
    }

    //@notice Create a vault by hitting this function from the frontend UI
    //@access Can be executed by anyone, but must be the owner of the original NFT collection
    function deployVault(
        string memory _name,
        string memory _symbol,
        address _collection,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _collectionOwnerFeeRatio, // 1000 = 1%
        uint256[] memory _minPrices, // wei
        address[] memory _paymentTokens,
        uint256[] calldata _allowedTokenIds
    ) external virtual {
        require(_collection.is721(), "OnlyERC721");

        address _vault = address(
            new Vault721(
                _name,
                _symbol,
                _collection,
                msg.sender,
                _market,
                _minDuration * 1 days, // day -> sec
                _maxDuration * 1 days, // day -> sec
                _collectionOwnerFeeRatio, // bps: 1000 => 1%
                _minPrices, // wei
                _paymentTokens,
                _allowedTokenIds
            )
        );

        emit VaultDeployed(_vault, _collection);
    }
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import "./Wrap721.sol";
import "./IMarket.sol";
import "./RentaFiSVG.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWrap721 {
    function emitTransfer(
        address from,
        address to,
        uint256 id,
        uint256 lockId
    ) external;
}

contract Vault721 is ERC721 {
    address public wrapContract;
    address public originalCollection;
    address public marketContract;
    address public collectionOwner;
    uint256 public minDuration;
    uint256 public maxDuration;
    uint256 public collectionOwnerFeeRatio;
    mapping(uint256 => bool) public tokenIdAllowed;
    mapping(address => uint256) public minPrices;
    address[] public paymentTokens;

    constructor(
        string memory _name,
        string memory _symbol,
        address _collection,
        address _collectionOwner,
        address _marketContract,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _collectionOwnerFeeRatio,
        uint256[] memory _minPrices,
        address[] memory _paymentTokens, // 'Stack too deep' error because of too many args!
        uint256[] memory _allowedTokenIds
    ) ERC721(_name, _symbol) {
        marketContract = _marketContract;
        originalCollection = _collection;
        collectionOwner = _collectionOwner; // Who deploys this Vault contract from Factory contract

        _setDuration(_minDuration, _maxDuration);
        _setCollectionOwnerFeeRatio(_collectionOwnerFeeRatio);
        _setMinPrices(_minPrices, _paymentTokens);

        for (uint256 i = 0; i < _allowedTokenIds.length; i++) {
            tokenIdAllowed[_allowedTokenIds[i]] = true;
        }

        _deployWrap();
    }

    function _setCollectionOwnerFeeRatio(uint256 _collectionOwnerFeeRatio) internal {
        uint256 _protocolAdminFeeRatio = IMarket(marketContract).protocolAdminFeeRatio();
        require(_protocolAdminFeeRatio + _collectionOwnerFeeRatio <= 100000, "Total fee is over 100%");
        collectionOwnerFeeRatio = _collectionOwnerFeeRatio;
    }

    function _setDuration(uint256 _minDuration, uint256 _maxDuration) internal {
        require(minDuration <= maxDuration, "minDuration > maxDuration");
        minDuration = _minDuration;
        maxDuration = _maxDuration;
    }

    function _setMinPrices(uint256[] memory _minPrices, address[] memory _paymentTokens) internal {
        require(_minPrices.length > 0, "Empty arrays are not allowed");
        require(_minPrices.length == _paymentTokens.length, "Arrays must be of the same length");
        for (uint256 i = 0; i < _minPrices.length; i++) {
            minPrices[_paymentTokens[i]] = _minPrices[i];
        }
        paymentTokens = _paymentTokens;
    }

    function _deployWrap() internal virtual {
        wrapContract = address(
            new Wrap721(
                IERC721Metadata(originalCollection).name(),
                IERC721Metadata(originalCollection).symbol(),
                marketContract
            )
        );
    }

    modifier onlyCollectionOwner() {
        require(msg.sender == collectionOwner, "onlyCollectionOwner");
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == marketContract, "onlyMarket");
        _;
    }

    function getPaymentTokens() external view returns (address[] memory) {
        return paymentTokens;
    }

    function setTokenIdAllowed(uint256[] calldata _tokenIds, bool[] calldata _allowed) external onlyCollectionOwner {
        require(_tokenIds.length == _allowed.length, "Arrays must be of the same length");
        for (uint256 i = 0; i < _allowed.length; i++) {
            if (_allowed[i]) {
                tokenIdAllowed[_tokenIds[i]] = true;
            } else {
                // Deleting a non-existent key does not result in an error.
                delete tokenIdAllowed[_tokenIds[i]];
            }
        }
    }

    // setter
    function setMinPrices(uint256[] memory _minPrices, address[] memory _paymentTokens) external onlyCollectionOwner {
        _setMinPrices(_minPrices, _paymentTokens);
    }

    function setCollectionOwnerFeeRatio(uint256 _collectionOwnerFeeRatio) external onlyCollectionOwner {
        _setCollectionOwnerFeeRatio(_collectionOwnerFeeRatio);
    }

    function setDuration(uint256 _minDuration, uint256 _maxDuration) external onlyCollectionOwner {
        _setDuration(_minDuration, _maxDuration);
    }

    function redeem(uint256 _lockId) external virtual onlyMarket {
        IMarket.Lend memory _lend = IMarket(marketContract).getLendRent(_lockId).lend;
        require(msg.sender == _lend.lender || msg.sender == marketContract, "not lender or market");
        // Send tokens back from Vault contract to the user's wallet
        IERC721(originalCollection).safeTransferFrom(address(this), _lend.lender, _lend.tokenId, "");
    }

    function mintONft(uint256 _lockId) external onlyMarket {
        address _lender = IMarket(marketContract).getLendRent(_lockId).lend.lender;
        _safeMint(_lender, _lockId);
    }

    function _mintWNft(address _renter, uint256 _lockId) internal virtual {
        uint256 _tokenId = IMarket(marketContract).getLendRent(_lockId).lend.tokenId;
        IWrap721(wrapContract).emitTransfer(address(this), _renter, _tokenId, _lockId);
    }

    function mintWNft(
        address _renter,
        uint256 _starts,
        uint256 _expires,
        uint256 _lockId
    ) public virtual onlyMarket {
        _expires;
        // If it starts later, only book and return.
        if (_starts > block.timestamp) return;
        _mintWNft(_renter, _lockId);
    }

    function activate(
        uint256 _rentId,
        uint256 _lockId,
        address _renter
    ) external virtual onlyMarket {
        IMarket.Rent[] memory _rents = IMarket(marketContract).getLendRent(_lockId).rent;
        IMarket.Rent memory _rent;
        for (uint256 i = 0; i < _rents.length; i++) {
            if (_rents[i].rentId == _rentId) {
                _rent = _rents[i];
                break;
            }
        }
        require(_rent.rentId == _rentId, "Rent not found");
        require(_rent.renterAddress == _renter, "onlyRenter");
        require(
            _rent.rentalStartTime < block.timestamp && _rent.rentalExpireTime > block.timestamp,
            "Outside the term"
        );
        _mintWNft(_renter, _lockId);
    }

    function tokenURI(uint256 _lockId) public view override returns (string memory) {
        require(_exists(_lockId), "ERC721Metadata: URI query for nonexistent token");

        // CHANGE STATE
        IMarket.Lend memory _lend = IMarket(marketContract).getLendRent(_lockId).lend;
        bytes memory json = RentaFiSVG.getOwnershipSVG(
            _lockId,
            _lend.tokenId,
            _lend.lockStartTime,
            _lend.lockExpireTime,
            IVault(_lend.vault).originalCollection(),
            name()
        );
        string memory _tokenURI = string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));

        return _tokenURI;
    }

    function burn(uint256 _lockId) external onlyMarket {
        _burn(_lockId);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external pure returns (bytes4) {
        _operator;
        _from;
        _tokenId;
        _data;
        return 0x150b7a02;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity =0.8.13;

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import "./IMarket.sol";
import "./IVault.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract Wrap721 is ERC721 {
    constructor(
        string memory _name,
        string memory _symbol,
        address _marketAddress
    ) ERC721(_name, _symbol) {
        _vault = msg.sender;
        _market = _marketAddress;
    }

    address private _vault;
    address private _market;
    uint256[] private _tokens;

    // tokenId => lockId
    mapping(uint256 => uint256) private _tokenId2LockId;

    modifier onlyVault() {
        require(msg.sender == _vault, "This method is only for vault");
        _;
    }

    function _exists(uint256 _tokenId) internal view override returns (bool) {
        // Check Lend existence
        uint256 _lockId = _tokenId2LockId[_tokenId];
        if (_lockId == 0) return false;

        // Check Rent existence
        IMarket.LendRent memory _lendRent = IMarket(_market).getLendRent(_lockId);
        if (_lendRent.rent.length == 0) return false;

        // Check Rent validity
        uint256 _rentalExpireTime = _lendRent.rent[0].rentalExpireTime;
        return _rentalExpireTime > block.timestamp;
    }

    function ownerOf(uint256 _tokenId) public view virtual override returns (address) {
        IMarket.LendRent memory _lendRent = IMarket(_market).getLendRent(_tokenId2LockId[_tokenId]);

        if (_lendRent.rent.length == 0) return _market;

        uint256 _rentalExpireTime = _lendRent.rent[0].rentalExpireTime;

        if (_rentalExpireTime > block.timestamp) {
            return _lendRent.rent[0].renterAddress;
        } else {
            return address(0);
        }
    }

    function balanceOf(address owner) public view override returns (uint256 balance) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (ownerOf(_tokens[i]) == owner) balance++;
        }
    }

    function emitTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _lockId
    ) public onlyVault {
        _tokenId2LockId[_tokenId] = _lockId;
        _tokens.push(_tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return IERC721Metadata(IVault(_vault).originalCollection()).tokenURI(_tokenId);
    }

    modifier disabled() {
        require(false, "Disabled function");
        _;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override disabled {}

    function approve(address to, uint256 tokenId) public override disabled {}

    function getApproved(uint256 tokenId) public view override disabled returns (address) {}

    function setApprovalForAll(address operator, bool _approved) public override disabled {}

    function isApprovedForAll(address owner, address operator) public view override disabled returns (bool) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override disabled {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public override disabled {}
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

interface IMarket {
    enum ListType {
        Public,
        Private,
        Event
    }
    enum PaymentMethod {
        OneTime,
        Loan,
        BNPL,
        Subscription
    }
    struct Lend {
        uint256 lockStartTime;
        uint256 lockExpireTime;
        uint256 minRentalDuration; // days
        uint256 maxRentalDuration; // days
        uint256 dailyRentalPrice; // wei
        uint256 tokenId;
        uint256 amount; // for ERC1155
        address vault;
        address paymentToken;
        address lender;
        ListType listType;
        PaymentMethod paymentMethod;
    }
    struct Rent {
        address renterAddress;
        uint256 rentId;
        uint256 rentalStartTime;
        uint256 rentalExpireTime;
        uint256 amount;
    }
    struct LendRent {
        Lend lend;
        Rent[] rent;
    }

    function getLendRent(uint256 _lockId) external view returns (LendRent memory);

    function protocolAdminFeeRatio() external view returns (uint256);

    // function collectionOwner(address originalCollection) external view returns (address);
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

library RentaFiSVG {
    function weiToEther(uint256 num) public pure returns (string memory) {
        if (num == 0) return "0.0";
        bytes memory b = bytes(Strings.toString(num));
        uint256 n = b.length;
        if (n < 19) for (uint i = 0; i < 19 - n; i++) b = abi.encodePacked("0", b);
        n = b.length;
        uint256 k = 18;
        for (uint i = n - 1; i > n - 18; i--) {
            if (b[i] != "0") break;
            k--;
        }
        uint256 m = n - 18 + k + 1;
        bytes memory a = new bytes(m);
        for (uint256 i = 0; i < k; i++) a[m - 1 - i] = b[n - 19 + k - i];
        a[m - k - 1] = ".";
        for (uint256 i = 0; i < n - 18; i++) a[m - k - 2 - i] = b[n - 19 - i];
        return string(a);
    }

    function getYieldSVG(
        uint256 _lockId,
        uint256 _tokenId,
        uint256 _benefit,
        uint256 _lockStartTime,
        uint256 _lockExpireTime,
        address _collection,
        string memory _name,
        string memory _tokenSymbol
    ) public pure returns (bytes memory) {
        string memory parsed = weiToEther(_benefit);
        string memory svg = string(
            abi.encodePacked(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' fill='#fff' viewBox='0 0 486 300'><rect width='485.4' height='300' fill='#fff' rx='12'/><rect width='485.4' height='300' fill='url(#a)' rx='12'/><text fill='#5A6480' font-family='Poppins' font-size='16' font-weight='400'><tspan x='28' y='40'>Yield NFT</tspan><tspan x='420' y='170'>",
                    _tokenSymbol,
                    "</tspan></text><text fill='#5A6480' font-family='Inter' font-size='24' font-weight='900'><tspan x='28' y='135'>Claimable Funds</tspan></text><text fill='#5A6480' font-family='Inter' font-size='16' font-weight='900' text-anchor='end'><tspan x='415' y='170'>",
                    parsed,
                    "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='900'><tspan x='28' y='270'>"
                ),
                abi.encodePacked(
                    _name,
                    "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='283'>",
                    Strings.toHexString(uint256(uint160(_collection)), 20),
                    "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400' text-anchor='end'><tspan x='463' y='270'>#",
                    Strings.toString(_tokenId),
                    "</tspan></text><defs><linearGradient id='a' x1='0' x2='379' y1='96' y2='353' gradientUnits='userSpaceOnUse'><stop stop-color='#7DBCFF' stop-opacity='.1'/><stop offset='1' stop-color='#FF7DC0' stop-opacity='.1'/></linearGradient></defs></svg>"
                )
            )
        );

        bytes memory json = abi.encodePacked(
            '{"name": "yieldNFT #',
            Strings.toString(_lockId),
            ' - RentaFi", "description": "YieldNFT represents Rental Fee deposited by Borrower in a RentaFi Escrow. The owner of this NFT can claim rental fee after lock-time expired by burn this.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '", "attributes":[{"display_type": "date", "trait_type": "StartDate", "value":"',
            Strings.toString(_lockStartTime),
            '"},{"display_type": "date", "trait_type":"ExpireDate", "value":"',
            Strings.toString(_lockExpireTime),
            '"},{"trait_type":"FeeAmount", "value":"',
            parsed,
            '"}]}'
        );

        return json;
    }

    function getOwnershipSVG(
        uint256 _lockId,
        uint256 _tokenId,
        uint256 _lockStartTime,
        uint256 _lockExpireTime,
        address _collection,
        string memory _name
    ) public pure returns (bytes memory) {
        string memory svg = string(
            abi.encodePacked(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' fill='#fff' viewBox='0 0 486 300'><rect width='485.4' height='300' fill='#fff' rx='12'/><rect width='485.4' height='300' fill='url(#a)' rx='12'/><text fill='#5A6480' font-family='Poppins' font-size='16' font-weight='400'><tspan x='28' y='40'>Ownership NFT</tspan><tspan x='250' y='270'>Until Unlock</tspan><tspan x='430' y='270'>Day</tspan></text><text fill='#5A6480' font-family='Inter' font-size='32' font-weight='900'><tspan x='28' y='150'>",
                    _name,
                    "</tspan></text><text fill='#5A6480' font-family='Inter' font-size='36' font-weight='900' text-anchor='end'><tspan x='425' y='270'>",
                    Strings.toString((_lockExpireTime - _lockStartTime) / 1 days)
                ),
                abi.encodePacked(
                    "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='170'>",
                    Strings.toHexString(uint256(uint160(_collection)), 20),
                    "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='185'>",
                    Strings.toString(_tokenId),
                    "</tspan></text><defs><linearGradient id='a' x1='0' x2='379' y1='96' y2='353' gradientUnits='userSpaceOnUse'><stop stop-color='#7DBCFF' stop-opacity='.1'/><stop offset='1' stop-color='#FF7DC0' stop-opacity='.1'/></linearGradient></defs></svg>"
                )
            )
        );

        bytes memory json = abi.encodePacked(
            '{"name": "OwnershipNFT #',
            Strings.toString(_lockId),
            ' - RentaFi", "description": "OwnershipNFT represents Original NFT locked in a RentaFi Escrow. The owner of this NFT can claim original NFT after lock-time expired by burn this.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '", "attributes":[{"display_type": "date", "trait_type": "StartDate", "value":"',
            Strings.toString(_lockStartTime),
            '"},{"display_type": "date", "trait_type":"ExpireDate", "value":"',
            Strings.toString(_lockExpireTime),
            '"}]}'
        );

        return json;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

interface IVault {
    function factoryContract() external view returns (address);

    function name() external view returns (string memory);

    function approve(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function mintONft(uint256 lockId) external;

    function mintWNft(
        address renter,
        uint256 starts,
        uint256 expires,
        uint256 lockId
    ) external;

    function activate(
        uint256 _rentId,
        uint256 _lockId,
        address renter
    ) external;

    function originalCollection() external view returns (address);

    function redeem(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function collectionOwner() external view returns (address);

    function collectionOwnerFeeRatio() external view returns (uint256);

    function tokenIdAllowed(uint256 tokenId) external view returns (bool);

    function getPaymentTokens() external view returns (address[] memory);

    function setMinPrices(uint256[] memory minPrices, address[] memory paymentTokens) external;

    function minPrices(address paymentToken) external view returns (uint256);

    function minDuration() external view returns (uint256);

    function maxDuration() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ERC4907/IERC4907.sol";

library Detector {
    function is721(address collection) public view returns (bool) {
        return IERC165(collection).supportsInterface(type(IERC721).interfaceId);
    }

    function is1155(address collection) public view returns (bool) {
        return IERC165(collection).supportsInterface(type(IERC1155).interfaceId);
    }

    function is4907(address collection) public view returns (bool) {
        return IERC165(collection).supportsInterface(type(IERC4907).interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}