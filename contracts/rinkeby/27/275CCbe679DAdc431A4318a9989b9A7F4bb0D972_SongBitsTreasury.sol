// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./interfaces/IParams.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/ICollection.sol";

import "./utils/Ownable.sol";

contract SongBitsTreasury is Ownable, IMetadata {
    event Buy(
        address indexed who,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 bits
    );

    mapping(address => IParams.Fees) private _fees;
    uint256 private _fanInventory;
    uint256 private _songbidsBank;
    address private _collection;

    constructor() {
        _transferOwnership(msg.sender);
    }

    function getFanInventory() public view returns (uint256) {
        return _fanInventory;
    }

    function getSongbidsBank() public view returns (uint256) {
        return _songbidsBank;
    }

    function getFees(address _artist)
        public
        view
        returns (IParams.Fees memory)
    {
        return _fees[_artist];
    }

    function setFee(address _author, IParams.Fees memory fees_) public {
        _fees[_author] = fees_;
    }

    function buy(uint256 _metadataId, uint256 _bits) public payable {
        ICollection collection = ICollection(_collection);
        Metadata memory metadata = collection.getMetadata(_metadataId);

        require(
            collection.getMetadata(_metadataId).cost <= msg.value,
            "insufficient funds"
        );
        require(
            _bits <= metadata.duration,
            "should be less or equal to the duration"
        );

        require(metadata.totalBought != metadata.duration, "No free bits");

        collection.mint(_metadataId, msg.sender, _bits);

        _revenuePrimatySale(payable(metadata.artist), msg.value);

        emit Buy(msg.sender, _metadataId, msg.value, _bits);
    }

    function _revenuePrimatySale(address payable _artist, uint256 _amount)
        internal
    {
        IParams.Fees memory fees = _fees[_collection];

        uint256 claculatedAuthorFee = (_amount *
            fees._artistPrimaryFeePrecent) / 10000;
        uint256 claculatedFanFee = (_amount * fees._fanFeePercent) / 10000;
        uint256 claculatedSongBitsFee = (_amount * fees._singbitFeePercent) /
            10000;

        (bool ar, ) = _artist.call{value: claculatedAuthorFee}("");
        require(ar);

        _fanInventory += claculatedFanFee;
        _songbidsBank += claculatedSongBitsFee;
    }

    function _revenueResale(
        address payable _artist,
        address payable _fan,
        uint256 _amount
    ) internal {
        IParams.Fees memory fees = _fees[_collection];

        uint256 claculatedAuthorFee = (_amount * fees._artistResaleFeePrecent) /
            100;
        uint256 claculatedSongBitsFee = (_amount * fees._singbitFeePercent) /
            100;

        uint256 claculatedFanFee = _amount -
            (claculatedAuthorFee + claculatedSongBitsFee);

        (bool ar, ) = _artist.call{value: claculatedAuthorFee}("");
        require(ar);

        (bool fr, ) = _fan.call{value: claculatedFanFee}("");
        require(fr);

        _fanInventory += claculatedFanFee;
    }

    function withdraw() public payable onlyOwner {
        (bool result, ) = payable(owner()).call{value: _songbidsBank}("");
        require(result);
    }

    function setCollection(address collection_) public onlyOwner {
        _collection = collection_;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

interface IParams {
    struct CollectionParams {
        string _name;
        string _symbol;
    }

    struct Fees {
        uint256 _singbitFeePercent;
        uint256 _artistResaleFeePrecent;
        uint256 _artistPrimaryFeePrecent;
        uint256 _fanFeePercent;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

interface IMetadata {
    struct Metadata {
        address artist;
        address owner;
        uint256 duration;
        uint256 parentId;
        uint256 totalBought;
        uint256 cost;
        string uri;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./IERC721.sol";
import "./IMetadata.sol";

interface ICollection is IERC721, IMetadata {
    event Mint(address _to, uint256 _duration, uint256 _cost, string uri);

    function totalSupply() external view returns (uint256);

    function getMetadata(uint256 tokenId)
        external
        view
        returns (Metadata memory);

    function mint(
        uint256 _id,
        address _to,
        uint256 bits
    ) external;

    function createMetadata(
        address artist,
        uint256 tokenId,
        uint256 duration,
        uint256 parentId,
        uint256 cost,
        string memory uri
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./IERC165.sol";

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

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

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}