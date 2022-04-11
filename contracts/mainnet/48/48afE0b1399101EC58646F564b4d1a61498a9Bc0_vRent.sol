// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../ERCX/Interface/IERCX.sol";
import "../ERCX/Contract/ERCX.sol";

import "./IPayment.sol";
import "./IvRent.sol";

contract vRent is IvRent, ERC721Holder {
    using SafeERC20 for ERC20;

    IPayment private payment;
    address private admin;
    address payable private beneficiary;
    uint256 private leasingId = 1;
    bool public paused = false;
    IERCX _ERCX;
    ERCX ERCXImp;

    // in bps. so 1000 => 1%
    uint256 public rentFee = 0;

    uint256 private constant SECONDS_IN_DAY = 86400;

    struct Leasing {
        address payable leaserAddress;
        uint8 maxLeaseDuration;
        bytes4 dailyLeasePrice;
        IPayment.PaymentToken paymentToken;
    }

    // single storage slot: 160 bits, 168, 200
    struct Renting {
        address payable renterAddress;
        uint8 rentDuration;
        uint32 rentedAt;
    }

    struct LeasingRenting {
        Leasing Leasing;
        Renting renting;
    }

    mapping(bytes32 => LeasingRenting) private leasingRenting;

    struct CallData {
        address[] nfts;
        uint256[] tokenIds;
        uint8[] maxLeaseDurations;
        bytes4[] dailyLeasePrices;
        uint256[] leasingIds;
        uint8[] rentDurations;
        IPayment.PaymentToken[] paymentTokens;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "vRent::not admin");
        _;
    }

    modifier notPaused() {
        require(!paused, "vRent::paused");
        _;
    }

    constructor(
        address _payment,
        address payable _beneficiary,
        address _admin,
        ERCX ERCX_
    ) {
        _verifyIsNotZeroAddr(_payment);
        _verifyIsNotZeroAddr(_beneficiary);
        _verifyIsNotZeroAddr(_admin);
        payment = IPayment(_payment);
        beneficiary = _beneficiary;
        admin = _admin;
        _ERCX = ERCX_;
        ERCXImp = ERCX_;
    }

    function bundleCall(function(CallData memory) _manager, CallData memory _cd)
        private
    {
        require(_cd.nfts.length > 0, "vRent::no nfts");
        _manager(_cd);
    }

    /**
     * @dev user Lease the nft for earning.
     *
     * Emits an {Lent} event indicating the nft is Leaseed by Leaser.
     *
     * Requirements:
     *
     * - the caller must have allowance for `_tokenIds`'s tokens of at least
     * `_tokenAmounts`.
     * - the caller must have a balance of at least `_tokenAmounts`.
     * - `_dailyLeasePrices` should be between 9999.9999 and 0.0001
     */
    function lease(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint8[] memory _maxLeaseDurations,
        bytes4[] memory _dailyLeasePrices,
        IPayment.PaymentToken[] memory _paymentTokens
    ) external override notPaused {
        bundleCall(
            manageLease,
            _createLeaseCallData(
                _nfts,
                _tokenIds,
                _maxLeaseDurations,
                _dailyLeasePrices,
                _paymentTokens
            )
        );
    }

    /**
     * @dev See {IvRent-rent}.
     *
     * Emits an {Rented} event indicating the nft is rented by renter.
     *
     * Requirements:
     *
     * - caller must have a balance of at least daily rent + collateral amount.
     * - the caller must have allowance for PaymentToken's tokens of at least
     *   dailyLeasePrice + collateral amount.
     */
    function rentNFT(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint256[] memory _leasingIds,
        uint8[] memory _rentDurations
    ) external override notPaused {
        bundleCall(
            manageRent,
            _createRentCallData(_nfts, _tokenIds, _leasingIds, _rentDurations)
        );
    }

    /**
     * @dev renter returns NFT to vRent contract
     *
     * Emits an {Returned} event indicating the nft returned from renter to contract.
     *
     * Requirements:
     *
     * - caller cannot be the zero address.
     * - caller must have a balance of `_tokenIds`.
     */
    function endRent(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint256[] memory _leasingIds
    ) external override notPaused {
        bundleCall(
            manageReturn,
            _createActionCallData(_nfts, _tokenIds, _leasingIds)
        );
    }

    /**
     * @dev Leaser gets his nft back from vRent
     *
     * Emits an {LeasingStopped} event indicating nft Leasing stopped.
     *
     * Requirements:
     *
     * - caller cannot be the zero address.
     * - caller must be the one who Leaseed nft.
     */
    function cancelLeasing(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint256[] memory _leasingIds
    ) external override notPaused {
        bundleCall(
            manageStopLeasing,
            _createActionCallData(_nfts, _tokenIds, _leasingIds)
        );
    }

    // -------------------------------------------------------------------------

    /**
     * deduct the platform fee and transfer it to `beneficiary` address
     */

    function takeFee(uint256 _rent, IPayment.PaymentToken _paymentToken)
        private
        returns (uint256 fee)
    {
        fee = _rent * rentFee;
        fee /= 10000;
        uint8 paymentTokenIx = uint8(_paymentToken);
        verifyTokenNotSentinel(paymentTokenIx);
        ERC20 paymentToken = ERC20(payment.getPaymentToken(paymentTokenIx));
        paymentToken.safeTransfer(beneficiary, fee);
    }

    //   distribute payments
    function distributePayments(
        LeasingRenting storage _LeasingRenting,
        uint256 _secondsSinceRentStart
    ) private {
        uint8 paymentTokenIx = uint8(_LeasingRenting.Leasing.paymentToken);
        verifyTokenNotSentinel(paymentTokenIx);
        address paymentToken = payment.getPaymentToken(paymentTokenIx);
        uint256 decimals = ERC20(paymentToken).decimals();

        uint256 scale = 10**decimals;
        uint256 rentPrice = _unwrapPrice(
            _LeasingRenting.Leasing.dailyLeasePrice,
            scale
        );
        uint256 totalRenterPmtWoCollateral = rentPrice *
            _LeasingRenting.renting.rentDuration;
        uint256 sendLeaserAmt = (_secondsSinceRentStart * rentPrice) /
            SECONDS_IN_DAY;
        require(
            totalRenterPmtWoCollateral > 0,
            "vRent::total payment wo collateral is zero"
        );
        require(sendLeaserAmt > 0, "vRent::Leaser payment is zero");
        uint256 sendRenterAmt = totalRenterPmtWoCollateral - sendLeaserAmt;

        uint256 takenFee = takeFee(
            sendLeaserAmt,
            _LeasingRenting.Leasing.paymentToken
        );

        sendLeaserAmt -= takenFee;

        ERC20(paymentToken).safeTransfer(
            _LeasingRenting.Leasing.leaserAddress,
            sendLeaserAmt
        );
        ERC20(paymentToken).safeTransfer(
            _LeasingRenting.renting.renterAddress,
            sendRenterAmt
        );
    }

    // -------------------------------------------------------------------------
    function manageLease(CallData memory _cd) private {
        for (uint256 i = 0; i < _cd.nfts.length; i++) {
            _verifyIsLeaseable(_cd, i);

            LeasingRenting storage item = leasingRenting[
                keccak256(
                    abi.encodePacked(_cd.nfts[i], _cd.tokenIds[i], leasingId)
                )
            ];

            _verifyIsNull(item.Leasing);
            _verifyIsNull(item.renting);

            item.Leasing = Leasing({
                leaserAddress: payable(msg.sender),
                maxLeaseDuration: _cd.maxLeaseDurations[i],
                dailyLeasePrice: _cd.dailyLeasePrices[i],
                paymentToken: _cd.paymentTokens[i]
            });

            emit Leased(
                _cd.nfts[i],
                _cd.tokenIds[i],
                leasingId,
                msg.sender,
                _cd.maxLeaseDurations[i],
                _cd.dailyLeasePrices[i],
                _cd.paymentTokens[i]
            );

            // set lien
            _ERCX.setLien(leasingId);
            IERC721(_cd.nfts[i]).transferFrom(
                msg.sender,
                address(this),
                _cd.tokenIds[i]
            );
            leasingId++;
        }
    }

    function manageRent(CallData memory _cd) private {
        for (uint256 i = 0; i < _cd.nfts.length; i++) {
            LeasingRenting storage item = leasingRenting[
                keccak256(
                    abi.encodePacked(
                        _cd.nfts[i],
                        _cd.tokenIds[i],
                        _cd.leasingIds[i]
                    )
                )
            ];

            _verifyIsNotNull(item.Leasing);
            _verifyIsNull(item.renting);
            _verifyIsRentable(item.Leasing, _cd, i, msg.sender);

            uint8 paymentTokenIx = uint8(item.Leasing.paymentToken);
            verifyTokenNotSentinel(paymentTokenIx);
            address paymentToken = payment.getPaymentToken(paymentTokenIx);
            uint256 decimals = ERC20(paymentToken).decimals();

            {
                uint256 scale = 10**decimals;
                uint256 rentPrice = _cd.rentDurations[i] *
                    _unwrapPrice(item.Leasing.dailyLeasePrice, scale);

                require(rentPrice > 0, "vRent::rent price is zero");

                ERC20(paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    rentPrice
                );
            }

            item.renting.renterAddress = payable(msg.sender);
            item.renting.rentDuration = _cd.rentDurations[i];
            item.renting.rentedAt = uint32(block.timestamp);

            emit Rented(
                _cd.leasingIds[i],
                msg.sender,
                _cd.rentDurations[i],
                item.renting.rentedAt
            );
            // transfer user ownership 2615
            _ERCX.safeTransferUser(admin, msg.sender, _cd.leasingIds[i]);
        }
    }

    function manageReturn(CallData memory _cd) private {
        for (uint256 i = 0; i < _cd.nfts.length; i++) {
            LeasingRenting storage item = leasingRenting[
                keccak256(
                    abi.encodePacked(
                        _cd.nfts[i],
                        _cd.tokenIds[i],
                        _cd.leasingIds[i]
                    )
                )
            ];

            _verifyIsNotNull(item.Leasing);
            _verifyIsReturnable(item.renting, msg.sender, block.timestamp);

            uint256 secondsSinceRentStart = block.timestamp -
                item.renting.rentedAt;
            distributePayments(item, secondsSinceRentStart);

            emit Returned(_cd.leasingIds[i], uint32(block.timestamp));

            delete item.renting;

            // transfer user role back to owner
            _ERCX.safeTransferUser(msg.sender, admin, _cd.leasingIds[i]);
        }
    }

    function manageStopLeasing(CallData memory _cd) private {
        for (uint256 i = 0; i < _cd.nfts.length; i++) {
            LeasingRenting storage item = leasingRenting[
                keccak256(
                    abi.encodePacked(
                        _cd.nfts[i],
                        _cd.tokenIds[i],
                        _cd.leasingIds[i]
                    )
                )
            ];

            _verifyIsNotNull(item.Leasing);
            _verifyIsNull(item.renting);
            _verifyIsStoppable(item.Leasing, msg.sender);

            emit LeasingStopped(_cd.leasingIds[i], uint32(block.timestamp));

            delete item.Leasing;
            // revoke lien
            _ERCX.revokeLien(_cd.leasingIds[i]);
            IERC721(_cd.nfts[i]).transferFrom(
                address(this),
                msg.sender,
                _cd.tokenIds[i]
            );
        }
    }

    function _createLeaseCallData(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint8[] memory _maxLeaseDurations,
        bytes4[] memory _dailyLeasePrices,
        IPayment.PaymentToken[] memory _paymentTokens
    ) private pure returns (CallData memory cd) {
        cd = CallData({
            nfts: _nfts,
            tokenIds: _tokenIds,
            leasingIds: new uint256[](0),
            rentDurations: new uint8[](0),
            maxLeaseDurations: _maxLeaseDurations,
            dailyLeasePrices: _dailyLeasePrices,
            paymentTokens: _paymentTokens
        });
    }

    function _createRentCallData(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint256[] memory _leasingIds,
        uint8[] memory _rentDurations
    ) private pure returns (CallData memory cd) {
        cd = CallData({
            nfts: _nfts,
            tokenIds: _tokenIds,
            leasingIds: _leasingIds,
            rentDurations: _rentDurations,
            maxLeaseDurations: new uint8[](0),
            dailyLeasePrices: new bytes4[](0),
            paymentTokens: new IPayment.PaymentToken[](0)
        });
    }

    function _createActionCallData(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint256[] memory _leasingIds
    ) private pure returns (CallData memory cd) {
        cd = CallData({
            nfts: _nfts,
            tokenIds: _tokenIds,
            leasingIds: _leasingIds,
            rentDurations: new uint8[](0),
            maxLeaseDurations: new uint8[](0),
            dailyLeasePrices: new bytes4[](0),
            paymentTokens: new IPayment.PaymentToken[](0)
        });
    }

    /**
     * convert the `dailyLeasePrices` from bytes4 into decimal
     */
    function _unwrapPrice(bytes4 _price, uint256 _scale)
        private
        pure
        returns (uint256)
    {
        _verifyIsUnwrapablePrice(_price, _scale);

        uint16 whole = uint16(bytes2(_price));
        uint16 decimal = uint16(bytes2(_price << 16));
        uint256 decimalScale = _scale / 10000;

        if (whole > 9999) {
            whole = 9999;
        }
        if (decimal > 9999) {
            decimal = 9999;
        }

        uint256 w = whole * _scale;
        uint256 d = decimal * decimalScale;
        uint256 price = w + d;

        return price;
    }

    // -------------------------------------------------------------------------

    /**
     * verify whether caller is zero aaddress or not
     */
    function _verifyIsNotZeroAddr(address _addr) private pure {
        require(_addr != address(0), "vRent::zero address");
    }

    function _verifyIsZeroAddr(address _addr) private pure {
        require(_addr == address(0), "vRent::not a zero address");
    }

    function _verifyIsNull(Leasing memory _Leasing) private pure {
        _verifyIsZeroAddr(_Leasing.leaserAddress);
        require(_Leasing.maxLeaseDuration == 0, "vRent::duration not zero");
        require(_Leasing.dailyLeasePrice == 0, "vRent::rent price not zero");
    }

    function _verifyIsNotNull(Leasing memory _Leasing) private pure {
        _verifyIsNotZeroAddr(_Leasing.leaserAddress);
        require(_Leasing.maxLeaseDuration != 0, "vRent::duration zero");
        require(_Leasing.dailyLeasePrice != 0, "vRent::rent price is zero");
    }

    function _verifyIsNull(Renting memory _renting) private pure {
        _verifyIsZeroAddr(_renting.renterAddress);
        require(_renting.rentDuration == 0, "vRent::duration not zero");
        require(_renting.rentedAt == 0, "vRent::rented at not zero");
    }

    function _verifyIsNotNull(Renting memory _renting) private pure {
        _verifyIsNotZeroAddr(_renting.renterAddress);
        require(_renting.rentDuration != 0, "vRent::duration is zero");
        require(_renting.rentedAt != 0, "vRent::rented at is zero");
    }

    /**
     * verify whether the duration is between the range else user can't Lease nft
     */
    function _verifyIsLeaseable(CallData memory _cd, uint256 _i) private pure {
        require(_cd.maxLeaseDurations[_i] > 0, "vRent::duration is zero");
        require(
            _cd.maxLeaseDurations[_i] <= type(uint8).max,
            "vRent::not uint8"
        );
        require(
            uint32(_cd.dailyLeasePrices[_i]) > 0,
            "vRent::rent price is zero"
        );
    }

    /**
     * verifys the rent duration provided by user
     */
    function _verifyIsRentable(
        Leasing memory _Leasing,
        CallData memory _cd,
        uint256 _i,
        address _msgSender
    ) private pure {
        require(
            _msgSender != _Leasing.leaserAddress,
            "vRent::cant rent own nft"
        );
        require(_cd.rentDurations[_i] <= type(uint8).max, "vRent::not uint8");
        require(_cd.rentDurations[_i] > 0, "vRent::duration is zero");
        require(
            _cd.rentDurations[_i] <= _Leasing.maxLeaseDuration,
            "vRent::rent duration exceeds allowed max"
        );
    }

    /**
     * @dev compare the timestamp and return time and returns
     * whether the NFT is returnable or not
     */
    function _verifyIsReturnable(
        Renting memory _renting,
        address _msgSender,
        uint256 _blockTimestamp
    ) private pure {
        require(_renting.renterAddress == _msgSender, "vRent::not renter");
        require(
            !_isPastReturnDate(_renting, _blockTimestamp),
            "vRent::past return date"
        );
    }

    function _verifyIsStoppable(Leasing memory _Leasing, address _msgSender)
        private
        pure
    {
        require(_Leasing.leaserAddress == _msgSender, "vRent::not Leaser");
    }

    function _verifyIsClaimable(
        Renting memory _renting,
        uint256 _blockTimestamp
    ) private pure {
        require(
            _isPastReturnDate(_renting, _blockTimestamp),
            "vRent::return date not passed"
        );
    }

    function _verifyIsUnwrapablePrice(bytes4 _price, uint256 _scale)
        private
        pure
    {
        require(uint32(_price) > 0, "vRent::invalid price");
        require(_scale >= 10000, "vRent::invalid scale");
    }

    function verifyTokenNotSentinel(uint8 _paymentIx) private pure {
        require(_paymentIx > 0, "vRent::token is sentinel");
    }

    function _isPastReturnDate(Renting memory _renting, uint256 _now)
        private
        pure
        returns (bool)
    {
        require(_now > _renting.rentedAt, "vRent::now before rented");
        return
            _now - _renting.rentedAt > _renting.rentDuration * SECONDS_IN_DAY;
    }

    // -------------------------------------------------------------------------

    /**
     * @dev only Admin can call this function
     * set the platform `rentFee`
     * `+_rentFee` should be less than 100%
     */
    function setRentFee(uint256 _rentFee) external onlyAdmin {
        require(_rentFee < 10000, "vRent::fee exceeds 100pct");
        rentFee = _rentFee;
    }

    /**
     * @dev only admin can call this function
     * replaces the `beneficiary` address to `+_newBeneficiary`
     */
    function setBeneficiary(address payable _newBeneficiary)
        external
        onlyAdmin
    {
        beneficiary = _newBeneficiary;
    }

    /**
     * admin can pause the Lease, rent, returnit or claimCollateral functions
     */
    function setPaused(bool _paused) external onlyAdmin {
        paused = _paused;
    }

    function getleasingId() external view returns (uint256) {
        return leasingId;
    }

    function getLeasing(
        address nft,
        uint256 tokenId,
        uint256 LeaseId
    ) external view returns (Leasing memory) {
        return
            leasingRenting[keccak256(abi.encodePacked(nft, tokenId, LeaseId))]
                .Leasing;
    }

    function getRenting(
        address nft,
        uint256 tokenId,
        uint256 LeaseId
    ) external view returns (Renting memory) {
        return
            leasingRenting[keccak256(abi.encodePacked(nft, tokenId, LeaseId))]
                .renting;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: un-licensed
pragma solidity ^0.8.0;

interface IERCX {
    event TransferUser(
        address indexed from,
        address indexed to,
        uint256 indexed itemId,
        address operator
    );
    event ApprovalForUser(
        address indexed user,
        address indexed approved,
        uint256 itemId
    );
    event TransferOwner(
        address indexed from,
        address indexed to,
        uint256 indexed itemId,
        address operator
    );
    event ApprovalForOwner(
        address indexed owner,
        address indexed approved,
        uint256 itemId
    );
    event LienApproval(address indexed to, uint256 indexed itemId);
    event TenantRightApproval(address indexed to, uint256 indexed itemId);
    event LienSet(address indexed to, uint256 indexed itemId, bool status);
    event TenantRightSet(
        address indexed to,
        uint256 indexed itemId,
        bool status
    );

    function balanceOfOwner(address owner) external view returns (uint256);

    function balanceOfUser(address user) external view returns (uint256);

    function userOf(uint256 itemId) external view returns (address);

    function ownerOf(uint256 itemId) external view returns (address);

    function safeTransferOwner(address from, address to, uint256 itemId) external;
    function safeTransferOwner(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) external;

    function safeTransferUser(address from, address to, uint256 itemId) external;
    function safeTransferUser(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) external;

    function approveForOwner(address to, uint256 itemId) external;
    function getApprovedForOwner(uint256 itemId) external view returns (address);

    function approveForUser(address to, uint256 itemId) external;
    function getApprovedForUser(uint256 itemId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address requester, address operator)
        external
        view
        returns (bool);

    function approveLien(address to, uint256 itemId) external;
    function getApprovedLien(uint256 itemId) external view returns (address);
    function setLien(uint256 itemId) external;
    function getCurrentLien(uint256 itemId) external view returns (address);
    function revokeLien(uint256 itemId) external;

    function approveTenantRight(address to, uint256 itemId) external;
    function getApprovedTenantRight(uint256 itemId)
        external
        view
        returns (address);
    function setTenantRight(uint256 itemId) external;
    function getCurrentTenantRight(uint256 itemId)
        external
        view
        returns (address);
    function revokeTenantRight(uint256 itemId) external;
}

//SPDX-License-Identifier: un-licensed
pragma solidity ^0.8.0;

import "../Interface/IERCX.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../Interface/IERCXReceiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERCX is IERCX, ERC721, ERC165Storage, AccessControl {
    using Strings for uint256;
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    address _owner;
    Counters.Counter private _tokenIds;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes4 private constant _ERCX_RECEIVED = 0x11111111;
    //bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"));

    // Mapping from item ID to layer to owner
    mapping(uint256 => mapping(uint256 => address)) private _itemOwner;

    // Mapping from item ID to layer to approved address
    mapping(uint256 => mapping(uint256 => address)) private _transferApprovals;

    // Mapping from owner to layer to number of owned item
    mapping(address => mapping(uint256 => Counters.Counter))
        private _ownedItemsCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from item ID to approved address of setting lien
    mapping(uint256 => address) private _lienApprovals;

    // Mapping from item ID to contract address of lien
    mapping(uint256 => address) private _lienAddress;

    // Mapping from item ID to approved address of setting tenant right agreement
    mapping(uint256 => address) private _tenantRightApprovals;

    // Mapping from item ID to contract address of TenantRight
    mapping(uint256 => address) private _tenantRightAddress;

    bytes4 private constant _InterfaceId_ERCX =
        bytes4(keccak256("balanceOfOwner(address)")) ^
            bytes4(keccak256("balanceOfUser(address)")) ^
            bytes4(keccak256("ownerOf(uint256)")) ^
            bytes4(keccak256("userOf(uint256)")) ^
            bytes4(keccak256("safeTransferOwner(address, address, uint256)")) ^
            bytes4(
                keccak256("safeTransferOwner(address, address, uint256, bytes)")
            ) ^
            bytes4(keccak256("safeTransferUser(address, address, uint256)")) ^
            bytes4(
                keccak256("safeTransferUser(address, address, uint256, bytes)")
            ) ^
            bytes4(keccak256("approveForOwner(address, uint256)")) ^
            bytes4(keccak256("getApprovedForOwner(uint256)")) ^
            bytes4(keccak256("approveForUser(address, uint256)")) ^
            bytes4(keccak256("getApprovedForUser(uint256)")) ^
            bytes4(keccak256("setApprovalForAll(address, bool)")) ^
            bytes4(keccak256("isApprovedForAll(address, address)")) ^
            bytes4(keccak256("approveLien(address, uint256)")) ^
            bytes4(keccak256("getApprovedLien(uint256)")) ^
            bytes4(keccak256("setLien(uint256)")) ^
            bytes4(keccak256("getCurrentLien(uint256)")) ^
            bytes4(keccak256("revokeLien(uint256)")) ^
            bytes4(keccak256("approveTenantRight(address, uint256)")) ^
            bytes4(keccak256("getApprovedTenantRight(uint256)")) ^
            bytes4(keccak256("setTenantRight(uint256)")) ^
            bytes4(keccak256("getCurrentTenantRight(uint256)")) ^
            bytes4(keccak256("revokeTenantRight(uint256)"));

    constructor() ERC721("vRent Non-C", "RNC") {
        _owner = msg.sender;
        // register the supported interfaces to conform to ERCX via ERC165
        _registerInterface(_InterfaceId_ERCX);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC165Storage, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return uint256 representing the amount of items owned by the passed address in the specified layer
     */
    function balanceOfOwner(address owner)
        public
        view
        override
        returns (uint256)
    {
        require(owner != address(0));
        uint256 balance = _ownedItemsCount[owner][2].current();
        return balance;
    }

    /**
     * @dev Gets the balance of the specified address
     * @param user address to query the balance of
     * @return uint256 representing the amount of items owned by the passed address
     */
    function balanceOfUser(address user)
        public
        view
        override
        returns (uint256)
    {
        require(user != address(0));
        uint256 balance = _ownedItemsCount[user][1].current();
        return balance;
    }

    /**
     * @dev Gets the user of the specified item ID
     * @param itemId uint256 ID of the item to query the user of
     * @return owner address currently marked as the owner of the given item ID
     */
    function userOf(uint256 itemId) public view override returns (address) {
        address user = _itemOwner[itemId][1];
        require(user != address(0));
        return user;
    }

    /**
     * @dev Gets the owner of the specified item ID
     * @param itemId uint256 ID of the item to query the owner of
     * @return owner address currently marked as the owner of the given item ID
     */
    function ownerOf(uint256 itemId)
        public
        view
        override(IERCX, ERC721)
        returns (address)
    {
        address owner = _itemOwner[itemId][2];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev Approves another address to transfer the user of the given item ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per item at a given time.
     * Can only be called by the item owner or an approved operator.
     * @param to address to be approved for the given item ID
     */
    function approveForUser(address to, uint256 itemId) public override {
        address user = userOf(itemId);
        address owner = ownerOf(itemId);

        require(to != owner && to != user);
        require(
            msg.sender == user ||
                msg.sender == owner ||
                isApprovedForAll(user, msg.sender) ||
                isApprovedForAll(owner, msg.sender)
        );
        if (msg.sender == owner || isApprovedForAll(owner, msg.sender)) {
            require(getCurrentTenantRight(itemId) == address(0));
        }
        _transferApprovals[itemId][1] = to;
        emit ApprovalForUser(user, to, itemId);
    }

    /**
     * @dev Gets the approved address for the user of the item ID, or zero if no address set
     * Reverts if the item ID does not exist.
     * @param itemId uint256 ID of the item to query the approval of
     * @return address currently approved for the given item ID
     */
    function getApprovedForUser(uint256 itemId)
        public
        view
        override
        returns (address)
    {
        require(_exists(itemId, 1));
        return _transferApprovals[itemId][1];
    }

    /**
     * @dev Approves another address to transfer the owner of the given item ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per item at a given time.
     * Can only be called by the item owner or an approved operator.
     * @param to address to be approved for the given item ID
     * @param itemId uint256 ID of the item to be approved
     */
    function approveForOwner(address to, uint256 itemId) public override {
        address owner = ownerOf(itemId);

        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _transferApprovals[itemId][2] = to;
        emit ApprovalForOwner(owner, to, itemId);
    }

    /**
     * @dev Gets the approved address for the of the item ID, or zero if no address set
     * Reverts if the item ID does not exist.
     * @param itemId uint256 ID of the item to query the approval o
     * @return address currently approved for the given item ID
     */
    function getApprovedForOwner(uint256 itemId)
        public
        view
        override
        returns (address)
    {
        require(_exists(itemId, 2));
        return _transferApprovals[itemId][2];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all items of the sender on their behalf
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved)
        public
        override(IERCX, ERC721)
    {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(IERCX, ERC721)
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Approves another address to set lien contract for the given item ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per item at a given time.
     * Can only be called by the item owner or an approved operator.
     * @param to address to be approved for the given item ID
     * @param itemId uint256 ID of the item to be approved
     */
    function approveLien(address to, uint256 itemId) public override {
        address owner = ownerOf(itemId);
        // require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _lienApprovals[itemId] = to;
        emit LienApproval(to, itemId);
    }

    /**
     * @dev Gets the approved address for setting lien for a item ID, or zero if no address set
     * Reverts if the item ID does not exist.
     * @param itemId uint256 ID of the item to query the approval of
     * @return address currently approved for the given item ID
     */
    function getApprovedLien(uint256 itemId)
        public
        view
        override
        returns (address)
    {
        require(_exists(itemId, 2));
        return _lienApprovals[itemId];
    }

    /**
     * @dev Sets lien agreements to already approved address
     * The lien address is allowed to transfer all items of the sender on their behalf
     * @param itemId uint256 ID of the item
     */
    function setLien(uint256 itemId) public override {
        require(msg.sender == getApprovedLien(itemId));
        _lienAddress[itemId] = msg.sender;
        _clearLienApproval(itemId);
        emit LienSet(msg.sender, itemId, true);
    }

    /**
     * @dev Gets the current lien agreement address, or zero if no address set
     * Reverts if the item ID does not exist.
     * @param itemId uint256 ID of the item to query the lien address
     * @return address of the lien agreement address for the given item ID
     */
    function getCurrentLien(uint256 itemId)
        public
        view
        override
        returns (address)
    {
        require(_exists(itemId, 2));
        return _lienAddress[itemId];
    }

    /**
     * @dev Revoke the lien agreements. Only the lien address can revoke.
     * @param itemId uint256 ID of the item
     */
    function revokeLien(uint256 itemId) public override {
        require(msg.sender == getCurrentLien(itemId));
        _lienAddress[itemId] = address(0);
        emit LienSet(address(0), itemId, false);
    }

    /**
     * @dev Approves another address to set tenant right agreement for the given item ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per item at a given time.
     * Can only be called by the item owner or an approved operator.
     * @param to address to be approved for the given item ID
     * @param itemId uint256 ID of the item to be approved
     */
    function approveTenantRight(address to, uint256 itemId) public override {
        address owner = ownerOf(itemId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _tenantRightApprovals[itemId] = to;
        emit TenantRightApproval(to, itemId);
    }

    /**
     * @dev Gets the approved address for setting tenant right for a item ID, or zero if no address set
     * Reverts if the item ID does not exist.
     * @param itemId uint256 ID of the item to query the approval of
     * @return address currently approved for the given item ID
     */
    function getApprovedTenantRight(uint256 itemId)
        public
        view
        override
        returns (address)
    {
        require(_exists(itemId, 2));
        return _tenantRightApprovals[itemId];
    }

    /**
     * @dev Sets the tenant right agreement to already approved address
     * The lien address is allowed to transfer all items of the sender on their behalf
     * @param itemId uint256 ID of the item
     */
    function setTenantRight(uint256 itemId) public override {
        require(msg.sender == getApprovedTenantRight(itemId));
        _tenantRightAddress[itemId] = msg.sender;
        _clearTenantRightApproval(itemId);
        _clearTransferApproval(itemId, 1); //Reset transfer approval
        emit TenantRightSet(msg.sender, itemId, true);
    }

    /**
     * @dev Gets the current tenant right agreement address, or zero if no address set
     * Reverts if the item ID does not exist.
     * @param itemId uint256 ID of the item to query the tenant right address
     * @return address of the tenant right agreement address for the given item ID
     */
    function getCurrentTenantRight(uint256 itemId)
        public
        view
        override
        returns (address)
    {
        require(_exists(itemId, 2));
        return _tenantRightAddress[itemId];
    }

    /**
     * @dev Revoke the tenant right agreement. Only the lien address can revoke.
     * @param itemId uint256 ID of the item
     */
    function revokeTenantRight(uint256 itemId) public override {
        require(msg.sender == getCurrentTenantRight(itemId));
        _tenantRightAddress[itemId] = address(0);
        emit TenantRightSet(address(0), itemId, false);
    }

    /**
   * @dev Safely transfers the user of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred

  */
    function safeTransferUser(
        address from,
        address to,
        uint256 itemId
    ) public override {
        // solium-disable-next-line arg-overflow
        safeTransferUser(from, to, itemId, "");
    }

    /**
     * @dev Safely transfers the user of a given item ID to another address
     * If the target address is a contract, it must implement `onERCXReceived`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the item
     * @param to address to receive the ownership of the given item ID
     * @param itemId uint256 ID of the item to be transferred
     * @param data bytes data to send along with a safe transfer check
     */
    function safeTransferUser(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) public override {
        require(_isEligibleForTransfer(msg.sender, itemId, 1));
        _safeTransfer(from, to, itemId, 1, data);
    }

    /**
     * @dev Safely transfers the ownership of a given item ID to another address
     * If the target address is a contract, it must implement `onERCXReceived`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the item
     * @param to address to receive the ownership of the given item ID
     * @param itemId uint256 ID of the item to be transferred
     */
    function safeTransferOwner(
        address from,
        address to,
        uint256 itemId
    ) public override {
        // solium-disable-next-line arg-overflow
        safeTransferOwner(from, to, itemId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given item ID to another address
     * If the target address is a contract, it must implement `onERCXReceived`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the item
     * @param to address to receive the ownership of the given item ID
     * @param itemId uint256 ID of the item to be transferred
     * @param data bytes data to send along with a safe transfer check
     */
    function safeTransferOwner(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) public override {
        require(_isEligibleForTransfer(msg.sender, itemId, 2));
        _safeTransfer(from, to, itemId, 2, data);
    }

    /**
     * @dev Safely transfers the ownership of a given item ID to another address
     * If the target address is a contract, it must implement `onERCXReceived`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the item
     * @param to address to receive the ownership of the given item ID
     * @param itemId uint256 ID of the item to be transferred
     * @param layer uint256 number to specify the layer
     * @param data bytes data to send along with a safe transfer check
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 itemId,
        uint256 layer,
        bytes memory data
    ) internal {
        _transfer(from, to, itemId, layer);
        require(
            _checkOnERCXReceived(from, to, itemId, layer, data),
            "ERCX: transfer to non ERCXReceiver implementer"
        );
    }

    /**
     * @dev Returns whether the given spender can transfer a given item ID.
     * @param spender address of the spender to query
     * @param itemId uint256 ID of the item to be transferred
     * @param layer uint256 number to specify the layer
     * @return bool whether the msg.sender is approved for the given item ID,
     * is an operator of the owner, or is the owner of the item
     */
    function _isEligibleForTransfer(
        address spender,
        uint256 itemId,
        uint256 layer
    ) internal view returns (bool) {
        require(_exists(itemId, layer));
        bool flag;
        if (layer == 1) {
            address user = userOf(itemId);
            address owner = ownerOf(itemId);
            require(
                spender == user ||
                    spender == owner ||
                    isApprovedForAll(user, spender) ||
                    isApprovedForAll(owner, spender) ||
                    spender == getApprovedForUser(itemId) ||
                    spender == getCurrentLien(itemId)
            );
            if (spender == owner || isApprovedForAll(owner, spender)) {
                require(getCurrentTenantRight(itemId) == address(0));
            }
            flag = true;
        }

        if (layer == 2) {
            address owner = ownerOf(itemId);
            require(
                spender == owner ||
                    isApprovedForAll(owner, spender) ||
                    spender == getApprovedForOwner(itemId) ||
                    spender == getCurrentLien(itemId)
            );
            flag = true;
        }
        return flag;
    }

    /**
     * @dev Returns whether the specified item exists
     * @param itemId uint256 ID of the item to query the existence of
     * @param layer uint256 number to specify the layer
     * @return whether the item exists
     */
    function _exists(uint256 itemId, uint256 layer)
        internal
        view
        returns (bool)
    {
        address owner = _itemOwner[itemId][layer];
        return owner != address(0);
    }

    /**
     * @dev Internal function to safely mint a new item.
     * Reverts if the given item ID already exists.
     * If the target address is a contract, it must implement `onERCXReceived`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted item
     * @param itemId uint256 ID of the item to be minted
     */
    function _safeMint(address to, uint256 itemId) internal override {
        _safeMint(to, itemId, "");
    }

    /**
     * @dev Internal function to safely mint a new item.
     * Reverts if the given item ID already exists.
     * If the target address is a contract, it must implement `onERCXReceived`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted item
     * @param itemId uint256 ID of the item to be minted
     * @param data bytes data to send along with a safe transfer check
     */
    function _safeMint(
        address to,
        uint256 itemId,
        bytes memory data
    ) internal override {
        _mint(to, itemId);
        require(_checkOnERCXReceived(address(0), to, itemId, 1, data));
        require(_checkOnERCXReceived(address(0), to, itemId, 2, data));
    }

    function _mint(address to, uint256 itemId) internal override {
        require(to != address(0), "ERCX: mint to the zero address");
        require(!_exists(itemId, 1), "ERCX: item already minted");

        _itemOwner[itemId][1] = to;
        _itemOwner[itemId][2] = to;
        _ownedItemsCount[to][1].increment();
        _ownedItemsCount[to][2].increment();

        emit TransferUser(address(0), to, itemId, msg.sender);
        emit TransferOwner(address(0), to, itemId, msg.sender);
    }

    /**
     * @dev Internal function to mint a new item.
     * Reverts if the given item ID already exists.
     * A new item iss minted with all three layers.
     */
    function mint() external {
        require(hasRole(MINTER_ROLE, msg.sender), "ERCX: Admin only");

        _tokenIds.increment();
        uint256 itemId = _tokenIds.current();
        _mint(msg.sender, itemId);

        emit TransferUser(address(0), msg.sender, itemId, msg.sender);
        emit TransferOwner(address(0), msg.sender, itemId, msg.sender);
    }

    /**
     * @dev Internal function to burn a specific item.
     * Reverts if the item does not exist.
     * @param itemId uint256 ID of the item being burned
     */
    function _burn(uint256 itemId) internal virtual override {
        address user = userOf(itemId);
        address owner = ownerOf(itemId);
        require(user == msg.sender && owner == msg.sender);

        _clearTransferApproval(itemId, 1);
        _clearTransferApproval(itemId, 2);

        _ownedItemsCount[user][1].decrement();
        _ownedItemsCount[owner][2].decrement();
        _itemOwner[itemId][1] = address(0);
        _itemOwner[itemId][2] = address(0);

        emit TransferUser(user, address(0), itemId, msg.sender);
        emit TransferOwner(owner, address(0), itemId, msg.sender);
    }

    /**
     * @dev Internal function to transfer ownership of a given item ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the item
     * @param to address to receive the ownership of the given item ID
     * @param itemId uint256 ID of the item to be transferred
     * @param layer uint256 number to specify the layer
     */
    function _transfer(
        address from,
        address to,
        uint256 itemId,
        uint256 layer
    ) internal virtual {
        if (layer == 1) {
            require(userOf(itemId) == from);
        } else {
            require(ownerOf(itemId) == from);
        }
        require(to != address(0));

        _clearTransferApproval(itemId, layer);

        if (layer == 2) {
            _clearLienApproval(itemId);
            _clearTenantRightApproval(itemId);
        }

        _ownedItemsCount[from][layer].decrement();
        _ownedItemsCount[to][layer].increment();

        _itemOwner[itemId][layer] = to;

        if (layer == 1) {
            emit TransferUser(from, to, itemId, msg.sender);
        } else {
            emit TransferOwner(from, to, itemId, msg.sender);
        }
    }

    /**
     * @dev Internal function to invoke {IERCXReceiver-onERCXReceived} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This is an internal detail of the `ERCX` contract and its use is deprecated.
     * @param from address representing the previous owner of the given item ID
     * @param to target address that will receive the items
     * @param itemId uint256 ID of the item to be transferred
     * @param layer uint256 number to specify the layer
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERCXReceived(
        address from,
        address to,
        uint256 itemId,
        uint256 layer,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERCXReceiver(to).onERCXReceived(
            msg.sender,
            from,
            itemId,
            layer,
            data
        );
        return (retval == _ERCX_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given item ID.
     * @param itemId uint256 ID of the item to be transferred
     * @param layer uint256 number to specify the layer
     */
    function _clearTransferApproval(uint256 itemId, uint256 layer) private {
        if (_transferApprovals[itemId][layer] != address(0)) {
            _transferApprovals[itemId][layer] = address(0);
        }
    }

    function _clearTenantRightApproval(uint256 itemId) private {
        if (_tenantRightApprovals[itemId] != address(0)) {
            _tenantRightApprovals[itemId] = address(0);
        }
    }

    function _clearLienApproval(uint256 itemId) private {
        if (_lienApprovals[itemId] != address(0)) {
            _lienApprovals[itemId] = address(0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IPayment {
    enum PaymentToken {
        SENTINEL,
        WETH,
        USDC,
        DAI,
        USDT,
        TUSD,
        RENT
    }

    function getPaymentToken(uint8 index) external view returns (address);

    function setPaymentToken(uint8 index, address currencyAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IPayment.sol";

interface IvRent is IERC721Receiver {
    event Leased(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 leasingId,
        address indexed leaserAddress,
        uint8 maxRentDuration,
        bytes4 dailyRentPrice,
        IPayment.PaymentToken paymentToken
    );

    event Rented(
        uint256 leasingId,
        address indexed renterAddress,
        uint8 rentDuration,
        uint32 rentedAt
    );

    event Returned(uint256 indexed leasingId, uint32 returnedAt);

    event CollateralClaimed(uint256 indexed leasingId, uint32 claimedAt);

    event LeasingStopped(uint256 indexed leasingId, uint32 stoppedAt);

    /**
     * @dev sends your NFT to ReNFT contract, which acts as an escrow
     * between the lender and the renter
     */
    function lease(
        address[] memory _nft,
        uint256[] memory _tokenId,
        uint8[] memory _maxRentDuration,
        bytes4[] memory _dailyRentPrice,
        IPayment.PaymentToken[] memory _paymentToken
    ) external;

    /**
     * @dev renter sends rentDuration * dailyRentPrice
     * to cover for the potentially full cost of renting. They also
     * must send the collateral (nft price set by the lender in lend)
     */
    function rentNFT(
        address[] memory _nft,
        uint256[] memory _tokenId,
        uint256[] memory _leasingIds,
        uint8[] memory _rentDurations
    ) external;

    /**
     * @dev renters call this to return the rented NFT before the
     * deadline. If they fail to do so, they will lose the posted
     * collateral
     */
    function endRent(
        address[] memory _nft,
        uint256[] memory _tokenId,
        uint256[] memory _leasingIds
    ) external;

    /**
     * @dev stop lending releases the NFT from escrow and sends it back
     * to the lender
     */
    function cancelLeasing(
        address[] memory _nft,
        uint256[] memory _tokenId,
        uint256[] memory _leasingIds
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

//SPDX-License-Identifier: un-licensed
pragma solidity ^0.8.0;

/**
 * @title ERCX token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERCX asset contracts.
 */
interface IERCXReceiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERCX smart contract calls this function on the recipient
     * after a {IERCX-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERCXReceived.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERCX contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param itemId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERCXReceived(address,address,uint256,uint256,bytes)"))`
     */
    function onERCXReceived(
        address operator,
        address from,
        uint256 itemId,
        uint256 layer,
        bytes memory data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}