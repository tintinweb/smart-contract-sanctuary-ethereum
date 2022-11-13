// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BoaxMarketplaceState is Ownable {
    address private boaxMarketplace; // require to in contract to check state update
    address private boaxEnglishAuction; // require to in contract to check state update
    address payable private _feeAccount; // marketplace fee account (EOA)
    // uint24 private _artistFee; // fee (profits) on all secondary sales paid to the artist

    mapping(uint256 => uint24) private tokenIdToArtistFee;
    uint24 private _marketplaceFee; // fee of marketplace for trading NFT
    mapping(uint256 => bool) private secondarySale; // map token Id to bool indicating wether it has been sold before

    mapping(uint256 => address) public artists; // token Id to artist mapping, used for sending fees to artist on secondary sales

    modifier onlyContracts() {
        require(
            msg.sender == boaxMarketplace || msg.sender == boaxEnglishAuction,
            "not allowed"
        );
        _;
    }

    /**
     * @dev updates the royaltiesFee for given token
     * @param _tokenId is the id of the token to update
     * @param _fee is the new royaltiesFee for token
     */
    function modifyTokenRoyalities(uint256 _tokenId, uint24 _fee) external {
        require(msg.sender == boaxMarketplace, "not allowed");
        tokenIdToArtistFee[_tokenId] = _fee;
    }

    /**
     * @notice  only either auction or marketplace contract can call it to set tokenId as secondary sale.
     * @param _tokenId boaxerc721 NFTs' tokenId
     *
     */
    function setSecondarySale(uint256 _tokenId) external onlyContracts {
        secondarySale[_tokenId] = true;
    }

    /**
     * @notice  only either auction or marketplace contract can call it to set tokenId to artist.
     * @param _tokenId boaxerc721 NFTs' tokenId
     * @param _artist is the NFT token creator
     *
     */
    function setTokenInfo(
        uint256 _tokenId,
        address _artist,
        uint24 _artistFee
    ) external onlyContracts {
        // solhint-disable-next-line
        require(_artist != address(0));
        artists[_tokenId] = _artist;

        if (_artistFee == 0) {
            // if artist does not selects the artsit fee make the default 5%
            _artistFee = 500;
        }

        tokenIdToArtistFee[_tokenId] = _artistFee;
    }

    /**
     * @notice setter function only callable by contract admin used to change the address to which fees are paid
     * @param feeAccount is the address owned by marketplace that will collect sales fees
     */
    function setFeeAccount(address payable feeAccount) external onlyOwner {
        _feeAccount = feeAccount;
    }

    /**
     * @notice setter function only callable by contract admin used to update Royality
     * @param _fee   bps (basic points). it is in bps i.e (1% = 100bps)
     */
    function setMarketplaceFee(uint24 _fee) external onlyOwner {
        // solhint-disable-next-line
        require(_fee > 0); // new fee should be more than 0
        _marketplaceFee = _fee;
    }

    // /**
    //  * @notice setter function only callable by contract admin used to update Royality for artists
    //  * @param _fee is the new bps (basic points) for NFT's artist. it is in bps i.e (1% = 100bps)
    //  */
    // function setSecondarySaleFeeArtist(uint24 _fee) external onlyOwner {
    //     // solhint-disable-next-line
    //     require(_fee > 0); // new fee should be more than 0
    //     _artistFee = _fee;
    // }

    /**
     * @notice setter function only callable by contract admin used to update marketplace and auction contract addresses
     * @param _boaxMarketplace address of boax marketplace contract
     * @param _boaxEnglishAuction address of boax english auction contract
     */
    function setContractAddresses(
        address _boaxMarketplace,
        address _boaxEnglishAuction
    ) external onlyOwner {
        require(
            address(0) != _boaxMarketplace && address(0) != _boaxEnglishAuction,
            "addresses cannot be null"
        );

        boaxMarketplace = _boaxMarketplace;
        boaxEnglishAuction = _boaxEnglishAuction;
    }

    // /**
    //  * @dev it will calcuate the new bps fee limit. it should be less than or equal to 9000. if the limit is set to 100% for both fees than the trade function in marketplace and auction will fail due to overflow
    //  */
    // function _feeLimit(uint24 _x, uint24 _y) internal pure returns (bool) {
    //     uint24 total = _x + _y;
    //     if (total > 9001) return false;
    //     return true;
    // }

    /*****************************/
    /****** View Functions *******/
    /*****************************/

    function getStateInfo(uint256 tokenId)
        external
        view
        returns (
            address feeAccount,
            bool isSecondarySale,
            uint24 artistFee,
            uint24 marketplaceFee,
            address artist
        )
    {
        feeAccount = _feeAccount;
        isSecondarySale = secondarySale[tokenId];
        artistFee = tokenIdToArtistFee[tokenId];
        marketplaceFee = _marketplaceFee;
        artist = artists[tokenId];
    }

    constructor(address feeAccount) {
        // solhint-disable-next-line
        require(address(0) != feeAccount);
        _feeAccount = payable(feeAccount); // account or contract that can redeem funds from fees.
        _marketplaceFee = 1000; // 10% fee on all sales paid to  (artist receives the remainder, 90%)
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