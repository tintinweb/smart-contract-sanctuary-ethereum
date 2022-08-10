// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IMint {
    event Minted(address targetAddress, uint tokenId);
    event AdminChanged(address oldAdmin, address newAdmin);
    event DevWalletChanged(address oldDevWallet, address newDevWallet);
    event WithdrawedBalance(address devWallet, uint amount);
    event Withdrawed(address devWallet, uint tokenId);
    event SalePriceChanged(uint oldPrice, uint newPrice);
}

contract Mint is IMint, Ownable {
    address payable public admin;
    address payable public devWallet =
        payable(0x3b3B9e2f88Fa57B41f0026F4E95E1cbd12C05ad9);
    IERC721 public crr = IERC721(0x9c6b5033Ee140082E55B4d8CA32EA72F8bbFB4A5);
    uint256 public salePrice = 0.2 ether;
    mapping(uint256 => uint256) public NFTs;
    uint256 public mintableAmount;

    constructor() {
        admin = payable(msg.sender);
    }

    function mint(address account, uint256[] memory tokenIds) public payable {
        uint mintAmount = tokenIds.length;
        require(
            crr.balanceOf(account) + mintAmount < 4,
            "One user can own only 3 NFTs"
        );
        for (uint i = 0; i < mintAmount; i++) {
            require(
                crr.ownerOf(tokenIds[i]) == address(this),
                "Contract does not have this NFT."
            );
        }
        require(
            msg.value >= salePrice * mintAmount,
            "Price is less than salePrice."
        );
        _checkMintables();
        for (uint i = 0; i < mintAmount; i++) {
            crr.approve(account, tokenIds[i]);
            crr.safeTransferFrom(address(this), account, tokenIds[i]);
            NFTs[tokenIds[i]] = 0;
            mintableAmount--;
            emit Minted(account, tokenIds[i]);
        }
        devWallet.transfer(msg.value);
    }

    function checkMintables() external {
        _checkMintables();
    }

    function _checkMintables() internal {
        mintableAmount = 0;
        for (uint i = 0; i < 111; i++) {
            if (crr.ownerOf(i) == address(this)) {
                NFTs[i] = i + 1;
                mintableAmount++;
            } else {
                NFTs[i] = 0;
            }
        }
    }

    function setAdmin(address payable _admin) public onlyOwner {
        require(_admin != address(0), "Ownable: new owner is the zero address");
        if (admin != _admin) {
            _transferOwnership(_admin);
            admin = _admin;
            emit AdminChanged(admin, _admin);
        }
    }

    function setDevWallet(address payable _devWallet) public onlyOwner {
        require(
            _devWallet != address(0),
            "Ownable: new owner is the zero address"
        );
        if (devWallet != _devWallet) {
            devWallet = _devWallet;
            emit DevWalletChanged(devWallet, _devWallet);
        }
    }

    function setSalePrce(uint _salePrice) public onlyOwner {
        if (salePrice != _salePrice) {
            salePrice = _salePrice;
            emit SalePriceChanged(salePrice, _salePrice);
        }
    }

    function withdrawETH() public onlyOwner {
        uint _balance = address(this).balance;
        admin.transfer(_balance);
        emit WithdrawedBalance(admin, _balance);
    }

    function withdrawNFTs() public onlyOwner {
        uint amount;
        for (uint i = 0; i < 111; i++) {
            if (crr.ownerOf(i) == address(this)) {
                crr.approve(devWallet, i);
                crr.transferFrom(address(this), devWallet, i);
                amount++;
            }
        }
        emit Withdrawed(devWallet, amount);
    }

    function getMintableNFTs() public view returns (uint256[] memory) {
        uint256[] memory _mintableNFTs = new uint256[](mintableAmount);
        uint j = 0;
        for (uint i = 0; i < 111; i++) {
            if (NFTs[i] != 0) {
                _mintableNFTs[j] = NFTs[i];
                j++;
            }
        }
        return _mintableNFTs;
    }

    function setToken(address _tokenAddress) public onlyOwner {
        crr = IERC721(_tokenAddress);
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