// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IAAOption.sol";
import "./interface/IAAOptionMarket.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./interface/IAAOptionBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interface/ITokenDecimals.sol";
import "./interface/ISwapRouter.sol";

contract AAOptionMarket is AccessControl, IAAOptionMarket{

    IAAOption internal optionToken;
    IERC20 internal quoteAsset;
    IERC20 internal baseAsset;
    IAAOptionBase internal optionProof;
    AggregatorV3Interface internal priceFeed;
    ISwapRouter internal uniswap;
    // 28800 8hours
    uint256 public freezeTradeBeforeSettle = 8 * 60 * 60 ;
    // 10000 means 1,default 100 means 0.01
    uint256 public uinSlippage = 100;

    bytes32 public constant MAKER_ROLE = keccak256("MAKER_ROLE");

    mapping(uint256 => AAOptionLockPool) public override optionLockPool;

    mapping(uint256 => uint80) public optionPriceRound;

    mapping(address => uint256) public override makerNonce;

    struct TradeDto{
        uint256 price;
        uint256 amount;
        address from;
        address to;
        IAAOption.AAOptionDetail optionDetail;
    }

    constructor(
        IAAOption _optionToken,
        IERC20 _quoteAsset,
        IERC20 _baseAsset,
        IAAOptionBase _optionProof,
        AggregatorV3Interface _priceFeed,
        ISwapRouter _uniswap
    ) {
        optionToken = _optionToken;
        quoteAsset = _quoteAsset;
        baseAsset = _baseAsset;
        optionProof = _optionProof;
        priceFeed = _priceFeed;
        uniswap = _uniswap;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setDefault(uint256 _freezeTradeBeforeSettle,uint256 _slippage) public onlyRole(DEFAULT_ADMIN_ROLE){
        if(_freezeTradeBeforeSettle > 60){
            freezeTradeBeforeSettle = _freezeTradeBeforeSettle;
        }
        if(_slippage > 0){
            require(_slippage <= 1e4,"must be le 10000");
            uinSlippage = _slippage;
        }
    }


    function checkSign(AAOptionMsg memory optionMsg, uint256 optionId, TradeType tradeType) public override {
        require(optionMsg.amount <= optionMsg.signAmount,"signAmount not enough");
        require(optionMsg.signTime > block.timestamp,"sign expired");
        require(hasRole(MAKER_ROLE, optionMsg.maker),"must be valid maker");
        require(SignatureChecker.isValidSignatureNow(
                optionMsg.maker,
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(
                        address(this),optionId,optionMsg.price,optionMsg.signAmount,tradeType,optionMsg.signTime,block.chainid,makerNonce[optionMsg.maker]
                    )
                    )
                ),
                optionMsg.sign),"sign valid error");
        makerNonce[optionMsg.maker]++;
    }

    /**
   * @dev Opens a position, which may be long call, long put, short call or short put.
   * @param optionMsg struct
     *  maker.
     *  amount:aggregator match amount for maker
     *  signAmount : maker sign with amount (signAmount must be ge match amount)
     *  signTime : maker sign with time (signTime must be gt currentTime)
     *  price : maker's price and sign with price
     *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,chainId,innerNonce)
   * @param optionId: option(time,strike,call/put) id
   * @param amount: total amount (order amount)
   * @param tradeType: LONG SHORT
   */
    function openPosition(
        AAOptionMsg[] memory optionMsg,
        uint256 optionId,
        uint256 amount,
        TradeType tradeType
    ) external override returns (uint256 totalCost){

        IAAOption.AAOptionDetail memory optionDetail = optionToken.getOptionDetail(optionId);

        require(optionDetail.expireTime > block.timestamp + freezeTradeBeforeSettle,"option expired");

        optionLockPool[optionId].poolId = optionId;
        uint256 step;
        uint256 checkAmount;
        while(step < optionMsg.length){
            checkSign(optionMsg[step], optionId, tradeType);
            TradeDto memory tradeDto;
            if (tradeType == TradeType.LONG) {
                tradeDto = TradeDto(optionMsg[step].price, optionMsg[step].amount, msg.sender, optionMsg[step].maker, optionDetail);
            } else {
                tradeDto = TradeDto(optionMsg[step].price, optionMsg[step].amount, optionMsg[step].maker, msg.sender, optionDetail);
            }
            totalCost += _doOpen(tradeDto);
            checkAmount+=optionMsg[step].amount;
            step++;
        }
        require(checkAmount == amount,"order amount not match");
        emit PositionOpened(msg.sender, tradeType, optionId, amount, totalCost);
    }

    function _doOpen(TradeDto memory tradeDto) internal returns (uint256 quoteAmount){
        quoteAmount = tradeDto.price * tradeDto.amount / (10 ** ITokenDecimals(address(baseAsset)).decimals());
        require(quoteAsset.transferFrom(tradeDto.from, tradeDto.to, quoteAmount), "QuoteTransferFailed");
        optionToken.mint(tradeDto.from,tradeDto.optionDetail.id,tradeDto.amount,"");
        if(tradeDto.optionDetail.optionType){
            //call
            require(baseAsset.transferFrom(tradeDto.to, address(this), tradeDto.amount), "BaseLockTransferFailed");
            optionProof.mint(tradeDto.to,tradeDto.optionDetail.id,tradeDto.amount,"");
            optionLockPool[tradeDto.optionDetail.id].totalLockAmount += tradeDto.amount;
        }else{
            //put
            uint256 quoteLockAmount;
            quoteLockAmount = tradeDto.amount * tradeDto.optionDetail.strikePrice / (10 ** ITokenDecimals(address(baseAsset)).decimals());
            require(quoteAsset.transferFrom(tradeDto.to, address(this), quoteLockAmount), "QuoteLockTransferFailed");
            optionProof.mint(tradeDto.to,tradeDto.optionDetail.id,quoteLockAmount,"");
            optionLockPool[tradeDto.optionDetail.id].totalLockAmount += quoteLockAmount;
        }
    }

    /**
   * @dev close a position, which may be long call, long put, short call or short put.
   * @param optionMsg struct
     *  maker.
     *  amount:aggregator match amount for maker
     *  signAmount : maker sign with amount (signAmount must be ge match amount)
     *  signTime : maker sign with time (signTime must be gt currentTime)
     *  price : maker's price and sign with price
     *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,chainId,innerNonce)
   * @param optionId: option(time,strike,call/put) id
   * @param amount: total amount (order amount)
   * @param tradeType: LONG SHORT
   */
    function closePosition(
        AAOptionMsg[] memory optionMsg,
        uint256 optionId,
        uint256 amount,
        TradeType tradeType
    ) external override returns (uint256 totalCost){
        IAAOption.AAOptionDetail memory optionDetail = optionToken.getOptionDetail(optionId);
        require(optionDetail.expireTime > block.timestamp + freezeTradeBeforeSettle,"option expired");
        uint256 step;
        uint256 checkAmount;
        while(step < optionMsg.length){
            checkSign(optionMsg[step], optionId, tradeType);
            if (tradeType == TradeType.LONG) {
                uint256 quoteAmount;
                quoteAmount = optionMsg[step].price * optionMsg[step].amount / (10 ** ITokenDecimals(address(baseAsset)).decimals());
                require(quoteAsset.transferFrom(optionMsg[step].maker, msg.sender, quoteAmount), "QuoteTransferFailed");
                optionToken.safeTransferFrom(msg.sender, optionMsg[step].maker, optionId, optionMsg[step].amount,"");
                totalCost += quoteAmount;
            } else {
                TradeDto memory tradeDto = TradeDto(optionMsg[step].price, optionMsg[step].amount, optionMsg[step].maker, msg.sender, optionDetail);
                totalCost += _doShortClose(tradeDto);
            }
            checkAmount+=optionMsg[step].amount;
            step++;

        }
        require(checkAmount == amount,"order amount not match");
        emit PositionClosed(msg.sender, tradeType, optionId, amount, totalCost);
    }

    function _doShortClose(TradeDto memory tradeDto) internal returns (uint256 quoteAmount){
        quoteAmount = tradeDto.price * tradeDto.amount / (10 ** ITokenDecimals(address(baseAsset)).decimals());
        require(quoteAsset.transferFrom(tradeDto.to, tradeDto.from, quoteAmount), "QuoteTransferFailed");
        if(tradeDto.optionDetail.optionType){
            //call
            require(baseAsset.transferFrom(tradeDto.from, tradeDto.to, tradeDto.amount), "BaseTransferFailed");
            optionProof.safeTransferFrom(tradeDto.to, tradeDto.from, tradeDto.optionDetail.id, tradeDto.amount,"");
        }else{
            //put
            uint256 quoteLockAmount;
            quoteLockAmount = tradeDto.amount * tradeDto.optionDetail.strikePrice / (10 ** ITokenDecimals(address(baseAsset)).decimals());
            require(quoteAsset.transferFrom(tradeDto.from, tradeDto.to, quoteLockAmount), "QuoteTransferFailed");
            optionProof.safeTransferFrom(tradeDto.to, tradeDto.from, tradeDto.optionDetail.id, quoteLockAmount,"");
        }
    }

    function settleOptions(uint256 optionId) external override returns (uint256 profit,uint256 amount){
        IAAOption.AAOptionDetail memory optionDetail = optionToken.getOptionDetail(optionId);
        require(optionDetail.expireTime <= block.timestamp,"must be expired");
        require(optionLockPool[optionId].spotPrice > uint256(0),"");
        uint256 optionBalance = optionToken.balanceOf(msg.sender, optionId);
        uint256 lockBalance = optionProof.balanceOf(msg.sender, optionId);

        if(optionDetail.optionType){
            optionLockPool[optionId].executeAmount += (optionBalance + lockBalance);
            // call
            // in the time
            if(optionDetail.strikePrice < optionLockPool[optionId].spotPrice){
                if(optionBalance > 0){
                    profit = (optionLockPool[optionId].spotPrice - optionDetail.strikePrice) * optionBalance / optionLockPool[optionId].spotPrice;
                    optionToken.burn(msg.sender, optionId, optionBalance);
                    // swap baseAsset profit to quoteAsset
                    require(baseAsset.approve(address(uniswap),profit), "baseAsset approve uniV2 failed");
                    /*address[] memory path = new address[](2);
                    path[0] = address(baseAsset);
                    path[1] = address(quoteAsset);*/
                    (,uint256 price) = getPriceForBase();
                    uint256 quoteProfit = profit / (10 ** ITokenDecimals(address(baseAsset)).decimals()) * price;
                    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                        tokenIn: address(baseAsset),
                        tokenOut: address(quoteAsset),
                        fee: uint24(3000),
                        recipient: msg.sender,
                        amountIn: profit,
                        amountOutMinimum: quoteProfit * uinSlippage / 1e4,
                        sqrtPriceLimitX96: 0
                    });
                    profit = uniswap.exactInputSingle(params);
                    /*(uint256[] memory amounts) = uniswap.swapExactTokensForTokens(profit,quoteProfit * uinSlippage / 1e4,path,msg.sender,block.timestamp);
                    profit = amounts[amounts.length-1];*/
                }
                if(lockBalance > 0){
                    amount = lockBalance - lockBalance * (optionLockPool[optionId].spotPrice - optionDetail.strikePrice) / optionLockPool[optionId].spotPrice;
                    optionProof.burn(msg.sender, optionId, lockBalance);
                    require(baseAsset.transfer(msg.sender, amount), "BaseTransferFailed");
                }
                // out/at the time
            }else{
                if(optionBalance > 0){
                    optionToken.burn(msg.sender, optionId, optionBalance);
                }
                if(lockBalance > 0){
                    optionProof.burn(msg.sender, optionId, lockBalance);
                    amount = lockBalance;
                    require(baseAsset.transfer(msg.sender, lockBalance), "BaseTransferFailed");
                }
            }

        }else{
            optionLockPool[optionId].executeAmount += (optionBalance * optionDetail.strikePrice / (10 ** ITokenDecimals(address(baseAsset)).decimals()) + lockBalance);
            // put
            // in the time
            if(optionDetail.strikePrice > optionLockPool[optionId].spotPrice){
                if(optionBalance > 0){
                    profit = (optionDetail.strikePrice - optionLockPool[optionId].spotPrice) * optionBalance / (10 ** ITokenDecimals(address(baseAsset)).decimals());
                    optionToken.burn(msg.sender, optionId, optionBalance);
                    require(quoteAsset.transfer( msg.sender, profit), "QuoteTransferFailed");
                }
                if(lockBalance > 0){
                    amount = lockBalance - lockBalance * (optionDetail.strikePrice - optionLockPool[optionId].spotPrice) / optionDetail.strikePrice;
                    optionProof.burn(msg.sender, optionId, lockBalance);
                    require(quoteAsset.transfer( msg.sender, amount), "QuoteTransferFailed");
                }
                // out/at the time
            }else{
                if(optionBalance > 0){
                    optionToken.burn(msg.sender, optionId, optionBalance);
                }
                if(lockBalance > 0){
                    optionProof.burn(msg.sender, optionId, lockBalance);
                    amount = lockBalance;
                    require(quoteAsset.transfer( msg.sender, lockBalance), "QuoteTransferFailed");
                }
            }
        }
        emit OptionsSettled(msg.sender,optionId,optionBalance,lockBalance);
    }

    function storeOptionsPrice(uint256 optionId) external override returns (uint256){
        IAAOption.AAOptionDetail memory optionDetail = optionToken.getOptionDetail(optionId);
        require(optionDetail.expireTime > block.timestamp && (block.timestamp + freezeTradeBeforeSettle > optionDetail.expireTime),"not store period");
        if(optionLockPool[optionId].spotPrice <= uint256(0)){
            (uint80 roundId,uint256 price) = getPriceForBase();
            optionLockPool[optionId].spotPrice = price;
            uint256 optionOpposeId = optionToken.getOptionId(optionDetail.expireTime, optionDetail.strikePrice, !(optionDetail.optionType));
            optionLockPool[optionOpposeId].spotPrice = optionLockPool[optionId].spotPrice;
            optionPriceRound[optionId] = roundId;
            optionPriceRound[optionOpposeId] = roundId;
        }
        return optionLockPool[optionId].spotPrice;
    }

    function getPriceForBase() internal view returns(uint80 _roundId,uint256 price){
        (
        uint80 roundId,
        int256 answer,
        ,
        ,
        ) = priceFeed.latestRoundData();
        require(answer > 0,"price get error");
        _roundId = roundId;
        price = uint256(answer) * (10 ** ITokenDecimals(address(quoteAsset)).decimals()) / (10 ** priceFeed.decimals());
    }

    function emergencyOptionsPrice(uint256 optionId,uint256 price) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256){
        IAAOption.AAOptionDetail memory optionDetail = optionToken.getOptionDetail(optionId);
        require(optionDetail.expireTime < block.timestamp ,"not emergency store period");
        if(optionLockPool[optionId].spotPrice <= uint256(0)){
            optionLockPool[optionId].spotPrice = price;
            uint256 optionOpposeId = optionToken.getOptionId(optionDetail.expireTime, optionDetail.strikePrice, !(optionDetail.optionType));
            optionLockPool[optionOpposeId].spotPrice = price;
        }
        return optionLockPool[optionId].spotPrice;

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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAAOption is IERC1155{

    struct AAOptionDetail {
        uint256 id;
        uint256 expireTime;
        uint256 strikePrice;
        bool optionType;//{ true CALL, false PUT}
    }

    function currentId() external view returns (uint256);

    function getOptionDetail(uint256 id) external view returns (AAOptionDetail memory);

    function getOptionId(uint256 expireTime, uint256 strikePrice, bool optionType) external view returns (uint256);

    function listOptions(uint256 fromIndex, uint256 pageSize) external view returns (AAOptionDetail[] memory);

    function createOptionId(uint256 expireTime, uint256 strikePrice, bool optionType) external returns (uint256);

    function createOptionIdBatch(uint256[] memory expireTime, uint256[] memory strikePrice, bool[] memory optionType) external returns (uint256[] memory);

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external returns (uint256);

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external returns (uint256[] memory);

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

pragma solidity ^0.8.4;

import "./IAABaseData.sol";

interface IAAOptionMarket is IAABaseData{

  event PositionOpened(
    address indexed user,
    TradeType indexed tradeType,
    uint256 indexed optionId,
    uint256 amount,
    uint256 totalCost
  );

  event PositionClosed(
    address indexed user,
    TradeType indexed tradeType,
    uint256 indexed optionId,
    uint256 amount,
    uint256 totalCost
  );

  event OptionsSettled(
    address indexed user,
    uint256 indexed optionId,
    uint256 indexed optionAmount,
    uint256 lockAmount
  );

  function optionLockPool(uint256 optionId) external view returns (uint256, uint256, uint256, uint256);

  function makerNonce(address maker) external view returns (uint256);

  /**
   * @dev Opens a position, which may be long call, long put, short call or short put.
   * @param optionMsg struct
     *  maker.
     *  amount:aggregator match amount for maker
     *  signAmount : maker sign with amount (signAmount must be ge match amount)
     *  signTime : maker sign with time (signTime must be gt currentTime)
     *  price : maker's price and sign with price
     *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,chainId)
   * @param optionId: option(time,strike,call/put) id
   * @param amount: total amount (order amount)
   * @param tradeType: LONG SHORT
   */
  function openPosition(
    AAOptionMsg[] memory optionMsg,
    uint256 optionId,
    uint256 amount,
    TradeType tradeType
  ) external returns (uint256 totalCost);

  /**
   * @dev close a position, which may be long call, long put, short call or short put.
   * @param optionMsg struct
     *  maker.
     *  amount:aggregator match amount for maker
     *  signAmount : maker sign with amount (signAmount must be ge match amount)
     *  signTime : maker sign with time (signTime must be gt currentTime)
     *  price : maker's price and sign with price
     *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,chainId)
   * @param optionId: option(time,strike,call/put) id
   * @param amount: total amount (order amount)
   * @param tradeType: LONG SHORT
   */
  function closePosition(
    AAOptionMsg[] memory optionMsg,
    uint256 optionId,
    uint256 amount,
    TradeType tradeType
  ) external returns (uint256 totalCost);

  function settleOptions(uint256 optionId) external returns (uint256 profit,uint256 amount);

  function storeOptionsPrice(uint256 optionId) external returns(uint256);

  function checkSign(AAOptionMsg memory optionMsg, uint256 optionId, TradeType tradeType) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAAOptionBase is IERC1155{



    function mint(address account, uint256 id, uint256 amount, bytes memory data)
    external;

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

pragma solidity ^0.8.4;

interface ITokenDecimals {
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.4;

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams memory params) external payable returns (uint256 amountOut);
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

pragma solidity ^0.8.4;

interface IAABaseData {

    // poolId same optionId
    /**
    * totalLockAmount
    * executeAmount: settled amount
    * spotPrice: settle amount
    */
    struct AAOptionLockPool{
        uint256 poolId;
        uint256 totalLockAmount;
        uint256 executeAmount;
        uint256 spotPrice;
    }

    /**
       *  maker.
       *  amount:aggregator match amount for maker
       *  signAmount : maker sign with amount (signAmount must be ge match amount)
       *  signTime : maker sign with time (signTime must be gt currentTime)
       *  price : maker's price and sign with price
       *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,makerNonce)
    */
    struct AAOptionMsg{
        address maker;
        uint256 amount;
        uint256 signAmount;
        uint256 signTime;
        uint256 price;
        bytes sign;
    }

    enum TradeType {LONG, SHORT}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}