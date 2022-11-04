// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC1155 {
    function safeMint(address to, uint256 tokenId) external;
}

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract AstrolistSell is Ownable {
    using Strings for uint256;
    mapping(address => bool) private _isWhiteListed;

    mapping(address => bool) private _isNotEligible;

    mapping(uint256 => bool) private _isIdTaken;

    address private _collectorAddress;

    IERC1155 private _nftToken;

    IERC20 private _erc20Token;

    uint256 private _price;

    string private _baseUri = "https://gateway.pinata.cloud/ipfs/";

    string extendedString1 = "/Erc721_Data_";

    string extendedString2 = ".json";

    struct TokenUri {
        string uri;
        uint256 tokenId;
    }

    constructor(
        address nftAddress,
        address erc20Address,
        address collectorAddress
    ) {
        _nftToken = IERC1155(nftAddress);
        _erc20Token = IERC20(erc20Address);
        _collectorAddress = collectorAddress;
    }

    function claimReward() external {
        address to = _msgSender();
        require(_isWhiteListed[to], "Address is not WhiteListed");
        require(!_isNotEligible[to], "You are not eligible");
        _isWhiteListed[to] = false;
        for (uint256 i; i < 501; i++) {
            if (!_isIdTaken[i]) {
                _nftToken.safeMint(to, i);
                _isIdTaken[i] = true;
                _isNotEligible[to] = true;
                break;
            }
        }

        _isNotEligible[to] = true;
    }

    function claimRewardByTokenId(uint256 tokenId) external {
        address to = _msgSender();
        require(_isIdTaken[tokenId], "TokenId is already taken");
        require(_isWhiteListed[to], "Address is not whiteListed");
        require(!_isNotEligible[to], "You are not eligible");
        _isWhiteListed[to] = false;
        _nftToken.safeMint(to, tokenId);
        _isIdTaken[tokenId] = true;
        _isNotEligible[to] = true;
    }

    function whiteListAddresses(address[] memory userAddresses)
        external
        onlyOwner
    {
        for (uint256 i; i < userAddresses.length; i++) {
            _isWhiteListed[userAddresses[i]] = true;
        }
    }

    function removeWhiteListedAddresses(address[] memory userAddresses)
        external
        onlyOwner
    {
        for (uint256 i; i < userAddresses.length; i++) {
            _isWhiteListed[userAddresses[i]] = false;
        }
    }

    function buyNft(uint256 tokenId) external {
        require(!_isIdTaken[tokenId], "Token Id is already taken");

        address userAddress = _msgSender();
        require(!_isNotEligible[userAddress], "You are not eligible");

        _erc20Token.transferFrom(userAddress, _collectorAddress, _price);
        _nftToken.safeMint(userAddress, tokenId);
        _isIdTaken[tokenId] = true;
    }

    function getNfts() external view returns (TokenUri[] memory) {
        uint256 count;
        uint256 index;

        for (uint256 i = 1; i < 501; i++) {
            if (!_isIdTaken[i]) {
                count++;
            }
        }
        TokenUri[] memory tokenuris = new TokenUri[](count);

        for (uint256 j = 1; j < 501; j++) {
            if (!_isIdTaken[j]) {
                tokenuris[index] = TokenUri(
                    string(abi.encodePacked(_baseUri, j)),
                    j
                );
                index++;
            }
        }
        return tokenuris;
    }

    function getNFTTemp() external view returns (TokenUri[] memory) {
        uint256 count;
        uint256 index;
        uint256 tokenId;
        string memory metaData;

        for (uint256 i = 1; i < 501; i++) {
            if (!_isIdTaken[i]) {
                count++;
            }
        }
        TokenUri[] memory tokenuris = new TokenUri[](count);

        for (uint256 j = 1; j < 501; j++) {
            if (!_isIdTaken[j]) {
                tokenId = j;
                if (tokenId > 0 && tokenId < 101) {
                    metaData = "QmayKSgyEe6xgfoVfsYhdSHSNoDP17ukfDg5b7mzqGXFCS";
                }
                if (tokenId > 100 && tokenId < 201) {
                    metaData = "QmXqhk7tsF4uor92KCuYGepWKR2d7c3Jqz9Qmr6wBwxSBt";
                }
                if (tokenId > 200 && tokenId < 301) {
                    metaData = "QmcxQfhbdJXoEN2KFqeZgu9JzerEe99b8tken4sbKdcdwN";
                }
                if (tokenId > 300 && tokenId < 401) {
                    metaData = "QmdbdAyscMPK9R9efwysgoBPM2fSLNWFx2wn4rDx2CZq5q";
                }
                if (tokenId > 400 && tokenId < 501) {
                    metaData = "QmRc8ePQD2SzQMbmNxxv9cAUcVZYNurVXyHcghX9nbFHY8";
                }

                tokenuris[index] = TokenUri(
                    string(
                        abi.encodePacked(
                            string(
                                abi.encodePacked(
                                    _baseUri,
                                    metaData,
                                    extendedString1,
                                    tokenId.toString(),
                                    extendedString2
                                )
                            )
                        )
                    ),
                    j
                );
                index++;
            }
        }
        return tokenuris;
    }

    function setIsIdTaken(uint256[] memory ids, bool value) external onlyOwner {
        for (uint256 i; i < ids.length; i++) {
            _isIdTaken[ids[i]] = value;
        }
    }

    function isWhiteListed(address userAddress) external view returns (bool) {
        return _isWhiteListed[userAddress];
    }

    function isNotEligible(address userAddress) external view returns (bool) {
        return _isNotEligible[userAddress];
    }

    function isIdTaken(uint256 tokenId) external view returns (bool) {
        return _isIdTaken[tokenId];
    }

    function getCollectorAddress() external view returns (address) {
        return _collectorAddress;
    }

    function getNFTAddress() external view returns (address) {
        return address(_nftToken);
    }

    function getERC20Address() external view returns (address) {
        return address(_erc20Token);
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }

    function getBaseUri() external view returns (string memory) {
        return _baseUri;
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