// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./interfaces/IParams.sol";
import "./interfaces/ICollection.sol";

import "./utils/Ownable.sol";

contract SongBitsTreasury is Ownable {
    mapping(address => IParams.Fees) private _fees;
    address private _factory;

    modifier notZeroFactoryAddress() {
        require(_factory != address(0));
        _;
    }

    constructor() {
        _transferOwnership(msg.sender);
    }

    function setFee(address _collection, IParams.Fees memory fees_)
        public
        notZeroFactoryAddress
    {
        require(
            ICollection(_collection).artist() == msg.sender ||
                _factory == msg.sender
        );
        _fees[_collection] = fees_;
    }

    function buy(address _collection, uint256 _tokenId)
        public
        payable
        notZeroFactoryAddress
    {
        ICollection collection = ICollection(_collection);
        require(collection.ownerOf(_tokenId) != msg.sender, "you token owner");
        require(
            collection.getMetadata(_tokenId).cost <= msg.value,
            "insufficient funds"
        );
        require(
            collection.getMetadata(_tokenId).hasPart == false,
            "solg has a part"
        );

        collection.approve(msg.sender, _tokenId);
        collection.safeTransferFrom(
            collection.ownerOf(_tokenId),
            msg.sender,
            _tokenId,
            ""
        );
        _revenue(
            payable(collection.artist()),
            payable(msg.sender),
            msg.value,
            _collection
        );
    }

    function buyPart(
        address _collection,
        uint256 _tokenId,
        uint256 boughtFrom,
        uint256 boughtTo
    ) public payable notZeroFactoryAddress {
        ICollection collection = ICollection(_collection);

        require(collection.ownerOf(_tokenId) != msg.sender, "you token owner");
        uint256 newId = collection.totalSupply() + 1;
        uint256 partCost = (collection.getMetadata(_tokenId).duration /
            collection.getMetadata(_tokenId).cost) * (boughtTo - boughtFrom);

        require(partCost <= msg.value, "insufficient funds");

        collection.mint(msg.sender, newId, partCost);
        collection.createMetadata(
            newId,
            boughtTo - boughtFrom,
            _tokenId,
            0,
            boughtTo,
            partCost,
            true,
            false
        );

        collection.getMetadata(_tokenId).hasPart = true;
        _revenue(
            payable(collection.artist()),
            payable(msg.sender),
            msg.value,
            _collection
        );
    }

    function setFactoryAddress(address factort_) public onlyOwner {
        _factory = factort_;
    }

    function _revenue(
        address payable _artist,
        address payable _fan,
        uint256 _amount,
        address _collection
    ) internal {
        IParams.Fees memory fees = _fees[_collection];

        uint256 claculatedAuthorFee = (_amount * fees._artistFeePrecent) / 100;
        uint256 claculatedFanFee = (_amount * fees._fanFeePercent) / 100;

        (bool ar, ) = _artist.call{value: claculatedAuthorFee}("");
        require(ar);

        (bool fr, ) = _fan.call{value: claculatedFanFee}("");
        require(fr);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

interface IParams {
    struct CollectionParams {
        string _name;
        string _symbol;
        string _uri;
        Fees _fees;
    }

    struct Fees {
        uint256 _singbitFeePercent;
        uint256 _artistFeePrecent;
        uint256 _fanFeePercent;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./IERC721.sol";

interface ICollection is IERC721 {
    struct Metadata {
        uint256 duration;
        uint256 parentId;
        uint256 boughtFrom;
        uint256 boughtTo;
        uint256 cost;
        bool isPart;
        bool hasPart;
    }

    function artist() external view returns (address);

    function totalSupply() external view returns (uint256);

    function getMetadata(uint256 tokenId)
        external
        view
        returns (Metadata memory);

    function mint(
        address _to,
        uint256 _duration,
        uint256 _cost
    ) external;

    function createMetadata(
        uint256 tokenId,
        uint256 duration,
        uint256 parentId,
        uint256 boughtFrom,
        uint256 boughtTo,
        uint256 cost,
        bool isPart,
        bool hasPart
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