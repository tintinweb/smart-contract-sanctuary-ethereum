// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface INFT {
    function mint(address _to, uint256 _tokenId) external;

    function tokenTypeAndPrice(uint256 _tokenId)
        external
        view
        returns (string memory _tokenType, uint256 _price);

    function ownerOf(uint256 _tokenId) external returns (address owner);
}

contract ChildZoothereum is Ownable {
    INFT public zoothereumContract;
    //check if tokeId in minted array, if minted ++ else counter +1 if limit of range revert
    mapping(uint256 => bool) mintedNfts;
    uint16[9] maxSupplyPerRange = [250, 450, 600, 700, 790, 835, 865, 885, 900];
    uint256[9] public rangesCurrTokenId = [
        1,
        251,
        451,
        601,
        701,
        791,
        836,
        866,
        886
    ];

    // MODIFIERS

    /*
     * @notice checks if range selected is valid and has available nfts to mint
     * @param _range uint of the position in the array of the specified range
     */
    modifier checkValidRange(uint256 _range) {
        require(_range >= 0 && _range < 9, "selected range not available");
        require(
            rangesCurrTokenId[_range] < maxSupplyPerRange[_range],
            "Can't mint more nfts for that range"
        );
        _;
    }

    /*
     * @param _zoothereumAddress address of deployed zoothereum contract
     * @param _mintedNfts array of tokenIds already minted in the main contract
     */
    constructor(address _zoothereumAddress, uint256[] memory _mintedNfts) {
        setMintedNfts(_mintedNfts);
        zoothereumContract = INFT(_zoothereumAddress);
    }

    /*
     * @notice Function to buy nft for a range
     * @param _range range of the nft to buy, must be a valid one
     */
    function buy(uint256 _range) external payable checkValidRange(_range) {
        uint256 tokenId = getTokenIdForRange(_range);

        (, uint256 price) = zoothereumContract.tokenTypeAndPrice(tokenId);
        require(msg.value >= price, "Invalid value sent");

        zoothereumContract.mint(msg.sender, tokenId);
    }

    /*
     * @notice get current valid tokenId for selected range to be minted
     * @param _range range to get tokenId for
     * @dev it will return tokenId to be minted, if range is completed reverts and updates rangeCurrTokenID
     */
    function getTokenIdForRange(uint256 _range)
        internal
        returns (uint256 _tokenId)
    {
        uint256 counter = rangesCurrTokenId[_range];

        while (
            mintedNfts[counter] && counter + 1 <= maxSupplyPerRange[_range]
        ) {
            unchecked {
                counter++;
            }

            if (mintedNfts[counter] && counter == maxSupplyPerRange[_range]) {
                rangesCurrTokenId[_range] = counter;
                revert("range completed, could not perform mint");
            }
        }

        rangesCurrTokenId[_range] = counter + 1;

        return counter;
    }

    /*
     * @notice funcion called by the constructor to set the snapShot of zooethereum contract
     * @param _mintedNfts array of tokenIds minted in zooethereum contract
     */
    function setMintedNfts(uint256[] memory _mintedNfts) internal {
        // Gas expensive funcition, would be nice to find a more efficient structure to store the
        // minted tokenIds
        for (uint256 i = 0; i < _mintedNfts.length; ) {
            mintedNfts[_mintedNfts[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    // TODO withdraw ether from contract

    function withdraw(address _reciever) external onlyOwner {
        (bool success, ) = _reciever.call{value: address(this).balance}("");
        require(success, "transaction not completed");
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