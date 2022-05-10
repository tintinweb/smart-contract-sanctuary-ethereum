/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/app/constant/ErrorType.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

error ZeroAddress();
error ZeroAmount();
error ZeroSize();
error ZeroBalance();
error ZeroTime();
error ZeroPayment();
error ExistentToken();
error NonexistentToken();
error LengthMismatch();
error NotAdmin();
error NotOwner();
error NotUser();
error NotMinter();
error IncorrectOwner();
error SameAddress();
error InvalidState();
error NotOwnerNorApproved();
error ToCurrentOwner();
error MustGreaterThan(uint256 value);
error MustLessThan(uint256 value);
error Insufficient();
error Overflows();
error AmountExceeds();
error TimeNotYet();
error IndexOutOfBounds();

contract ErrorType {}


// File contracts/app/access/IAdminable.sol


pragma solidity ^0.8.12;

interface IAdminable {
    /**
     * @dev
     */    
    function setAdmin(address newAdmin) external;

    /**
     * @dev
     */    
    function setMinter(address newMinter) external;

}


// File contracts/app/access/Adminable.sol


pragma solidity ^0.8.12;
contract Adminable is IAdminable {
    address private _admin;
    address private _minter;

    constructor() {
        _admin = msg.sender;
        _minter = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        // require(_admin == msg.sender, "Ownable: caller is not the owner");
        if (msg.sender != _admin) revert NotAdmin();
        _;
    }

    modifier onlyMinter() {
        if (msg.sender != _minter) revert NotMinter();
        _;
    }    

    function setAdmin(address newAdmin) external override onlyAdmin {
        // require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setAdmin(newAdmin);
    }

    function _setAdmin(address newAdmin) internal virtual {
        // require(newOwner != address(0), "Ownable: new owner is the zero address");
        if (newAdmin == address(0)) revert ZeroAddress();
        _admin = newAdmin;
    }

    function setMinter(address newMinter) external override onlyAdmin {
        _setMinter(newMinter);
    }

    function _setMinter(address newMinter) internal virtual {
        _minter = newMinter;
    }        
}


// File contracts/app/royalty/RoyaltyContract.sol


pragma solidity ^0.8.12;
// import "hardhat/console.sol";

contract RoyaltyContract is Adminable {
    string private _name;
    string private _symbol;
    uint96 private _denominator = 10000;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;

    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    constructor(
        string memory name_,
        string memory symbol_,
        uint96 denominator_,
        address receiver_,
        uint96 feeNumerator_
    ) {
        _setAdmin(msg.sender);
        _name = name_;
        _symbol = symbol_;
        _denominator = denominator_;
        //
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal view virtual returns (uint96) {
        return _denominator;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator)
        internal
        virtual
    {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        // require(receiver != address(0), "ERC2981: invalid receiver");
        if (receiver == address(0)) revert ZeroAddress();

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyAdmin
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    function deleteDefaultRoyalty() external onlyAdmin {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        // require(receiver != address(0), "ERC2981: Invalid parameters");
        if (receiver == address(0)) revert ZeroAddress();

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyAdmin {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setTokenRoyaltyBatch(
        uint256[] memory tokenIds,
        address receiver,
        uint96 feeNumerator
    ) external onlyAdmin {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _setTokenRoyalty(tokenIds[i], receiver, feeNumerator);
        }
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyAdmin {
        _resetTokenRoyalty(tokenId);
    }

    function resetTokenRoyaltyBatch(uint256[] memory tokenIds)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _resetTokenRoyalty(tokenIds[i]);
        }
    }
}