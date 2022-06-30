// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IKongWFC {
    function mint(uint256 quantity) external payable;

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external returns (address);

    function balanceOf(address owner) external returns (uint256);
}

contract KongWFCProxy is Ownable {
    IKongWFC public immutable kongWFC;
    uint256 public currentNftIndex;
    uint256 public endIndex;

    // uint256 public constant WHITELIST_MINT_START_DATE = 1661965200;
    uint256 public constant WHITELIST_MINT_START_DATE = 1656595800; //Thursday, June 30, 2022 4:30:00 PM GMT+03:00

    uint256 public constant RESERVED_PRICE = 0.0013 ether;

    mapping(address => uint256[]) public reserved;

    error AnotherMintingOccurred();
    error TransferTxError();
    error SupplyExceeded();
    error InvalidDate();
    error InsufficientFunds();
    error DontHaveReservedNFT();
    error MaxSupplyExceeded();
    error InvalidTokenIdSet();
    error NonReservedNftsExist();

    event ValuesSet(
        uint256 supply,
        uint256 indexed startId,
        uint256 indexed endId
    );

    event NftReserved(address indexed owner, uint256 tokenId);
    event NftClaimed(address indexed owner, uint256 tokenId);

    constructor(address kongWFCAddress) {
        kongWFC = IKongWFC(kongWFCAddress);
    }

    // startIndex is the first nft id of the proxy contract
    // supply is the number of minted nft to this contract
    function setValues(uint256 _startIndex, uint256 _supply) external {
        if (currentNftIndex != 0 && currentNftIndex < endIndex)
            revert NonReservedNftsExist();

        if (
            address(this) != kongWFC.ownerOf(_startIndex + _supply - 1) ||
            address(this) != kongWFC.ownerOf(_startIndex)
        ) revert InvalidTokenIdSet();

        currentNftIndex = _startIndex;
        endIndex = _startIndex + _supply - 1;
        emit ValuesSet(_supply, _startIndex, endIndex);
    }

    // does not effect supply,directly mints from KongWfc contract and sends to "to"
    function mint(address to, uint256 quantity) external payable {
        uint256 beginIndex = kongWFC.totalSupply();
        kongWFC.mint{ value: msg.value }(quantity);
        for (uint256 i = 0; i < quantity; ) {
            kongWFC.transferFrom(address(this), to, beginIndex + i);

            unchecked {
                ++i;
            }
        }
        if (kongWFC.totalSupply() != beginIndex + quantity)
            revert AnotherMintingOccurred();
    }

    function reserve(address to, uint256 quantity) external payable {
        if (currentNftIndex + quantity - 1 > endIndex)
            revert MaxSupplyExceeded();
        // solhint-disable not-rely-on-time
        if (block.timestamp > WHITELIST_MINT_START_DATE) revert InvalidDate();

        if (msg.value < (RESERVED_PRICE) * quantity) revert InsufficientFunds();

        for (uint256 i = 0; i < quantity; ) {
            reserved[to].push(currentNftIndex + i);

            emit NftReserved(to, currentNftIndex + i);

            unchecked {
                ++i;
            }
        }
        currentNftIndex += quantity;
    }

    function claim(address to) external {
        // you cant claim before WL mint
        if (block.timestamp < WHITELIST_MINT_START_DATE) revert InvalidDate();

        uint256[] memory nfts = reserved[to];
        uint256 quantity = nfts.length;

        if (quantity <= 0) {
            revert DontHaveReservedNFT();
        }

        // send reserved nfts
        for (uint256 i = 0; i < quantity; ) {
            kongWFC.transferFrom(address(this), to, nfts[i]);
            emit NftClaimed(to, nfts[i]);

            unchecked {
                ++i;
            }
        }
        delete reserved[to];
    }

    function withdrawRemaningNfts() external onlyOwner {
        // send not reserved,remaining nft's to user
        for (; currentNftIndex <= endIndex; ) {
            kongWFC.transferFrom(address(this), owner(), currentNftIndex);

            unchecked {
                ++currentNftIndex;
            }
        }
    }

    function withdraw() external onlyOwner {
        //solhint-disable-next-line avoid-low-level-calls
        (bool isSuccess, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        if (!isSuccess) revert TransferTxError();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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