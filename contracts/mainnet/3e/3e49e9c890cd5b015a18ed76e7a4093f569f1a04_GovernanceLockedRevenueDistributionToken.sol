// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { IERC20 } from "./interfaces/IERC20.sol";

/*
    ███████╗██████╗  ██████╗    ██████╗  ██████╗
    ██╔════╝██╔══██╗██╔════╝    ╚════██╗██╔═████╗
    █████╗  ██████╔╝██║          █████╔╝██║██╔██║
    ██╔══╝  ██╔══██╗██║         ██╔═══╝ ████╔╝██║
    ███████╗██║  ██║╚██████╗    ███████╗╚██████╔╝
    ╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚══════╝ ╚═════╝
*/

/**
 *  @title Modern ERC-20 implementation.
 *  @dev   Acknowledgements to Solmate, OpenZeppelin, and DSS for inspiring this code.
 */
contract ERC20 is IERC20 {

    /**************/
    /*** ERC-20 ***/
    /**************/

    string public override name;
    string public override symbol;

    uint8 public immutable override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    /****************/
    /*** ERC-2612 ***/
    /****************/

    // PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    uint256 internal immutable initialChainId;

    bytes32 internal immutable initialDomainSeparator;

    mapping(address => uint256) public override nonces;

    /**
     *  @param name_     The name of the token.
     *  @param symbol_   The symbol of the token.
     *  @param decimals_ The decimal precision used by the token.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name     = name_;
        symbol   = symbol_;
        decimals = decimals_;
        initialChainId = block.chainid;
        initialDomainSeparator = _computeDomainSeparator();
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function approve(address spender_, uint256 amount_) external override returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external override returns (bool success_) {
        _decreaseAllowance(msg.sender, spender_, subtractedAmount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedAmount_) external override returns (bool success_) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] + addedAmount_);
        return true;
    }

    function permit(address owner_, address spender_, uint256 amount_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) external override {
        require(deadline_ >= block.timestamp, "ERC20:P:EXPIRED");

        // Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}.
        require(
            uint256(s_) <= uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) &&
            (v_ == 27 || v_ == 28),
            "ERC20:P:MALLEABLE"
        );

        // Nonce realistically cannot overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, amount_, nonces[owner_]++, deadline_))
                )
            );

            address recoveredAddress = ecrecover(digest, v_, r_, s_);

            require(recoveredAddress == owner_ && owner_ != address(0), "ERC20:P:INVALID_SIGNATURE");
        }

        _approve(owner_, spender_, amount_);
    }

    function transfer(address recipient_, uint256 amount_) external override returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(address owner_, address recipient_, uint256 amount_) external override returns (bool success_) {
        _decreaseAllowance(owner_, msg.sender, amount_);
        _transfer(owner_, recipient_, amount_);
        return true;
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function DOMAIN_SEPARATOR() public view virtual override returns (bytes32 domainSeparator_) {
        return block.chainid == initialChainId ? initialDomainSeparator : _computeDomainSeparator();
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _approve(address owner_, address spender_, uint256 amount_) internal {
        emit Approval(owner_, spender_, allowance[owner_][spender_] = amount_);
    }

    function _burn(address owner_, uint256 amount_) internal virtual {
        balanceOf[owner_] -= amount_;

        // Cannot underflow because a user's balance will never be larger than the total supply.
        unchecked { totalSupply -= amount_; }

        emit Transfer(owner_, address(0), amount_);
    }

    function _computeDomainSeparator() internal view virtual returns (bytes32 domainSeparator_) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function _decreaseAllowance(address owner_, address spender_, uint256 subtractedAmount_) internal {
        uint256 spenderAllowance = allowance[owner_][spender_];  // Cache to memory.

        if (spenderAllowance != type(uint256).max) {
            _approve(owner_, spender_, spenderAllowance - subtractedAmount_);
        }
    }

    function _mint(address recipient_, uint256 amount_) internal virtual {
        totalSupply += amount_;

        // Cannot overflow because totalSupply would first overflow in the statement above.
        unchecked { balanceOf[recipient_] += amount_; }

        emit Transfer(address(0), recipient_, amount_);
    }

    function _transfer(address owner_, address recipient_, uint256 amount_) internal virtual {
        balanceOf[owner_] -= amount_;

        // Cannot overflow because minting prevents overflow of totalSupply, and sum of user balances == totalSupply.
        unchecked { balanceOf[recipient_] += amount_; }

        emit Transfer(owner_, recipient_, amount_);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @title Interface of the ERC20 standard as defined in the EIP, including EIP-2612 permit functionality.
interface IERC20 {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   Emitted when one account has set the allowance of another account over their tokens.
     *  @param owner_   Account that tokens are approved from.
     *  @param spender_ Account that tokens are approved for.
     *  @param amount_  Amount of tokens that have been approved.
     */
    event Approval(address indexed owner_, address indexed spender_, uint256 amount_);

    /**
     *  @dev   Emitted when tokens have moved from one account to another.
     *  @param owner_     Account that tokens have moved from.
     *  @param recipient_ Account that tokens have moved to.
     *  @param amount_    Amount of tokens that have been transferred.
     */
    event Transfer(address indexed owner_, address indexed recipient_, uint256 amount_);

    /**************************/
    /*** External Functions ***/
    /**************************/

    /**
     *  @dev    Function that allows one account to set the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_ Account that tokens are approved for.
     *  @param  amount_  Amount of tokens that have been approved.
     *  @return success_ Boolean indicating whether the operation succeeded.
     */
    function approve(address spender_, uint256 amount_) external returns (bool success_);

    /**
     *  @dev    Function that allows one account to decrease the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_          Account that tokens are approved for.
     *  @param  subtractedAmount_ Amount to decrease approval by.
     *  @return success_          Boolean indicating whether the operation succeeded.
     */
    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external returns (bool success_);

    /**
     *  @dev    Function that allows one account to increase the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_     Account that tokens are approved for.
     *  @param  addedAmount_ Amount to increase approval by.
     *  @return success_     Boolean indicating whether the operation succeeded.
     */
    function increaseAllowance(address spender_, uint256 addedAmount_) external returns (bool success_);

    /**
     *  @dev   Approve by signature.
     *  @param owner_    Owner address that signed the permit.
     *  @param spender_  Spender of the permit.
     *  @param amount_   Permit approval spend limit.
     *  @param deadline_ Deadline after which the permit is invalid.
     *  @param v_        ECDSA signature v component.
     *  @param r_        ECDSA signature r component.
     *  @param s_        ECDSA signature s component.
     */
    function permit(address owner_, address spender_, uint amount_, uint deadline_, uint8 v_, bytes32 r_, bytes32 s_) external;

    /**
     *  @dev    Moves an amount of tokens from `msg.sender` to a specified account.
     *          Emits a {Transfer} event.
     *  @param  recipient_ Account that receives tokens.
     *  @param  amount_    Amount of tokens that are transferred.
     *  @return success_   Boolean indicating whether the operation succeeded.
     */
    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    /**
     *  @dev    Moves a pre-approved amount of tokens from a sender to a specified account.
     *          Emits a {Transfer} event.
     *          Emits an {Approval} event.
     *  @param  owner_     Account that tokens are moving from.
     *  @param  recipient_ Account that receives tokens.
     *  @param  amount_    Amount of tokens that are transferred.
     *  @return success_   Boolean indicating whether the operation succeeded.
     */
    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    Returns the allowance that one account has given another over their tokens.
     *  @param  owner_     Account that tokens are approved from.
     *  @param  spender_   Account that tokens are approved for.
     *  @return allowance_ Allowance that one account has given another over their tokens.
     */
    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    /**
     *  @dev    Returns the amount of tokens owned by a given account.
     *  @param  account_ Account that owns the tokens.
     *  @return balance_ Amount of tokens owned by a given account.
     */
    function balanceOf(address account_) external view returns (uint256 balance_);

    /**
     *  @dev    Returns the decimal precision used by the token.
     *  @return decimals_ The decimal precision used by the token.
     */
    function decimals() external view returns (uint8 decimals_);

    /**
     *  @dev    Returns the signature domain separator.
     *  @return domainSeparator_ The signature domain separator.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator_);

    /**
     *  @dev    Returns the name of the token.
     *  @return name_ The name of the token.
     */
    function name() external view returns (string memory name_);

    /**
      *  @dev    Returns the nonce for the given owner.
      *  @param  owner_  The address of the owner account.
      *  @return nonce_ The nonce for the given owner.
     */
    function nonces(address owner_) external view returns (uint256 nonce_);

    /**
     *  @dev    Returns the symbol of the token.
     *  @return symbol_ The symbol of the token.
     */
    function symbol() external view returns (string memory symbol_);

    /**
     *  @dev    Returns the total amount of tokens in existence.
     *  @return totalSupply_ The total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 totalSupply_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20Like } from "./interfaces/IERC20Like.sol";

/**
 * @title Small Library to standardize erc20 token interactions.
 */
library ERC20Helper {

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function transfer(address token_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transfer.selector, to_, amount_));
    }

    function transferFrom(address token_, address from_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transferFrom.selector, from_, to_, amount_));
    }

    function approve(address token_, address spender_, uint256 amount_) internal returns (bool success_) {
        // If setting approval to zero fails, return false.
        if (!_call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, uint256(0)))) return false;

        // If `amount_` is zero, return true as the previous step already did this.
        if (amount_ == uint256(0)) return true;

        // Return the result of setting the approval to `amount_`.
        return _call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, amount_));
    }

    function _call(address token_, bytes memory data_) private returns (bool success_) {
        if (token_.code.length == uint256(0)) return false;

        bytes memory returnData;
        ( success_, returnData ) = token_.call(data_);

        return success_ && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as needed by ERC20Helper.
interface IERC20Like {

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ERC20 }       from "erc20/ERC20.sol";
import { ERC20Helper } from "erc20-helper/ERC20Helper.sol";

import { IRevenueDistributionToken } from "./interfaces/IRevenueDistributionToken.sol";

/*
    ██████╗ ██████╗ ████████╗
    ██╔══██╗██╔══██╗╚══██╔══╝
    ██████╔╝██║  ██║   ██║
    ██╔══██╗██║  ██║   ██║
    ██║  ██║██████╔╝   ██║
    ╚═╝  ╚═╝╚═════╝    ╚═╝
*/

contract RevenueDistributionToken is IRevenueDistributionToken, ERC20 {

    uint256 public immutable override precision;  // Precision of rates, equals max deposit amounts before rounding errors occur

    address public override asset;  // Underlying ERC-20 asset used by ERC-4626 functionality.

    address public override owner;         // Current owner of the contract, able to update the vesting schedule.
    address public override pendingOwner;  // Pending owner of the contract, able to accept ownership.

    uint256 public override freeAssets;           // Amount of assets unlocked regardless of time passed.
    uint256 public override issuanceRate;         // asset/second rate dependent on aggregate vesting schedule.
    uint256 public override lastUpdated;          // Timestamp of when issuance equation was last updated.
    uint256 public override vestingPeriodFinish;  // Timestamp when current vesting schedule ends.

    uint256 private locked = 1;  // Used in reentrancy check.

    /*****************/
    /*** Modifiers ***/
    /*****************/

    modifier nonReentrant() {
        require(locked == 1, "RDT:LOCKED");

        locked = 2;

        _;

        locked = 1;
    }

    constructor(string memory name_, string memory symbol_, address owner_, address asset_, uint256 precision_)
        ERC20(name_, symbol_, ERC20(asset_).decimals())
    {
        require((owner = owner_) != address(0), "RDT:C:OWNER_ZERO_ADDRESS");

        asset     = asset_;  // Don't need to check zero address as ERC20(asset_).decimals() will fail in ERC20 constructor.
        precision = precision_;
    }

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function acceptOwnership() external virtual override {
        require(msg.sender == pendingOwner, "RDT:AO:NOT_PO");

        emit OwnershipAccepted(owner, msg.sender);

        owner        = msg.sender;
        pendingOwner = address(0);
    }

    function setPendingOwner(address pendingOwner_) external virtual override {
        require(msg.sender == owner, "RDT:SPO:NOT_OWNER");

        pendingOwner = pendingOwner_;

        emit PendingOwnerSet(msg.sender, pendingOwner_);
    }

    function updateVestingSchedule(uint256 vestingPeriod_) external virtual override returns (uint256 issuanceRate_, uint256 freeAssets_) {
        require(msg.sender == owner, "RDT:UVS:NOT_OWNER");
        require(totalSupply != 0,    "RDT:UVS:ZERO_SUPPLY");

        // Update "y-intercept" to reflect current available asset.
        freeAssets_ = freeAssets = totalAssets();

        // Calculate slope.
        issuanceRate_ = issuanceRate = ((ERC20(asset).balanceOf(address(this)) - freeAssets_) * precision) / vestingPeriod_;

        // Update timestamp and period finish.
        vestingPeriodFinish = (lastUpdated = block.timestamp) + vestingPeriod_;

        emit IssuanceParamsUpdated(freeAssets_, issuanceRate_);
        emit VestingScheduleUpdated(msg.sender, vestingPeriodFinish);
    }

    /************************/
    /*** Staker Functions ***/
    /************************/

    function deposit(uint256 assets_, address receiver_) public virtual override nonReentrant returns (uint256 shares_) {
        _mint(shares_ = previewDeposit(assets_), assets_, receiver_, msg.sender);
    }

    function depositWithPermit(
        uint256 assets_,
        address receiver_,
        uint256 deadline_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    )
        external virtual override nonReentrant returns (uint256 shares_)
    {
        ERC20(asset).permit(msg.sender, address(this), assets_, deadline_, v_, r_, s_);
        _mint(shares_ = previewDeposit(assets_), assets_, receiver_, msg.sender);
    }

    function mint(uint256 shares_, address receiver_) public virtual override nonReentrant returns (uint256 assets_) {
        _mint(shares_, assets_ = previewMint(shares_), receiver_, msg.sender);
    }

    function mintWithPermit(
        uint256 shares_,
        address receiver_,
        uint256 maxAssets_,
        uint256 deadline_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    )
        external virtual override nonReentrant returns (uint256 assets_)
    {
        require((assets_ = previewMint(shares_)) <= maxAssets_, "RDT:MWP:INSUFFICIENT_PERMIT");

        ERC20(asset).permit(msg.sender, address(this), maxAssets_, deadline_, v_, r_, s_);
        _mint(shares_, assets_, receiver_, msg.sender);
    }

    function redeem(uint256 shares_, address receiver_, address owner_) external virtual override nonReentrant returns (uint256 assets_) {
        _burn(shares_, assets_ = previewRedeem(shares_), receiver_, owner_, msg.sender);
    }

    function withdraw(uint256 assets_, address receiver_, address owner_) external virtual override nonReentrant returns (uint256 shares_) {
        _burn(shares_ = previewWithdraw(assets_), assets_, receiver_, owner_, msg.sender);
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _mint(uint256 shares_, uint256 assets_, address receiver_, address caller_) internal virtual {
        require(receiver_ != address(0), "RDT:M:ZERO_RECEIVER");
        require(shares_   != uint256(0), "RDT:M:ZERO_SHARES");
        require(assets_   != uint256(0), "RDT:M:ZERO_ASSETS");

        _mint(receiver_, shares_);

        uint256 freeAssetsCache = freeAssets = totalAssets() + assets_;

        uint256 issuanceRate_ = _updateIssuanceParams();

        emit Deposit(caller_, receiver_, assets_, shares_);
        emit IssuanceParamsUpdated(freeAssetsCache, issuanceRate_);

        require(ERC20Helper.transferFrom(asset, caller_, address(this), assets_), "RDT:M:TRANSFER_FROM");
    }

    function _burn(uint256 shares_, uint256 assets_, address receiver_, address owner_, address caller_) internal virtual {
        require(receiver_ != address(0), "RDT:B:ZERO_RECEIVER");
        require(shares_   != uint256(0), "RDT:B:ZERO_SHARES");
        require(assets_   != uint256(0), "RDT:B:ZERO_ASSETS");

        if (caller_ != owner_) {
            _decreaseAllowance(owner_, caller_, shares_);
        }

        _burn(owner_, shares_);

        uint256 freeAssetsCache = freeAssets = totalAssets() - assets_;

        uint256 issuanceRate_ = _updateIssuanceParams();

        emit Withdraw(caller_, receiver_, owner_, assets_, shares_);
        emit IssuanceParamsUpdated(freeAssetsCache, issuanceRate_);

        require(ERC20Helper.transfer(asset, receiver_, assets_), "RDT:B:TRANSFER");
    }

    function _updateIssuanceParams() internal returns (uint256 issuanceRate_) {
        return issuanceRate = (lastUpdated = block.timestamp) > vestingPeriodFinish ? 0 : issuanceRate;
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function balanceOfAssets(address account_) public view virtual override returns (uint256 balanceOfAssets_) {
        return convertToAssets(balanceOf[account_]);
    }

    function convertToAssets(uint256 shares_) public view virtual override returns (uint256 assets_) {
        uint256 supply = totalSupply;  // Cache to stack.

        assets_ = supply == 0 ? shares_ : (shares_ * totalAssets()) / supply;
    }

    function convertToShares(uint256 assets_) public view virtual override returns (uint256 shares_) {
        uint256 supply = totalSupply;  // Cache to stack.

        shares_ = supply == 0 ? assets_ : (assets_ * supply) / totalAssets();
    }

    function maxDeposit(address receiver_) external pure virtual override returns (uint256 maxAssets_) {
        receiver_;  // Silence warning
        maxAssets_ = type(uint256).max;
    }

    function maxMint(address receiver_) external pure virtual override returns (uint256 maxShares_) {
        receiver_;  // Silence warning
        maxShares_ = type(uint256).max;
    }

    function maxRedeem(address owner_) external view virtual override returns (uint256 maxShares_) {
        maxShares_ = balanceOf[owner_];
    }

    function maxWithdraw(address owner_) external view virtual override returns (uint256 maxAssets_) {
        maxAssets_ = balanceOfAssets(owner_);
    }

    function previewDeposit(uint256 assets_) public view virtual override returns (uint256 shares_) {
        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round DOWN if it’s calculating the amount of shares to issue to a user, given an amount of assets provided.
        shares_ = convertToShares(assets_);
    }

    function previewMint(uint256 shares_) public view virtual override returns (uint256 assets_) {
        uint256 supply = totalSupply;  // Cache to stack.

        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round UP if it’s calculating the amount of assets a user must provide, to be issued a given amount of shares.
        assets_ = supply == 0 ? shares_ : _divRoundUp(shares_ * totalAssets(), supply);
    }

    function previewRedeem(uint256 shares_) public view virtual override returns (uint256 assets_) {
        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round DOWN if it’s calculating the amount of assets to send to a user, given amount of shares returned.
        assets_ = convertToAssets(shares_);
    }

    function previewWithdraw(uint256 assets_) public view virtual override returns (uint256 shares_) {
        uint256 supply = totalSupply;  // Cache to stack.

        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round UP if it’s calculating the amount of shares a user must return, to be sent a given amount of assets.
        shares_ = supply == 0 ? assets_ : _divRoundUp(assets_ * supply, totalAssets());
    }

    function totalAssets() public view virtual override returns (uint256 totalManagedAssets_) {
        uint256 issuanceRate_ = issuanceRate;

        if (issuanceRate_ == 0) return freeAssets;

        uint256 vestingPeriodFinish_ = vestingPeriodFinish;
        uint256 lastUpdated_         = lastUpdated;

        uint256 vestingTimePassed =
            block.timestamp > vestingPeriodFinish_ ?
                vestingPeriodFinish_ - lastUpdated_ :
                block.timestamp - lastUpdated_;

        return ((issuanceRate_ * vestingTimePassed) / precision) + freeAssets;
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _divRoundUp(uint256 numerator_, uint256 divisor_) internal pure returns (uint256 result_) {
       return (numerator_ / divisor_) + (numerator_ % divisor_ > 0 ? 1 : 0);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { IERC20 } from "erc20/interfaces/IERC20.sol";

/// @title A standard for tokenized Vaults with a single underlying ERC-20 token.
interface IERC4626 is IERC20 {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   `caller_` has exchanged `assets_` for `shares_` and transferred them to `owner_`.
     *         MUST be emitted when assets are deposited via the `deposit` or `mint` methods.
     *  @param caller_ The caller of the function that emitted the `Deposit` event.
     *  @param owner_  The owner of the shares.
     *  @param assets_ The amount of assets deposited.
     *  @param shares_ The amount of shares minted.
     */
    event Deposit(address indexed caller_, address indexed owner_, uint256 assets_, uint256 shares_);

    /**
     *  @dev   `caller_` has exchanged `shares_`, owned by `owner_`, for `assets_`, and transferred them to `receiver_`.
     *         MUST be emitted when assets are withdrawn via the `withdraw` or `redeem` methods.
     *  @param caller_   The caller of the function that emitted the `Withdraw` event.
     *  @param receiver_ The receiver of the assets.
     *  @param owner_    The owner of the shares.
     *  @param assets_   The amount of assets withdrawn.
     *  @param shares_   The amount of shares burned.
     */
    event Withdraw(address indexed caller_, address indexed receiver_, address indexed owner_, uint256 assets_, uint256 shares_);

    /***********************/
    /*** State Variables ***/
    /***********************/

    /**
     *  @dev    The address of the underlying asset used by the Vault.
     *          MUST be a contract that implements the ERC-20 standard.
     *          MUST NOT revert.
     *  @return asset_ The address of the underlying asset.
     */
    function asset() external view returns (address asset_);

    /********************************/
    /*** State Changing Functions ***/
    /********************************/

    /**
     *  @dev    Mints `shares_` to `receiver_` by depositing `assets_` into the Vault.
     *          MUST emit the {Deposit} event.
     *          MUST revert if all of the assets cannot be deposited (due to insufficient approval, deposit limits, slippage, etc).
     *  @param  assets_   The amount of assets to deposit.
     *  @param  receiver_ The receiver of the shares.
     *  @return shares_   The amount of shares minted.
     */
    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

    /**
     *  @dev    Mints `shares_` to `receiver_` by depositing `assets_` into the Vault.
     *          MUST emit the {Deposit} event.
     *          MUST revert if all of shares cannot be minted (due to insufficient approval, deposit limits, slippage, etc).
     *  @param  shares_   The amount of shares to mint.
     *  @param  receiver_ The receiver of the shares.
     *  @return assets_   The amount of assets deposited.
     */
    function mint(uint256 shares_, address receiver_) external returns (uint256 assets_);

    /**
     *  @dev    Burns `shares_` from `owner_` and sends `assets_` to `receiver_`.
     *          MUST emit the {Withdraw} event.
     *          MUST revert if all of the shares cannot be redeemed (due to insufficient shares, withdrawal limits, slippage, etc).
     *  @param  shares_   The amount of shares to redeem.
     *  @param  receiver_ The receiver of the assets.
     *  @param  owner_    The owner of the shares.
     *  @return assets_   The amount of assets sent to the receiver.
     */
    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

    /**
     *  @dev    Burns `shares_` from `owner_` and sends `assets_` to `receiver_`.
     *          MUST emit the {Withdraw} event.
     *          MUST revert if all of the assets cannot be withdrawn (due to insufficient assets, withdrawal limits, slippage, etc).
     *  @param  assets_   The amount of assets to withdraw.
     *  @param  receiver_ The receiver of the assets.
     *  @param  owner_    The owner of the assets.
     *  @return shares_   The amount of shares burned from the owner.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_) external returns (uint256 shares_);

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    The amount of `assets_` the `shares_` are currently equivalent to.
     *          MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT reflect slippage or other on-chain conditions when performing the actual exchange.
     *          MUST NOT show any variations depending on the caller.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to convert.
     *  @return assets_ The amount of equivalent assets.
     */
    function convertToAssets(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    The amount of `shares_` the `assets_` are currently equivalent to.
     *          MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT reflect slippage or other on-chain conditions when performing the actual exchange.
     *          MUST NOT show any variations depending on the caller.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to convert.
     *  @return shares_ The amount of equivalent shares.
     */
    function convertToShares(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `assets_` that can be deposited on behalf of the `receiver_` through a `deposit` call.
     *          MUST return a limited value if the receiver is subject to any limits, or the maximum value otherwise.
     *          MUST NOT revert.
     *  @param  receiver_ The receiver of the assets.
     *  @return assets_   The maximum amount of assets that can be deposited.
     */
    function maxDeposit(address receiver_) external view returns (uint256 assets_);

    /**
     *  @dev    Maximum amount of `shares_` that can be minted on behalf of the `receiver_` through a `mint` call.
     *          MUST return a limited value if the receiver is subject to any limits, or the maximum value otherwise.
     *          MUST NOT revert.
     *  @param  receiver_ The receiver of the shares.
     *  @return shares_   The maximum amount of shares that can be minted.
     */
    function maxMint(address receiver_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `shares_` that can be redeemed from the `owner_` through a `redeem` call.
     *          MUST return a limited value if the owner is subject to any limits, or the total amount of owned shares otherwise.
     *          MUST NOT revert.
     *  @param  owner_  The owner of the shares.
     *  @return shares_ The maximum amount of shares that can be redeemed.
     */
    function maxRedeem(address owner_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `assets_` that can be withdrawn from the `owner_` through a `withdraw` call.
     *          MUST return a limited value if the owner is subject to any limits, or the total amount of owned assets otherwise.
     *          MUST NOT revert.
     *  @param  owner_  The owner of the assets.
     *  @return assets_ The maximum amount of assets that can be withdrawn.
     */
    function maxWithdraw(address owner_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of shares that would be minted in a `deposit` call in the same transaction.
     *          MUST NOT account for deposit limits like those returned from `maxDeposit` and should always act as though the deposit would be accepted.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to deposit.
     *  @return shares_ The amount of shares that would be minted.
     */
    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of assets that would be deposited in a `mint` call in the same transaction.
     *          MUST NOT account for mint limits like those returned from `maxMint` and should always act as though the minting would be accepted.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to mint.
     *  @return assets_ The amount of assets that would be deposited.
     */
    function previewMint(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of assets that would be withdrawn in a `redeem` call in the same transaction.
     *          MUST NOT account for redemption limits like those returned from `maxRedeem` and should always act as though the redemption would be accepted.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to redeem.
     *  @return assets_ The amount of assets that would be withdrawn.
     */
    function previewRedeem(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of shares that would be burned in a `withdraw` call in the same transaction.
     *          MUST NOT account for withdrawal limits like those returned from `maxWithdraw` and should always act as though the withdrawal would be accepted.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to withdraw.
     *  @return shares_ The amount of shares that would be redeemed.
     */
    function previewWithdraw(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Total amount of the underlying asset that is managed by the Vault.
     *          SHOULD include compounding that occurs from any yields.
     *          MUST NOT revert.
     *  @return totalAssets_ The total amount of assets the Vault manages.
     */
    function totalAssets() external view returns (uint256 totalAssets_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { IERC20 } from "erc20/interfaces/IERC20.sol";

import { IERC4626 } from "./IERC4626.sol";

/// @title A token that represents ownership of future revenues distributed linearly over time.
interface IRevenueDistributionToken is IERC20, IERC4626 {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   Issuance parameters have been updated after a `_mint` or `_burn`.
     *  @param freeAssets_   Resulting `freeAssets` (y-intercept) value after accounting update.
     *  @param issuanceRate_ The new issuance rate of `asset` until `vestingPeriodFinish_`.
     */
    event IssuanceParamsUpdated(uint256 freeAssets_, uint256 issuanceRate_);

    /**
     *  @dev   `newOwner_` has accepted the transferral of RDT ownership from `previousOwner_`.
     *  @param previousOwner_ The previous RDT owner.
     *  @param newOwner_      The new RDT owner.
     */
    event OwnershipAccepted(address indexed previousOwner_, address indexed newOwner_);

    /**
     *  @dev   `owner_` has set the new pending owner of RDT to `pendingOwner_`.
     *  @param owner_        The current RDT owner.
     *  @param pendingOwner_ The new pending RDT owner.
     */
    event PendingOwnerSet(address indexed owner_, address indexed pendingOwner_);

    /**
     *  @dev   `owner_` has updated the RDT vesting schedule to end at `vestingPeriodFinish_`.
     *  @param owner_               The current RDT owner.
     *  @param vestingPeriodFinish_ When the unvested balance will finish vesting.
     */
    event VestingScheduleUpdated(address indexed owner_, uint256 vestingPeriodFinish_);

    /***********************/
    /*** State Variables ***/
    /***********************/

    /**
     *  @dev The total amount of the underlying asset that is currently unlocked and is not time-dependent.
     *       Analogous to the y-intercept in a linear function.
     */
    function freeAssets() external view returns (uint256 freeAssets_);

    /**
     *  @dev The rate of issuance of the vesting schedule that is currently active.
     *       Denominated as the amount of underlying assets vesting per second.
     */
    function issuanceRate() external view returns (uint256 issuanceRate_);

    /**
     *  @dev The timestamp of when the linear function was last recalculated.
     *       Analogous to t0 in a linear function.
     */
    function lastUpdated() external view returns (uint256 lastUpdated_);

    /**
     *  @dev The address of the account that is allowed to update the vesting schedule.
     */
    function owner() external view returns (address owner_);

    /**
     *  @dev The next owner, nominated by the current owner.
     */
    function pendingOwner() external view returns (address pendingOwner_);

    /**
     *  @dev The precision at which the issuance rate is measured.
     */
    function precision() external view returns (uint256 precision_);

    /**
     *  @dev The end of the current vesting schedule.
     */
    function vestingPeriodFinish() external view returns (uint256 vestingPeriodFinish_);

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    /**
     *  @dev Sets the pending owner as the new owner.
     *       Can be called only by the pending owner, and only after their nomination by the current owner.
     */
    function acceptOwnership() external;

    /**
     *  @dev   Sets a new address as the pending owner.
     *  @param pendingOwner_ The address of the next potential owner.
     */
    function setPendingOwner(address pendingOwner_) external;

    /**
     *  @dev    Updates the current vesting formula based on the amount of total unvested funds in the contract and the new `vestingPeriod_`.
     *  @param  vestingPeriod_ The amount of time over which all currently unaccounted underlying assets will be vested over.
     *  @return issuanceRate_  The new issuance rate.
     *  @return freeAssets_    The new amount of underlying assets that are unlocked.
     */
    function updateVestingSchedule(uint256 vestingPeriod_) external returns (uint256 issuanceRate_, uint256 freeAssets_);

    /************************/
    /*** Staker Functions ***/
    /************************/

    /**
     *  @dev    Does a ERC4626 `deposit` with a ERC-2612 `permit`.
     *  @param  assets_   The amount of `asset` to deposit.
     *  @param  receiver_ The receiver of the shares.
     *  @param  deadline_ The timestamp after which the `permit` signature is no longer valid.
     *  @param  v_        ECDSA signature v component.
     *  @param  r_        ECDSA signature r component.
     *  @param  s_        ECDSA signature s component.
     *  @return shares_   The amount of shares minted.
     */
    function depositWithPermit(uint256 assets_, address receiver_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) external returns (uint256 shares_);

    /**
     *  @dev    Does a ERC4626 `mint` with a ERC-2612 `permit`.
     *  @param  shares_    The amount of `shares` to mint.
     *  @param  receiver_  The receiver of the shares.
     *  @param  maxAssets_ The maximum amount of assets that can be taken, as per the permit.
     *  @param  deadline_  The timestamp after which the `permit` signature is no longer valid.
     *  @param  v_         ECDSA signature v component.
     *  @param  r_         ECDSA signature r component.
     *  @param  s_         ECDSA signature s component.
     *  @return assets_    The amount of shares deposited.
     */
    function mintWithPermit(uint256 shares_, address receiver_, uint256 maxAssets_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) external returns (uint256 assets_);


    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    Returns the amount of underlying assets owned by the specified account.
     *  @param  account_ Address of the account.
     *  @return assets_  Amount of assets owned.
     */
    function balanceOfAssets(address account_) external view returns (uint256 assets_);

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import {ERC20} from "erc20/ERC20.sol";
import {RevenueDistributionToken} from "revenue-distribution-token/RevenueDistributionToken.sol";
import {LockedRevenueDistributionToken} from "./LockedRevenueDistributionToken.sol";
import {IGovernanceLockedRevenueDistributionToken} from "./interfaces/IGovernanceLockedRevenueDistributionToken.sol";
import {Math} from "./libraries/Math.sol";

/*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░██████╗░██╗░░░░░██████╗░██████╗░████████╗░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░██╔════╝░██║░░░░░██╔══██╗██╔══██╗╚══██╔══╝░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░██║░░██╗░██║░░░░░██████╔╝██║░░██║░░░██║░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░██║░░╚██╗██║░░░░░██╔══██╗██║░░██║░░░██║░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░╚██████╔╝███████╗██║░░██║██████╔╝░░░██║░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░                                                                       ░░░░
░░░░            Governance Locked Revenue Distribution Token               ░░░░
░░░░                                                                       ░░░░
░░░░  Extending LockedRevenueDistributionToken with Compound governance,   ░░░░
░░░░  using OpenZeppelin's ERC20VotesComp implementation.                  ░░░░
░░░░                                                                       ░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

/**
 * @title  ERC-4626 revenue distribution vault with locking and Compound-compatible governance.
 * @notice Tokens are locked and must be subject to time-based or fee-based withdrawal conditions.
 * @dev    Voting power applies to the the total asset balance, including assets reserved for withdrawal.
 * @dev    Limited to a maximum asset supply of uint96.
 * @author GET Protocol DAO
 * @author Uses Maple's RevenueDistributionToken v1.0.1 under AGPL-3.0 (https://github.com/maple-labs/revenue-distribution-token/tree/v1.0.1)
 * @author Uses OpenZeppelin's ERC20Votes and ERC20VotesComp v4.8.0-rc.1 under MIT (https://github.com/OpenZeppelin/openzeppelin-contracts/tree/v4.8.0-rc.1/)
 */
contract GovernanceLockedRevenueDistributionToken is
    IGovernanceLockedRevenueDistributionToken,
    LockedRevenueDistributionToken
{
    // DELEGATE_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
    bytes32 private constant DELEGATE_TYPEHASH = 0xe48329057bfd03d55e49b547132e39cffd9c1820ad7b9d4c5307691425d15adf;

    mapping(address => address) public delegates;
    mapping(address => Checkpoint[]) public override userCheckpoints;
    Checkpoint[] private totalSupplyCheckpoints;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        address asset_,
        uint256 precision_,
        uint256 instantWithdrawalFee_,
        uint256 lockTime_,
        uint256 initialSeed_
    )
        LockedRevenueDistributionToken(
            name_,
            symbol_,
            owner_,
            asset_,
            precision_,
            instantWithdrawalFee_,
            lockTime_,
            initialSeed_
        )
    {}

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Public Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function delegate(address delegatee_) external virtual override {
        _delegate(msg.sender, delegatee_);
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     * @dev Equivalent to the OpenZeppelin implementation but written in style of ERC20.permit.
     */
    function delegateBySig(address delegatee_, uint256 nonce_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
        public
        virtual
        override
    {
        require(deadline_ >= block.timestamp, "GLRDT:DBS:EXPIRED");

        // Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}.
        require(
            uint256(s_) <= uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0)
                && (v_ == 27 || v_ == 28),
            "GLRDT:DBS:MALLEABLE"
        );

        bytes32 digest_ = keccak256(
            abi.encodePacked(
                "\x19\x01", DOMAIN_SEPARATOR(), keccak256(abi.encode(DELEGATE_TYPEHASH, delegatee_, nonce_, deadline_))
            )
        );

        address recoveredAddress_ = ecrecover(digest_, v_, r_, s_);

        require(recoveredAddress_ != address(0), "GLRDT:DBS:INVALID_SIGNATURE");

        // Nonce realistically cannot overflow.
        unchecked {
            require(nonce_ == nonces[recoveredAddress_]++, "GLRDT:DBS:INVALID_NONCE");
        }

        _delegate(recoveredAddress_, delegatee_);
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                          View Functions                           ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function convertToAssets(uint256 shares_, uint256 blockNumber_)
        public
        view
        virtual
        override
        returns (uint256 assets_)
    {
        (uint256 totalSupply_, uint256 totalAssets_) = _checkpointsLookup(totalSupplyCheckpoints, blockNumber_);
        assets_ = totalSupply_ == 0 ? shares_ : (shares_ * totalAssets_) / totalSupply_;
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function checkpoints(address account_, uint32 pos_)
        external
        view
        virtual
        override
        returns (uint32 fromBlock_, uint96 votes_)
    {
        Checkpoint memory checkpoint_ = userCheckpoints[account_][pos_];
        fromBlock_ = checkpoint_.fromBlock;
        votes_ = checkpoint_.assets;
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function numCheckpoints(address account_) public view virtual override returns (uint32 numCheckpoints_) {
        numCheckpoints_ = _toUint32(userCheckpoints[account_].length);
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function getVotes(address account_) public view virtual override returns (uint256 votes_) {
        uint256 pos_ = userCheckpoints[account_].length;
        if (pos_ == 0) {
            return 0;
        }
        uint256 shares_ = userCheckpoints[account_][pos_ - 1].shares;
        votes_ = convertToAssets(shares_, block.number);
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function getCurrentVotes(address account_) external view virtual override returns (uint96 votes_) {
        votes_ = _toUint96(getVotes(account_));
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function getPastVotes(address account_, uint256 blockNumber_)
        public
        view
        virtual
        override
        returns (uint256 votes_)
    {
        require(blockNumber_ < block.number, "GLRDT:BLOCK_NOT_MINED");
        (uint256 shares_,) = _checkpointsLookup(userCheckpoints[account_], blockNumber_);
        votes_ = convertToAssets(shares_, blockNumber_);
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */

    function getPriorVotes(address account_, uint256 blockNumber_)
        external
        view
        virtual
        override
        returns (uint96 votes_)
    {
        votes_ = _toUint96(getPastVotes(account_, blockNumber_));
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function getPastTotalSupply(uint256 blockNumber_) external view virtual override returns (uint256 totalSupply_) {
        require(blockNumber_ < block.number, "GLRDT:BLOCK_NOT_MINED");
        (totalSupply_,) = _checkpointsLookup(totalSupplyCheckpoints, blockNumber_);
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                        Internal Functions                         ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(uint256 shares_, uint256 assets_, address receiver_, address caller_) internal virtual override {
        super._mint(shares_, assets_, receiver_, caller_);
        _moveVotingPower(address(0), delegates[receiver_], shares_);
        _writeCheckpoint(totalSupplyCheckpoints, _add, shares_);
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(uint256 shares_, uint256 assets_, address receiver_, address owner_, address caller_)
        internal
        virtual
        override
    {
        super._burn(shares_, assets_, receiver_, owner_, caller_);
        _moveVotingPower(delegates[owner_], address(0), shares_);
        _writeCheckpoint(totalSupplyCheckpoints, _subtract, shares_);
    }

    /**
     * @inheritdoc ERC20
     * @dev Move voting power on transfer.
     */
    function _transfer(address owner_, address recipient_, uint256 amount_) internal virtual override {
        super._transfer(owner_, recipient_, amount_);
        _moveVotingPower(delegates[owner_], delegates[recipient_], amount_);
    }

    /**
     * @notice Change delegation for delegator to delegatee.
     * @param  delegator_ Account to transfer delegate balance from.
     * @param  delegatee_ Account to transfer delegate balance to.
     */
    function _delegate(address delegator_, address delegatee_) internal virtual {
        address currentDelegate_ = delegates[delegator_];
        uint256 delegatorBalance_ = balanceOf[delegator_];
        delegates[delegator_] = delegatee_;

        emit DelegateChanged(delegator_, currentDelegate_, delegatee_);

        _moveVotingPower(currentDelegate_, delegatee_, delegatorBalance_);
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Private Functions                         ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Lookup a value in a list of (sorted) checkpoints.
     * @param  ckpts        List of checkpoints to find within.
     * @param  blockNumber_ Block number of latest checkpoint.
     * @param  shares_      Amount of shares at checkpoint.
     * @param  assets_      Amount of assets at checkpoint.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber_)
        private
        view
        returns (uint96 shares_, uint96 assets_)
    {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber_`.
        //
        // Initially we check if the block is recent to narrow the search range.
        // During the loop, the index of the wanted checkpoint remains in the range [low_-1, high_).
        // With each iteration, either `low_` or `high_` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber_`, we look in [low_, mid_)
        // - If the middle checkpoint is before or equal to `blockNumber_`, we look in [mid_+1, high_)
        // Once we reach a single value (when low_ == high_), we've found the right checkpoint at the index high_-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber_`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber_`, but it works out
        // the same.
        uint256 length_ = ckpts.length;

        uint256 low_ = 0;
        uint256 high_ = length_;

        if (length_ > 5) {
            uint256 mid_ = length_ - Math.sqrt(length_);
            if (_unsafeAccess(ckpts, mid_).fromBlock > blockNumber_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);
            if (_unsafeAccess(ckpts, mid_).fromBlock > blockNumber_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        if (high_ == 0) {
            return (0, 0);
        }

        Checkpoint memory checkpoint_ = _unsafeAccess(ckpts, high_ - 1);
        return (checkpoint_.shares, checkpoint_.assets);
    }

    /**
     * @notice Move voting power from one account to another.
     * @param  src_    Source account to withdraw voting power from.
     * @param  dst_    Destination account to deposit voting power to.
     * @param  amount_ Ammont of voring power to move, measured in shares.
     */
    function _moveVotingPower(address src_, address dst_, uint256 amount_) private {
        if (src_ != dst_ && amount_ > 0) {
            if (src_ != address(0)) {
                (uint256 oldWeight_, uint256 newWeight_) = _writeCheckpoint(userCheckpoints[src_], _subtract, amount_);
                emit DelegateVotesChanged(src_, oldWeight_, newWeight_);
            }

            if (dst_ != address(0)) {
                (uint256 oldWeight_, uint256 newWeight_) = _writeCheckpoint(userCheckpoints[dst_], _add, amount_);
                emit DelegateVotesChanged(dst_, oldWeight_, newWeight_);
            }
        }
    }

    /**
     * @notice Compute and store a checkpoint within a Checkpoints array. Delta applied to share balance.
     * @param  ckpts      List of checkpoints to add to.
     * @param  op_        Function reference of mathematical operation to apply to delta. Either add or subtract.
     * @param  delta_     Delta between previous checkpoint's shares and new checkpoint's shares.
     * @return oldWeight_ Previous share balance.
     * @return newWeight_ New share balance.
     */
    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op_,
        uint256 delta_
    ) private returns (uint256 oldWeight_, uint256 newWeight_) {
        uint256 pos_ = ckpts.length;

        Checkpoint memory oldCkpt_ = pos_ == 0 ? Checkpoint(0, 0, 0) : _unsafeAccess(ckpts, pos_ - 1);

        oldWeight_ = oldCkpt_.shares;
        newWeight_ = op_(oldWeight_, delta_);

        if (pos_ > 0 && oldCkpt_.fromBlock == block.number) {
            _unsafeAccess(ckpts, pos_ - 1).shares = _toUint96(newWeight_);
            _unsafeAccess(ckpts, pos_ - 1).assets = _toUint96(convertToAssets(newWeight_));
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: _toUint32(block.number),
                    shares: _toUint96(newWeight_),
                    assets: _toUint96(convertToAssets(newWeight_))
                })
            );
        }
    }

    /**
     * @notice Computes the sum of two numbers.
     * @param  a_      First number.
     * @param  b_      Second number.
     * @return result_ Sum of first and second numbers.
     */
    function _add(uint256 a_, uint256 b_) private pure returns (uint256 result_) {
        return a_ + b_;
    }

    /**
     * @notice Subtracts the second number from the first.
     * @param  a_      First number.
     * @param  b_      Second number.
     * @return result_ Result of first number minus second number.
     */
    function _subtract(uint256 a_, uint256 b_) private pure returns (uint256 result_) {
        return a_ - b_;
    }
    /**
     * @notice Returns the downcasted uint32 from uint256, reverting on overflow (when the input is greater than
     * largest uint32). Counterpart to Solidity's `uint32` operator.
     * @param  value_ Input value to cast.
     */

    function _toUint32(uint256 value_) private pure returns (uint32) {
        require(value_ <= type(uint32).max, "GLRDT:CAST_EXCEEDS_32_BITS");
        return uint32(value_);
    }

    /**
     * @notice Returns the downcasted uint96 from uint256, reverting on overflow (when the input is greater than
     * largest uint96). Counterpart to Solidity's `uint96` operator.
     * @param  value_ Input value to cast.
     */
    function _toUint96(uint256 value_) private pure returns (uint96) {
        require(value_ <= type(uint96).max, "GLRDT:CAST_EXCEEDS_96_BITS");
        return uint96(value_);
    }

    /**
     * @notice Optimize accessing checkpoints from storage.
     * @dev    Added to OpenZeppelin v4.8.0-rc.0 (https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3673)
     * @param  ckpts  Checkpoints array in storage to access.
     * @param  pos_   Index/position of the checkpoint.
     * @return result Checkpoint found at position in array.
     */
    function _unsafeAccess(Checkpoint[] storage ckpts, uint256 pos_) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, ckpts.slot)
            result.slot := add(keccak256(0, 0x20), pos_)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import {RevenueDistributionToken} from "revenue-distribution-token/RevenueDistributionToken.sol";
import {ERC20} from "erc20/ERC20.sol";
import {ERC20Helper} from "erc20-helper/ERC20Helper.sol";
import {ILockedRevenueDistributionToken} from "./interfaces/ILockedRevenueDistributionToken.sol";

/*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██╗░░░░░██████╗░██████╗░████████╗░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██║░░░░░██╔══██╗██╔══██╗╚══██╔══╝░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██║░░░░░██████╔╝██║░░██║░░░██║░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░██║░░░░░██╔══██╗██║░░██║░░░██║░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░███████╗██║░░██║██████╔╝░░░██║░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░╚══════╝╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░                                                                       ░░░░
░░░░                  Locked Revenue Distribution Token                    ░░░░
░░░░                                                                       ░░░░
░░░░  Extending Maple's RevenueDistributionToken with time-based locking,  ░░░░
░░░░  fee-based instant withdrawals and public vesting schedule updating.  ░░░░
░░░░                                                                       ░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

/**
 * @title  ERC-4626 revenue distribution vault with locking.
 * @notice Tokens are locked and must be subject to time-based or fee-based withdrawal conditions.
 * @dev    Limited to a maximum asset supply of uint96.
 * @author GET Protocol DAO
 * @author Uses Maple's RevenueDistributionToken v1.0.1 under AGPL-3.0 (https://github.com/maple-labs/revenue-distribution-token/tree/v1.0.1)
 */
contract LockedRevenueDistributionToken is ILockedRevenueDistributionToken, RevenueDistributionToken {
    uint256 public constant override MAXIMUM_LOCK_TIME = 104 weeks;
    uint256 public constant override VESTING_PERIOD = 2 weeks;
    uint256 public constant override WITHDRAWAL_WINDOW = 4 weeks;
    uint256 public override instantWithdrawalFee;
    uint256 public override lockTime;

    mapping(address => WithdrawalRequest[]) internal userWithdrawalRequests;
    mapping(address => bool) public override withdrawalFeeExemptions;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        address asset_,
        uint256 precision_,
        uint256 instantWithdrawalFee_,
        uint256 lockTime_,
        uint256 initialSeed_
    ) RevenueDistributionToken(name_, symbol_, owner_, asset_, precision_) {
        instantWithdrawalFee = instantWithdrawalFee_;
        lockTime = lockTime_;

        // We initialize the contract by seeding an amount of shares and then burning them. This prevents donation
        // attacks from affecting the precision of the shares:assets rate.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706
        if (initialSeed_ > 0) {
            address caller_ = msg.sender;
            address receiver_ = address(0);

            // RDT.deposit() cannot be called within the constructor as this uses immutable variables.
            // ERC20._mint()
            totalSupply += initialSeed_;
            unchecked {
                balanceOf[receiver_] += initialSeed_;
            }
            emit Transfer(address(0), receiver_, initialSeed_);

            // RDT._mint()
            freeAssets = initialSeed_;
            emit Deposit(caller_, receiver_, initialSeed_, initialSeed_);
            emit IssuanceParamsUpdated(freeAssets, 0);
            require(ERC20Helper.transferFrom(asset_, msg.sender, address(this), initialSeed_), "LRDT:C:TRANSFER_FROM");
        }
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                     Administrative Functions                      ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function setInstantWithdrawalFee(uint256 percentage_) external virtual override {
        require(msg.sender == owner, "LRDT:CALLER_NOT_OWNER");
        require(percentage_ < 100, "LRDT:INVALID_FEE");

        instantWithdrawalFee = percentage_;

        emit InstantWithdrawalFeeChanged(percentage_);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function setLockTime(uint256 lockTime_) external virtual override {
        require(msg.sender == owner, "LRDT:CALLER_NOT_OWNER");
        require(lockTime_ <= MAXIMUM_LOCK_TIME, "LRDT:INVALID_LOCK_TIME");

        lockTime = lockTime_;

        emit LockTimeChanged(lockTime_);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function setWithdrawalFeeExemption(address account_, bool status_) external virtual override {
        require(msg.sender == owner, "LRDT:CALLER_NOT_OWNER");
        require(account_ != address(0), "LRDT:ZERO_ACCOUNT");

        if (status_) {
            withdrawalFeeExemptions[account_] = true;
        } else {
            delete withdrawalFeeExemptions[account_];
        }

        emit WithdrawalFeeExemptionStatusChanged(account_, status_);
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Public Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function createWithdrawalRequest(uint256 shares_) external virtual override nonReentrant {
        require(shares_ > 0, "LRDT:INVALID_AMOUNT");
        require(shares_ <= balanceOf[msg.sender], "LRDT:INSUFFICIENT_BALANCE");

        WithdrawalRequest memory request_ = WithdrawalRequest(
            uint32(block.timestamp + lockTime), uint32(lockTime), uint96(shares_), uint96(convertToAssets(shares_))
        );
        userWithdrawalRequests[msg.sender].push(request_);

        _transfer(msg.sender, address(this), shares_);

        emit WithdrawalRequestCreated(request_, userWithdrawalRequests[msg.sender].length - 1);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function cancelWithdrawalRequest(uint256 pos_) external virtual override nonReentrant {
        WithdrawalRequest memory request_ = userWithdrawalRequests[msg.sender][pos_];
        require(request_.shares > 0, "LRDT:NO_WITHDRAWAL_REQUEST");

        delete userWithdrawalRequests[msg.sender][pos_];

        uint256 refundShares_ = convertToShares(request_.assets);
        uint256 burnShares_ = request_.shares - refundShares_;

        if (burnShares_ > 0) {
            uint256 burnAssets_ = convertToAssets(burnShares_);
            _burn(burnShares_, burnAssets_, address(this), address(this), address(this));
            emit Redistribute(burnAssets_);
        }

        if (refundShares_ > 0) {
            _transfer(address(this), msg.sender, refundShares_);
            emit Refund(msg.sender, convertToAssets(refundShares_), refundShares_);
        }

        emit WithdrawalRequestCancelled(pos_);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function executeWithdrawalRequest(uint256 pos_) external virtual override nonReentrant {
        (WithdrawalRequest memory request_, uint256 assets_, uint256 fee_) = previewWithdrawalRequest(pos_, msg.sender);
        require(request_.shares > 0, "LRDT:NO_WITHDRAWAL_REQUEST");
        require(request_.unlockedAt + WITHDRAWAL_WINDOW > block.timestamp, "LRDT:WITHDRAWAL_WINDOW_CLOSED");

        delete userWithdrawalRequests[msg.sender][pos_];

        uint256 executeShares_ = convertToShares(assets_);
        uint256 burnShares_ = request_.shares - executeShares_;

        if (burnShares_ > 0) {
            uint256 burnAssets_ = convertToAssets(burnShares_);
            _burn(burnShares_, burnAssets_, address(this), address(this), address(this));
            emit Redistribute(burnAssets_ - fee_);
        }

        if (executeShares_ > 0) {
            _transfer(address(this), msg.sender, executeShares_);
            _burn(executeShares_, assets_, msg.sender, msg.sender, msg.sender);
        }

        if (fee_ > 0) {
            emit WithdrawalFeePaid(msg.sender, msg.sender, msg.sender, fee_);
        }

        emit WithdrawalRequestExecuted(pos_);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function updateVestingSchedule() external virtual override returns (uint256 issuanceRate_, uint256 freeAssets_) {
        // This require is here to prevent public function calls extending the vesting period infinitely. By allowing
        // this to be called again on the last day of the vesting period, we can maintain a regular schedule of reward
        // distribution on the same day of the week.
        //
        // Aside from the following line, and a fixed vesting period, this function is unchanged from the Maple
        // implementation.
        require(vestingPeriodFinish <= block.timestamp + 24 hours, "LRDT:UVS:STILL_VESTING");
        require(totalSupply > 0, "LRDT:UVS:ZERO_SUPPLY");

        // Update "y-intercept" to reflect current available asset.
        freeAssets_ = (freeAssets = totalAssets());

        // Carry over remaining time.
        uint256 vestingTime_ = VESTING_PERIOD;
        if (vestingPeriodFinish > block.timestamp) {
            vestingTime_ = VESTING_PERIOD + (vestingPeriodFinish - block.timestamp);
        }

        // Calculate slope.
        issuanceRate_ =
            (issuanceRate = ((ERC20(asset).balanceOf(address(this)) - freeAssets_) * precision) / vestingTime_);

        require(issuanceRate_ > 0, "LRDT:UVS:ZERO_ISSUANCE_RATE");

        // Update timestamp and period finish.
        vestingPeriodFinish = (lastUpdated = block.timestamp) + vestingTime_;

        emit IssuanceParamsUpdated(freeAssets_, issuanceRate_);
        emit VestingScheduleUpdated(msg.sender, vestingPeriodFinish);
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     * @dev Reentrancy modifier provided within the internal function call.
     */
    function deposit(uint256 assets_, address receiver_, uint256 minShares_)
        external
        virtual
        override
        returns (uint256 shares_)
    {
        shares_ = deposit(assets_, receiver_);
        require(shares_ >= minShares_, "LRDT:D:SLIPPAGE_PROTECTION");
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     * @dev Reentrancy modifier provided within the internal function call.
     */
    function mint(uint256 shares_, address receiver_, uint256 maxAssets_)
        external
        virtual
        override
        returns (uint256 assets_)
    {
        assets_ = mint(shares_, receiver_);
        require(assets_ <= maxAssets_, "LRDT:M:SLIPPAGE_PROTECTION");
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Will check for withdrawal fee exemption present on owner.
     */
    function redeem(uint256 shares_, address receiver_, address owner_)
        public
        virtual
        override
        nonReentrant
        returns (uint256 assets_)
    {
        uint256 fee_;
        (assets_, fee_) = previewRedeem(shares_, owner_);
        _burn(shares_, assets_, receiver_, owner_, msg.sender);

        if (fee_ > 0) {
            emit WithdrawalFeePaid(msg.sender, receiver_, owner_, fee_);
        }
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     * @dev Reentrancy modifier provided within the internal function call.
     */
    function redeem(uint256 shares_, address receiver_, address owner_, uint256 minAssets_)
        external
        virtual
        override
        returns (uint256 assets_)
    {
        assets_ = redeem(shares_, receiver_, owner_);
        require(assets_ >= minAssets_, "LRDT:R:SLIPPAGE_PROTECTION");
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Will check for withdrawal fee exemption present on owner.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_)
        public
        virtual
        override
        nonReentrant
        returns (uint256 shares_)
    {
        uint256 fee_;
        (shares_, fee_) = previewWithdraw(assets_, owner_);
        _burn(shares_, assets_, receiver_, owner_, msg.sender);

        if (fee_ > 0) {
            emit WithdrawalFeePaid(msg.sender, receiver_, owner_, fee_);
        }
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     * @dev Reentrancy modifier provided within the internal function call.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_, uint256 maxShares_)
        external
        virtual
        override
        returns (uint256 shares_)
    {
        shares_ = withdraw(assets_, receiver_, owner_);
        require(shares_ <= maxShares_, "LRDT:W:SLIPPAGE_PROTECTION");
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                          View Functions                           ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Returns the amount of redeemable assets for given shares after instant withdrawal fee.
     * @dev `address(0)` cannot be set as exempt, and is used here as default to imply that fees must be deducted.
     */
    function previewRedeem(uint256 shares_) public view virtual override returns (uint256 assets_) {
        (assets_,) = previewRedeem(shares_, address(0));
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function previewRedeem(uint256 shares_, address owner_)
        public
        view
        virtual
        override
        returns (uint256 assets_, uint256 fee_)
    {
        if (withdrawalFeeExemptions[owner_]) {
            return (super.previewRedeem(shares_), 0);
        }

        uint256 assetsPlusFee_ = super.previewRedeem(shares_);
        assets_ = (assetsPlusFee_ * (100 - instantWithdrawalFee)) / 100;
        fee_ = assetsPlusFee_ - assets_;
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Returns the amount of redeemable assets for given shares after instant withdrawal fee.
     * @dev `address(0)` cannot be set as exempt, and is used here as default to imply that fees must be deducted.
     */
    function previewWithdraw(uint256 assets_) public view virtual override returns (uint256 shares_) {
        (shares_,) = previewWithdraw(assets_, address(0));
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function previewWithdraw(uint256 assets_, address owner_)
        public
        view
        virtual
        override
        returns (uint256 shares_, uint256 fee_)
    {
        if (withdrawalFeeExemptions[owner_]) {
            return (super.previewWithdraw(assets_), 0);
        }

        uint256 assetsPlusFee_ = (assets_ * 100) / (100 - instantWithdrawalFee);
        shares_ = super.previewWithdraw(assetsPlusFee_);
        fee_ = assetsPlusFee_ - assets_;
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function previewWithdrawalRequest(uint256 pos_, address owner_)
        public
        view
        virtual
        override
        returns (WithdrawalRequest memory request_, uint256 assets_, uint256 fee_)
    {
        request_ = userWithdrawalRequests[owner_][pos_];

        if (withdrawalFeeExemptions[owner_] || request_.unlockedAt <= block.timestamp) {
            return (request_, request_.assets, 0);
        }

        uint256 remainingTime_ = request_.unlockedAt - block.timestamp;
        uint256 feePercentage_ = (instantWithdrawalFee * remainingTime_ * precision) / request_.lockTime;
        assets_ = (request_.assets * (100 * precision - feePercentage_)) / (100 * precision);
        fee_ = request_.assets - assets_;
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Restricted to uint96 as defined in WithdrawalRequest struct.
     */
    function maxDeposit(address receiver_) external pure virtual override returns (uint256 maxAssets_) {
        receiver_; // Silence warning
        maxAssets_ = type(uint96).max;
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Restricted to uint96 as defined in WithdrawalRequest struct.
     */
    function maxMint(address receiver_) external pure virtual override returns (uint256 maxShares_) {
        receiver_; // Silence warning
        maxShares_ = type(uint96).max;
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function withdrawalRequestCount(address owner_) external view virtual override returns (uint256 count_) {
        count_ = userWithdrawalRequests[owner_].length;
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function withdrawalRequests(address owner_)
        external
        view
        virtual
        override
        returns (WithdrawalRequest[] memory withdrawalRequests_)
    {
        withdrawalRequests_ = userWithdrawalRequests[owner_];
    }

    /**
     * @inheritdoc ILockedRevenueDistributionToken
     */
    function withdrawalRequests(address account_, uint256 pos_)
        external
        view
        virtual
        override
        returns (WithdrawalRequest memory withdrawalRequest_)
    {
        withdrawalRequest_ = userWithdrawalRequests[account_][pos_];
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

interface IGovernanceLockedRevenueDistributionToken {
    /**
     * @notice        Represents a voting checkpoin, packed into a single word.
     * @custom:member fromBlock Block number after which the checkpoint applies.
     * @custom:member shares    Amount of shares held & delegated to calculate point-in-time votes.
     * @custom:member assets    Amount of assets held & delegated to calculate point-in-time votes.
     */
    struct Checkpoint {
        uint32 fromBlock;
        uint96 shares;
        uint96 assets;
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                              Events                               ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Emitted when an account changes their delegate.
     * @param  delegator_    Account that has changed delegate.
     * @param  fromDelegate_ Previous delegate.
     * @param  toDelegate_   New delegate.
     */
    event DelegateChanged(address indexed delegator_, address indexed fromDelegate_, address indexed toDelegate_);

    /**
     * @notice Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     * @param  delegate_        Delegate that has received delegated balance change.
     * @param  previousBalance_ Previous delegated balance.
     * @param  newBalance_      New delegated balance.
     */
    event DelegateVotesChanged(address indexed delegate_, uint256 previousBalance_, uint256 newBalance_);

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                          State Variables                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Get the `pos`-th checkpoint for `account`.
     * @dev    Unused in Compound governance specification, exposes underlying Checkpoint struct.
     * @param  account_   Account that holds checkpoint.
     * @param  pos_       Index/position of the checkpoint.
     * @return fromBlock  Block in which the checkpoint is valid from.
     * @return shares     Total amount of shares within the checkpoint.
     * @return assets     Total amount of underlying assets derived from shares at time of checkpoint.
     */
    function userCheckpoints(address account_, uint256 pos_)
        external
        view
        returns (uint32 fromBlock, uint96 shares, uint96 assets);

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Public Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Delegates votes from the sender to `delegatee`.
     * @dev    Shares are delegated upon mint and transfer and removed upon burn.
     * @param  delegatee_ Account to delegate votes to.
     */
    function delegate(address delegatee_) external;

    /**
     * @notice Delegates votes from signer to `delegatee`.
     * @param  delegatee_ Account to delegate votes to.
     * @param  nonce_     Nonce of next signature transaction, expected to be equal to `nonces(signer)`.
     * @param  deadline_  Deadline after which the permit is invalid.
     * @param  v_         ECDSA signature v component.
     * @param  r_         ECDSA signature r component.
     * @param  s_         ECDSA signature s component.
     */
    function delegateBySig(address delegatee_, uint256 nonce_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
        external;

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                          View Functions                           ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Historical conversion from shares to assets, used for calculating voting power on past blocks.
     * @param  shares_      Amount of shares to conver to assets.
     * @param  blockNumber_ Block to use for checkpoint lookup.
     * @return assets_      Amount of assets held at block, representing voting power.
     */
    function convertToAssets(uint256 shares_, uint256 blockNumber_) external view returns (uint256 assets_);

    /**
     * @notice Get the Compound-compatible `pos`-th checkpoint for `account`.
     * @dev    Maintains Compound `checkpoints` compatibility by returning votes as a uint96 and omitting shares.
     * @param  account_   Account that holds checkpoint.
     * @param  pos_       Index/position of the checkpoint.
     * @return fromBlock_ Block in which the checkpoint is valid from.
     * @return votes_     Total amount of underlying assets (votes) derived from shares.
     */
    function checkpoints(address account_, uint32 pos_) external view returns (uint32 fromBlock_, uint96 votes_);

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account_) external view returns (uint32);

    /**
     * @notice Returns the current amount of votes that `account` has.
     * @dev    The delegated balance is denominated in the amount of shares delegated to an account, but voting power
     * is measured in assets. A conversion is done using the delegated shares to get the assets as of the latest
     * checkpoint. This ensures that all stakers' shares are converted to assets at the same rate.
     * @param  account_ Address of account to get votes for.
     * @return votes_   Amount of voting power as the number of assets for delegated shares.
     */
    function getVotes(address account_) external view returns (uint256 votes_);

    /**
     * @notice Comp version of the `getVotes` accessor, with `uint96` return type.
     * @param  account_ Address of account to get votes for.
     * @return votes_   Amount of voting power as the number of assets for delegated shares.
     */
    function getCurrentVotes(address account_) external view returns (uint96 votes_);

    /**
     * @notice Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     * @param  account_     Address of account to get votes for.
     * @param  blockNumber_ Voting power at block.
     * @return votes_       Amount of voting power as the number of assets for delegated shares.
     */
    function getPastVotes(address account_, uint256 blockNumber_) external view returns (uint256 votes_);

    /**
     * @notice Comp version of the `getPastVotes` accessor, with `uint96` return type.
     * @param  account_     Address of account to get votes for.
     * @param  blockNumber_ Voting power at block.
     * @return votes_       Amount of voting power as the number of assets for delegated shares.
     */
    function getPriorVotes(address account_, uint256 blockNumber_) external view returns (uint96 votes_);

    /**
     * @notice Returns the total supply of shares available at the end of a past block (`blockNumber`).
     * @param  blockNumber_ Block number to check for total supply.
     * @return totalSupply_ Total supply of shares.
     */
    function getPastTotalSupply(uint256 blockNumber_) external view returns (uint256 totalSupply_);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

interface ILockedRevenueDistributionToken {
    /**
     * @notice        Represents a withdrawal request, packed into a single word.
     * @custom:member unlockedAt Timestamp after which the withdrawal is unlocked.
     * @custom:member shares     Amount of shares to be burned upon withdrawal execution.
     * @custom:member assets     Amount of assets to be returned to user upon withdrawal execution.
     */
    struct WithdrawalRequest {
        uint32 unlockedAt;
        uint32 lockTime;
        uint96 shares;
        uint96 assets;
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                              Events                               ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Emitted when burning shares upon withdrawal request cancellation.
     * @param  assets_ Amount of assets returned to contract address.
     * @param  shares_ Share delta between withdrawal request creation and cancellation.
     */
    event CancellationBurn(uint256 assets_, uint256 shares_);

    /**
     * @notice Emitted when the instant withdrawal fee is set.
     * @param  percentage_ A percentage value from 0 to 100.
     */
    event InstantWithdrawalFeeChanged(uint256 percentage_);

    /**
     * @notice Emitted when time-to-unlock for a standard withdrawal set.
     * @param  lockTime_ Integer length of lock time, e.g. `26 weeks`.
     */
    event LockTimeChanged(uint256 lockTime_);

    /**
     * @notice Emitted when redistributing rewards upon early execution or cancellation of a withdrawal request.
     * @param  assets_ Assets redistributed to remaining stakers.
     */
    event Redistribute(uint256 assets_);

    /**
     * @notice Emitted when refunding shares upon withdrawal request cancellation.
     * @param  receiver_   Account to refund shares to at spot rate.
     * @param  assets_     Equivalent asset value for shares returned.
     * @param  shares_     Amount of shares returned to the receiver.
     */
    event Refund(address indexed receiver_, uint256 assets_, uint256 shares_);

    /**
     * @notice Emitted when fee exemption status has been set for an address.
     * @param  account_ Address in which to apply the exemption.
     * @param  status_  True for exempt, false to remove exemption.
     */
    event WithdrawalFeeExemptionStatusChanged(address indexed account_, bool status_);

    /**
     * @notice Emitted when an instant withdrawal fee is paid.
     * @param  caller_   The caller of the `redeem` or `withdraw` function.
     * @param  receiver_ The receiver of the assets.
     * @param  owner_    The owner of the shares or withdrawal request.
     * @param  fee_      The assets paid as fee.
     */
    event WithdrawalFeePaid(address indexed caller_, address indexed receiver_, address indexed owner_, uint256 fee_);

    /**
     * @notice Emitted when a new withdrawal request has been created for an account.
     * @param  request_ Struct containing shares, assets, and maturity date of the created request.
     * @param  pos_   Index/position of the withdrawal request created.
     */
    event WithdrawalRequestCreated(WithdrawalRequest request_, uint256 pos_);

    /**
     * @notice Emitted when an account cancels any existing withdrawal requests.
     * @param  pos_   Index/position of the withdrawal request cancelled.
     */
    event WithdrawalRequestCancelled(uint256 pos_);

    /**
     * @notice Emitted when a withdrawal request has been executed with shares burned and assets withdrawn.
     * @param  pos_ Index/position of the withdrawal request executed.
     */
    event WithdrawalRequestExecuted(uint256 pos_);

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                          State Variables                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Constant maximum lock time able to be set using `setLockTime` to avoid permanent lockup.
     * @return maximumLockTime_ Maxmimum lock time integer length, e.g. `104 weeks`.
     */
    function MAXIMUM_LOCK_TIME() external view returns (uint256 maximumLockTime_);

    /**
     * @notice Constant vesting period, used in `updateVestingSchedule`.
     * @return vestingPeriod_ Fixed vesting period, e.g. `2 weeks`.
     */
    function VESTING_PERIOD() external view returns (uint256 vestingPeriod_);

    /**
     * @notice Constant time window in which unlocked withdrawal requests can be executed.
     * @return withdrawalWindow_ Fixed withdrawal window, e.g. `4 weeks`.
     */
    function WITHDRAWAL_WINDOW() external view returns (uint256 withdrawalWindow_);

    /**
     * @notice Percentage withdrawal fee to be applied to instant withdrawals.
     * @return instantWithdrawalFee_ A percentage value from 0 to 100.
     */
    function instantWithdrawalFee() external view returns (uint256 instantWithdrawalFee_);

    /**
     * @notice The lock time set for standard withdrawals to become unlocked.
     * @return lockTime_ Length of lock of a standard withdrawal request, e.g. `26 weeks`.
     */
    function lockTime() external view returns (uint256 lockTime_);

    /**
     * @notice Returns exemption status for a given account. When true then instant withdrawal fee will not apply.
     * @param  account_ Account to check for exemption.
     * @return status_  Exemption status.
     */
    function withdrawalFeeExemptions(address account_) external view returns (bool status_);

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                     Administrative Functions                      ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Sets the intstant withdrawal fee, applied when making instant withdrawals or redemptions.
     * @notice Can only be set by owner.
     * @param  percentage_ Fee percentage. Must be an integer between 0 and 100 inclusive.
     */
    function setInstantWithdrawalFee(uint256 percentage_) external;

    /**
     * @notice Sets the lock time for standard withdrawals to become unlocked.
     * @notice Can only be set by owner.
     * @notice Must be lower than MAXIMUM_LOCK_TIME to prevent permanent lockup.
     * @param  lockTime_ Length of lock of a standard withdrawal request.
     */
    function setLockTime(uint256 lockTime_) external;

    /**
     * @notice Sets or unsets an owner address to be exempt from the withdrawal fee.
     * @notice Useful in case of future migrations where an approved contract may be given permission to migrate
     * balances to a new token. Can also be used to exempt third-party vaults from facing withdrawal fee when
     * managing balances, such as lending platform liquidations.
     * @notice Can only be set by contract `owner`.
     * @dev    The zero address cannot be set as exmempt as this will always represent an address that pays fees.
     * @param  owner_  Owner address to exempt from instant withdrawal fees.
     * @param  status_ true to add exemption, false to remove exemption.
     */
    function setWithdrawalFeeExemption(address owner_, bool status_) external;

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Public Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Creates a new withdrawal request for future execution using the shares conversion at the point of
     * request. May only be executed after the unlock date.
     * @notice Transfers shares to the vault contract to reserve them, reducing share balance.
     * @param  shares_ Amount of shares to redeem upon unlock.
     */
    function createWithdrawalRequest(uint256 shares_) external;

    /**
     * @notice Removes an open withdrawal request for the sender.
     * @param  pos_ Index/position of the withdrawal request to be cancelled.
     */
    function cancelWithdrawalRequest(uint256 pos_) external;

    /**
     * @notice Executes an existing withdrawal request for msg.sender. Before the request is unlocked, a percentage
     * fee will be paid, equal to a percentage of the instantWithdrawalFee by time elapsed of the request.
     * @param  pos_ Index/position of the withdrawal request to be executed.
     */
    function executeWithdrawalRequest(uint256 pos_) external;

    /**
     * @notice Executes an existing withdrawal request that has passed its unlock date.
     * @dev    Identical to parent implementation but made public by fixed vesting period and removal of owner check.
     * @return issuanceRate_ Slope of release of newly added assets, scaled up by `precision`.
     * @return freeAssets_   Amount of assets currently released to stakers.
     */
    function updateVestingSchedule() external returns (uint256 issuanceRate_, uint256 freeAssets_);

    /**
     * @notice ERC5143 slippage-protected deposit method. The transaction will revert if the shares to be returned is
     * less than minShares_.
     * @param  assets_    Amount of assets to deposit.
     * @param  receiver_  The receiver of the shares.
     * @param  minShares_ Minimum amount of shares to be returned.
     * @return shares_    Amount of shares returned to receiver_.
     */
    function deposit(uint256 assets_, address receiver_, uint256 minShares_) external returns (uint256 shares_);

    /**
     * @notice ERC5143 slippage-protected mint method. The transaction will revert if the assets to be deducted is
     * greater than maxAssets_.
     * @param  shares_    Amount of shares to mint.
     * @param  receiver_  The receiver of the shares.
     * @param  maxAssets_ Maximum amount of assets to be deducted.
     * @return assets_    Amount of deducted when minting shares.
     */
    function mint(uint256 shares_, address receiver_, uint256 maxAssets_) external returns (uint256 assets_);

    /**
     * @notice ERC5143 slippage-protected redeem method. The transaction will revert if the assets to be returned is
     * less than minAssets_.
     * @param  shares_    Amount of shares to redeem.
     * @param  receiver_  The receiver of the assets.
     * @param  owner_     Owner of shares making redemption.
     * @param  minAssets_ Minimum amount of assets to be returned.
     * @return assets_    Amount of assets returned.
     */
    function redeem(uint256 shares_, address receiver_, address owner_, uint256 minAssets_)
        external
        returns (uint256 assets_);

    /**
     * @notice ERC5143 slippage-protected withdraw method. The transaction will revert if the shares to be deducted is
     * greater than maxShares_.
     * @param  assets_    Amount of assets to withdraw.
     * @param  receiver_  The receiver of the assets.
     * @param  owner_     Owner of shares making withdrawal.
     * @param  maxShares_ Minimum amount of shares to be deducted.
     * @return shares_    Amount of shares deducted.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_, uint256 maxShares_)
        external
        returns (uint256 shares_);

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                          View Functions                           ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Previews a redemption of shares for owner. Applies withdrawal fee if owner does not have an exemption.
     * @param  owner_  Owner of shares making redemption.
     * @param  shares_ Amount of shares to redeem.
     * @return assets_ Assets redeemed for shares for owner.
     * @param  fee_    The assets paid as fee.
     */
    function previewRedeem(uint256 shares_, address owner_) external view returns (uint256 assets_, uint256 fee_);

    /**
     * @notice Previews a withdrawal of assets for owner. Applies withdrawal fee if owner does not have an exemption.
     * @param  owner_  Owner of shares makeing withdrawal.
     * @param  assets_ Amount of assets to withdraw.
     * @return shares_ Shares needed to be burned for owner.
     * @param  fee_    The assets paid as fee.
     */
    function previewWithdraw(uint256 assets_, address owner_) external view returns (uint256 shares_, uint256 fee_);

    /**
     * @notice Previews a withdrawal request execution, calculating the assets returned to the receiver and fee paid.
     * @notice Fee percentage reduces linearly from instantWithdrawalFee until 0 at the unlockedAt timestamp.
     * @param  pos_     Index/position of the withdrawal request to be previewed.
     * @param  owner_   Owner of the withdrawal request.
     * @return request_ The WithdrawalRequest struct within storage.
     * @return assets_  Amount of assets returned to owner if withdrawn.
     * @return fee_     The assets paid as fee.
     */
    function previewWithdrawalRequest(uint256 pos_, address owner_)
        external
        view
        returns (WithdrawalRequest memory request_, uint256 assets_, uint256 fee_);

    /**
     * @notice Returns a count of the number of created withdrawal requests for an account, including cancelled.
     * @param  owner_ Account address of owner of withdrawal requests.
     * @return count_ Number of withdrawal request created for owner account.
     */
    function withdrawalRequestCount(address owner_) external view returns (uint256 count_);

    /**
     * @notice Returns an array of created withdrawal requests for an account, including cancelled.
     * @param  owner_    Account address of owner of withdrawal requests.
     * @return requests_ Array of withdrawal request structs for an owner.
     */
    function withdrawalRequests(address owner_) external view returns (WithdrawalRequest[] memory requests_);

    /**
     * @notice Returns existing withdrawal request for a given account.
     * @param  account_ Account address holding withdrawal request.
     * @param  pos_     Index/position of the withdrawal request in the array.
     * @return request_ Withdrawal request struct found at position for owner.
     */
    function withdrawalRequests(address account_, uint256 pos_)
        external
        view
        returns (WithdrawalRequest memory request_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Standard math utilities missing in the Solidity language.
 * @author Uses OpenZeppelin's Math.sol v4.7.0 under MIT (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/utils/math/Math.sol)
 */

library Math {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }
}