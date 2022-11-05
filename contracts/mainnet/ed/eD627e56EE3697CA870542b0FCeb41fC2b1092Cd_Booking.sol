// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Booking is Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private totalOffers;
    Counters.Counter private unavailableOffers;
    struct SellOffer {
        address payable seller;
        uint256 offerId;
        uint256 rdgCoinBalanceAmount;
        uint256 pricePerTokens;
    }
    mapping(uint256 => SellOffer) public sellOffers;
    IERC20 public rdgCoin;
    IERC20 public usdt;
    uint256 public listingFee = 0.001 ether;

    constructor(address _rdgCoin, address _usdt) {
        rdgCoin = IERC20(_rdgCoin);
        usdt = IERC20(_usdt);
    }

    event ChangeListingFee(uint256 amount);
    event RemovedAllOffers(address indexed owner);
    event RemovedOfferId(address indexed owner, uint256 offerId);
    event ListedOffer(
        address indexed owner,
        uint256 rdgAmount,
        uint256 unitPrice
    );
    event BoughtOffer(
        address indexed buyer,
        address indexed seller,
        uint256 buyingAmount,
        uint256 rdgPrice
    );
    event UpdatePriceOffer(
        address indexed owner,
        uint256 _offerId,
        uint256 oldRdgPrice,
        uint256 newRdgPrice
    );

    event AddRdgAmountOffer(
        address indexed owner,
        uint256 _offerId,
        uint256 oldAmount,
        uint256 newAmount
    );
    event RemoveRdgAmountOffer(
        address indexed owner,
        uint256 _offerId,
        uint256 oldAmount,
        uint256 newAmount
    );

    function setListingFee(uint256 _amount) public onlyOwner {
        listingFee = _amount;
        emit ChangeListingFee(_amount);
    }

    function widthdrawDevBalance() public onlyOwner {
        require(address(this).balance > 0, "Nao tem saldo disponivel");
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "Falha ao enviar ether");
    }

    function listToken(uint256 _amount, uint256 _pricePerTokens)
        public
        payable
        whenNotPaused
    {
        require(msg.value >= listingFee, "Nao foi enviado taxa de operacao.");
        require(_amount > 0, "Quantidade minima deve ser maior que zero");
        require(
            rdgCoin.allowance(msg.sender, address(this)) >= _amount,
            "Quantidade nao aprovada para listagem"
        );
        rdgCoin.transferFrom(msg.sender, address(this), _amount);
        totalOffers.increment();
        sellOffers[totalOffers.current()] = SellOffer({
            offerId: totalOffers.current(),
            pricePerTokens: _pricePerTokens,
            rdgCoinBalanceAmount: _amount,
            seller: payable(msg.sender)
        });
        emit ListedOffer(msg.sender, _amount, _pricePerTokens);
    }

    function buyToken(uint256 _offerId, uint256 _amount) public {
        SellOffer storage offer = sellOffers[_offerId];
        require(
            offer.seller != msg.sender,
            "Dono da oferta nao pode comprar suas proprias moedas."
        );
        uint256 payerPrice = (offer.pricePerTokens * _amount) / 1 ether;
        uint256 amountBased = _amount * (10**12);

        require(
            usdt.allowance(msg.sender, address(this)) >= payerPrice,
            "USDT autorizado insuficiente para realizar a compra"
        );
        require(
            offer.rdgCoinBalanceAmount >= amountBased,
            "Valor solicitado superior ao disponivel da oferta"
        );
        require(
            rdgCoin.balanceOf(address(this)) >= amountBased,
            "Contrato nao tem RDG Coin"
        );
        offer.rdgCoinBalanceAmount -= amountBased;
        usdt.transferFrom(msg.sender, offer.seller, payerPrice);
        rdgCoin.transfer(msg.sender, amountBased);
        if (offer.rdgCoinBalanceAmount == 0) {
            delete sellOffers[_offerId];
            unavailableOffers.increment();
        }
        emit BoughtOffer(
            msg.sender,
            offer.seller,
            _amount,
            offer.pricePerTokens
        );
    }

    function getOffers() public view returns (SellOffer[] memory) {
        uint256 totalListedOffers = totalOffers.current() -
            unavailableOffers.current();
        SellOffer[] memory offers = new SellOffer[](totalListedOffers);
        uint256 offerIndex;
        for (uint i = 0; i < totalOffers.current(); i++) {
            SellOffer storage offer = sellOffers[i + 1];
            if (offer.rdgCoinBalanceAmount > 0) {
                offers[offerIndex] = offer;
                offerIndex++;
            }
        }
        return offers;
    }

    function getMyOffers() public view returns (SellOffer[] memory) {
        uint256 totalListedOffers = totalOffers.current() -
            unavailableOffers.current();
        SellOffer[] memory offers = new SellOffer[](totalListedOffers);
        uint256 offerIndex;
        for (uint i = 0; i < totalOffers.current(); i++) {
            SellOffer storage offer = sellOffers[i + 1];
            if (offer.rdgCoinBalanceAmount > 0 && offer.seller == msg.sender) {
                offers[offerIndex] = offer;
                offerIndex++;
            }
        }
        return offers;
    }

    function updatePriceOffer(uint256 _offerId, uint256 _updatedPricePerToken)
        public
    {
        SellOffer storage offer = sellOffers[_offerId];

        require(
            offer.seller == msg.sender,
            "Oferta so pode ser modificada pelo dono"
        );
        emit UpdatePriceOffer(
            msg.sender,
            _offerId,
            offer.pricePerTokens,
            _updatedPricePerToken
        );
        offer.pricePerTokens = _updatedPricePerToken;
    }

    function removeListedRdgAmountOffer(uint256 _offerId, uint256 _tokenAmount)
        public
    {
        SellOffer storage offer = sellOffers[_offerId];
        require(
            offer.seller == msg.sender,
            "Oferta so pode ser modificada pelo dono"
        );

        require(
            rdgCoin.balanceOf(address(this)) >= _tokenAmount,
            "RDG Coin insuficiente no contrato"
        );
        uint256 oldAmount = offer.rdgCoinBalanceAmount;
        offer.rdgCoinBalanceAmount -= _tokenAmount;
        uint256 newAmount = offer.rdgCoinBalanceAmount;
        rdgCoin.transfer(msg.sender, _tokenAmount);

        emit RemoveRdgAmountOffer(msg.sender, _offerId, oldAmount, newAmount);

        if (offer.rdgCoinBalanceAmount == 0) {
            delete sellOffers[_offerId];
            unavailableOffers.increment();
        }
    }

    function removeListedOffers() public returns (SellOffer[] memory) {
        uint256 totalOffersCount = totalOffers.current() -
            unavailableOffers.current();
        uint256 rdgCoinIndex = 0;
        uint256 rdgCoinAmount = 0;

        SellOffer[] memory offers = new SellOffer[](totalOffersCount);

        for (uint256 i = 0; i < totalOffers.current(); i++) {
            SellOffer storage offer = sellOffers[i + 1];
            if (offer.seller == msg.sender && offer.rdgCoinBalanceAmount > 0) {
                unavailableOffers.increment();
                offers[rdgCoinIndex] = offer;
                rdgCoinAmount += offer.rdgCoinBalanceAmount;
                offer.rdgCoinBalanceAmount = 0;
                rdgCoinIndex++;
            }
        }

        require(
            rdgCoinAmount > 0,
            "Nao tem nehuma oferta com saldo para saque"
        );
        require(
            rdgCoin.balanceOf(address(this)) >= rdgCoinAmount,
            "Saldo insuficiente do contrato"
        );
        rdgCoin.transfer(msg.sender, rdgCoinAmount);
        emit RemovedAllOffers(msg.sender);
        return offers;
    }

    function removeListedIdOffer(uint _offerId) public {
        SellOffer storage offer = sellOffers[_offerId];
        require(
            offer.seller == msg.sender,
            "Oferta so pode ser removida pelo dono"
        );
        unavailableOffers.increment();
        uint256 rdgCoinGiveBack = offer.rdgCoinBalanceAmount;
        require(
            rdgCoin.balanceOf(address(this)) >= rdgCoinGiveBack,
            "Saldo insuficiente no contrato"
        );
        offer.rdgCoinBalanceAmount = 0;
        delete sellOffers[_offerId];
        rdgCoin.transfer(msg.sender, rdgCoinGiveBack);
        emit RemovedOfferId(msg.sender, _offerId);
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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