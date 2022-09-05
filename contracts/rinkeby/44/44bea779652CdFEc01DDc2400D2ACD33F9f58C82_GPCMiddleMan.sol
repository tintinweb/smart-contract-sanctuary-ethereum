// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface.sol";

contract GPCMiddleMan is Ownable {
    address panda3;
    address giftShop;
    address gpcHolderAddress;
    IERC20 GPCToken;
    IPandaNFT panda3SC;
    IPandaNFT giftShopSC;

    constructor(
        address _panda3,
        address _giftshop,
        address _gpcTokenAddress,
        address _gpcHolderAddress
    ) {
        panda3 = _panda3;
        giftShop = _giftshop;
        GPCToken = IERC20(_gpcTokenAddress);
        gpcHolderAddress = _gpcHolderAddress;
        panda3SC = IPandaNFT(panda3);
        giftShopSC = IPandaNFT(giftShop);
    }

    function mintPanda3(uint256[] memory tokenIds) private {
        uint256 totalGPC = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 idToMint = (1500 + tokenIds[i]);
            require(
                panda3SC.getMintTime(idToMint) == 0,
                string(
                    abi.encodePacked(
                        "Token ID ",
                        Strings.toString(idToMint),
                        " Already Minted"
                    )
                )
            );

            uint256 cost = panda3SC.getCost(idToMint);
            require(
                cost > 0,
                string(
                    abi.encodePacked(
                        "Cost of token ",
                        Strings.toString(idToMint),
                        "  not set"
                    )
                )
            );

            totalGPC += cost;
        }

        GPCToken.transferFrom(msg.sender, gpcHolderAddress, totalGPC);
        panda3SC.mint(tokenIds, msg.sender);
    }

    function mintShopItem(uint256[] memory tokenIds, uint256[] memory amounts)
        private
    {
        uint256 totalGPC = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 token_id = tokenIds[i];
            uint256 cost = giftShopSC.getPrices(token_id);

            require(cost > 0, "Token ID does not exist");

            uint256 totalSupply = giftShopSC.getSupply(token_id);
            uint256 totalMinted = giftShopSC.getMintedQuantity(token_id);
            uint256 balanceLeft = totalSupply - totalMinted;
            
            require(
                balanceLeft > 0,
                "No more supply. Purchase from secondary market"
            );

            require(amounts[i] <= balanceLeft, "Cannot mint more than supply");

            totalGPC += cost;
        }

        GPCToken.transferFrom(msg.sender, gpcHolderAddress, totalGPC);

        giftShopSC.mint(tokenIds, amounts, msg.sender);
    }

    function checkOut(
        uint256[] memory shopItems,
        uint256[] memory shopItemAmounts,
        uint256[] memory pandaIds
    ) public {
        if (shopItems.length > 0) {
            require(
                shopItems.length == shopItemAmounts.length,
                "Shop item IDS and Amounts length have to match"
            );
            mintShopItem(shopItems, shopItemAmounts);
        }

        if (pandaIds.length > 0) {
            mintPanda3(pandaIds);
        }
    }

    function setGPCTokenAddress(address _gpcTokenAddress)
        public
        virtual
        onlyOwner
    {
        GPCToken = IERC20(_gpcTokenAddress);
    }

    function setPandaContract(address _panda3) external onlyOwner {
        panda3 = _panda3;
        panda3SC = IPandaNFT(panda3);
    }

    function setGPCHolder(address _gpcHolderAddress) external onlyOwner {
        gpcHolderAddress = _gpcHolderAddress;
    }

    function setGSContract(address _giftshop) external onlyOwner {
        giftShop = _giftshop;
        giftShopSC = IPandaNFT(giftShop);
    }

    function withdraw() public onlyOwner {
        GPCToken.transfer(msg.sender, GPCToken.balanceOf(address(this)));
    }

    function withdrawEth() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

interface IPandaNFT {
    function mint(
        uint256[] memory token_ids,
        uint256[] memory quantities,
        address sender
    ) external;

    function mint(uint256[] memory token_ids, address sender) external payable;

    function getCost(uint256 token_id) external returns (uint256);

    function getPrices(uint256 token_id) external returns (uint256);

    function getSupply(uint256 token_id) external returns (uint256);

    function getRemainingBalance(uint256 token_id) external returns (uint256);

    function getMintTime(uint256 _tokenId) external returns (uint256);
    
    function getMintedQuantity(uint256 token_id) external returns (uint256);

    
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