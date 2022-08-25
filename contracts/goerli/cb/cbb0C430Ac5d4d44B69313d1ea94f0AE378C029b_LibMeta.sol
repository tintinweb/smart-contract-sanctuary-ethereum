// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./LibShare.sol";

library LibMeta {

    struct TokenMeta {
        uint256 saleId;
        address collectionAddress;
        uint256 tokenId;
        uint256 price;
        bool directSale;
        bool bidSale;
        bool status;
        uint256 bidStartTime;
        uint256 bidEndTime;
        address currentOwner;
        address currency;
    }

   function transfer(TokenMeta storage token, address _to ) external{
        token.currentOwner = _to;
        token.status = false;
        token.directSale = false ;
        token.bidSale = false ;

    } 

    function checkSale(TokenMeta storage token, address caller, uint256 amount) external view {
        require(token.status);
        require(caller != address(0) && caller != token.currentOwner);
        require(!token.bidSale);
        if(token.currency == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || token.currency == address(0)) {
            require(amount >= token.price);
        }
        else {
            require(IERC20Upgradeable(token.currency).balanceOf(caller) >= token.price);
        }
    }

    function executeSale(TokenMeta storage meta, LibShare.Share[] memory _royalties, uint256 msgamount, address owner) external {
        if(meta.currency == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || meta.currency == address(0)) {
            uint256 sum = msgamount;
            uint256 val = msgamount;

            for (uint256 i = 0; i < _royalties.length; i++) {
                uint256 amount = (_royalties[i].value * val) / 10000;
                sum = sum - amount;
                // address payable receiver = royalties[i].account;
                (bool royalSuccess, ) = payable(_royalties[i].account).call{ value: amount }("");
                require(royalSuccess, "Transfer failed");
            }

            (bool isSuccess, ) = payable(owner).call{ value: (sum) }("");
            require(isSuccess, "Transfer failed");
        }
        else {
            uint256 sum = meta.price;
            uint256 val = meta.price;

            for (uint256 i = 0; i < _royalties.length; i++) {
                uint256 amount = (_royalties[i].value * val) / 10000;
                sum = sum - amount;
                // address payable receiver = royalties[i].account;
                (bool royalSuccess) = IERC20Upgradeable(meta.currency).transferFrom(msg.sender, _royalties[i].account, amount);
                require(royalSuccess, "Transfer failed");
            }

            (bool isSuccess) = IERC20Upgradeable(meta.currency).transferFrom(msg.sender, meta.currentOwner, sum);
            require(isSuccess, "Transfer failed");
        }
    }

    function send(address _to, uint256 amount) external {
        (bool royalSuccess, ) = payable(_to).call{ value: amount }("");
        require(royalSuccess, "Transfer failed");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

library LibShare {
    // Defines the share of royalties for the address
    struct Share {
        address payable account;
        uint96 value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}