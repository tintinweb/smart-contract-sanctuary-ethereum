/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

// File: yomiswap-v2/lib/FixedPointMathLib.sol


pragma solidity =0.8.17;

library FixedPointMathLib {
    uint256 internal constant WAD = 1e18;

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            if or(
                // Revert if y is zero to ensure we don't divide by zero below.
                iszero(y),
                // Equivalent to require(x == 0 || (x * baseUnit) / x == baseUnit)
                iszero(or(iszero(x), eq(div(z, x), baseUnit)))
            ) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := baseUnit
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := baseUnit
                }
                default {
                    z := x
                }
                let half := div(baseUnit, 2)
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, baseUnit)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }
}

// File: yomiswap-v2/interfaces/IPool.sol


pragma solidity =0.8.17;

interface IPool {
    //VARIANT
    function collection() external returns (address);

    function bondingCurve() external returns (address);

    function router() external returns (address);

    function paymentToken() external returns (address);

    function protocolFeeRatio() external returns (uint256);

    function buyEventNum() external returns (uint256);

    function sellEventNum() external returns (uint256);

    function stakeNFTprice() external returns (uint256);

    function stakeFTprice() external returns (uint256);

    function totalFTfee() external returns (uint256);

    function totalNFTfee() external returns (uint256);

    function isOtherStake() external returns (bool);

    function isPair() external returns (bool);

    struct UserInfo {
        uint256 initBuyNum;
        uint256 initSellNum;
        uint256 initSellAmount;
        uint256 totalNFTpoint;
        uint256 totalFTpoint;
    }

    struct PoolInfo {
        uint256 spotPrice;
        uint256 delta;
        uint256 spread;
        uint256 buyNum;
        uint256 sellNum;
    }

    function swapFTforNFT(uint256[] memory tokenIds, address user)
        external
        payable
        returns (uint256 protocolFee);

    function swapNFTforFT(
        uint256[] memory tokenIds,
        uint256 minExpectFee,
        address user
    ) external payable returns (uint256 protocolFee);


    function stakeNFT(uint256[] calldata tokenIds, address user) external;

    function withdrawNFT(uint256[] memory tokenIds, address user)
        external
        payable returns(uint256 totalFee);

    //@notice Only Single NonOtherStake
    function withdrawNFTpart(uint256[] calldata tokenIds, address user) external;

    //@notice Only All
    function withdrawFee(address user) external payable;

    //@notice reset Param
    function reset(address bondingCurve, uint256 newSpotPrice, uint256 newDelta, uint256 newSpread, address user) external;

    //@notice withdraw other FT
    function withdrawOtherFT(uint256 amount, address user) external;

    //@notice withdraw other NFT
    function withdrawOtherNFT(address collection, uint256 tokenId, address user)external;

    //GET
    //@notice Only All
    function getCalcBuyInfo(uint256 itemNum, uint256 spotPrice)
        external
        view
        returns (uint256);

    //@notice All
    function getCalcSellInfo(uint256 itemNum, uint256 spotPrice)
        external
        view
        returns (uint256);

    //@notice Only OtherStake
    function getUserStakeNFTfee(address user)
        external
        view
        returns (uint256 userFee);

    //@notice Only OtherStake
    function getUserStakeFTfee(address user)
        external
        view
        returns (uint256 userFee);

    //@notice Only Single NonOtherStake
    function getUserStakeNFTfee() external view returns (uint256 userFee);

    //@notice Only Single NonOtherStake
    function getUserStakeFTfee() external view returns (uint256 userFee);

    //@notice All
    function getPoolInfo() external view returns (PoolInfo memory);

    //@notice All
    function getAllHoldIds() external view returns (uint256[] memory);

    //@notice Only Pair NonOtherStake
    function getUserStakeFee() external view returns (uint256);

    //@notice Only Pair OtherStake
    function getUserStakeFee(address user) external view returns (uint256);

    //@notice Only OtherStake
    function getUserInfo(address user) external view returns (UserInfo memory);

    //@notice Only Non OtherStake
    function getUserInfo() external view returns (UserInfo memory);

    //SET
    //@notice All
    function setRouter(address newRouter) external;

    //@notice All
    function setProtocolFeeRatio(uint256 newProtocolFeeRatio) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: yomiswap-v2/Router.sol


pragma solidity =0.8.17;





contract Router is Ownable {
    using FixedPointMathLib for uint256;
    //@param supporterFeeRatio: ratio of supporter
    uint256 public supporterFeeRatio;

    //@param isCollectionApprove: isApprove of Collection
    mapping(address => bool) private isCollectionApprove;

    //@param isBondingCurve: isApprove of BondingCurve
    mapping(address => bool) private isBondingCurveApprove;

    //@param isPaymentToken: isApprove of PaymentToken
    mapping(address => bool) private isPaymentTokenApprove;

    //@param isFactoryApprove: isApprove of Facotory
    mapping(address => bool) private isFactoryApprove;

    //@param isSupporterApprove: isApprove of Supporter
    mapping(address => bool) private isSupporterApprove;

    //@param totalProtocolFee: total protocol fee per paymentToken
    mapping(address => uint256) public totalFee;

    //@param totalProtocolFee: total protocol fee per paymentToken
    mapping(address => uint256) private totalProtocolFee;

    //@param supporterFee: per supporter and per paymentToken
    mapping(address => mapping(address => uint256)) private supporterFee;

    //STRUCT
    struct input {
        uint256[] tokenIds;
    }

    //@notice only factory address
    modifier onlyFactory() {
        require(isFactoryApprove[msg.sender] == true, "onlyFactory");
        _;
    }

    //EVENT
    event StakeNFT(
        address indexed user,
        address indexed pool,
        uint256[] tokenIds
    );
    event SwapNFTforFT(
        address indexed user,
        address indexed pool,
        uint256[] tokenIds,
        uint256 totalFee,
        address supporter
    );
    event SwapFTforNFT(
        address indexed user,
        address indexed pool,
        uint256[] tokenIds,
        uint256 totalFee,
        address supporter
    );
    event WithdrawNFT(
        address indexed user,
        address indexed pool,
        uint256[] tokenIds,
        uint256 userAmount
    );
    event WithdrawNFTpart(
        address indexed user,
        address indexed pool,
        uint256[] tokenIds
    );
    event WithdrawFee(
        address indexed user,
        address indexed pool,
        uint256 userFee
    );
    event Received(address, uint256);
    event UpdateBondingCurve(address indexed bondingCurve, bool approve);
    event UpdateCollection(address indexed collection, bool approve);
    event UpdatePool(address indexed pool, bool approve);
    event UpdatePoolParam(address indexed pool);
    event UpdatePaymentToken(address indexed paymentToken, bool approve);
    event UpdateFactory(address indexed factory, bool approve);
    event UpdateSupporter(address indexed supporter, bool approve);

    //CONSTRCTO
    constructor(uint256 _supporterFeeRatio) {
      supporterFeeRatio = _supporterFeeRatio;
    }

    //MAIN
    function stakeNFT(address _pool, uint256[] calldata _tokenIds) external {
        IPool(_pool).stakeNFT(_tokenIds, msg.sender);
        emit StakeNFT(msg.sender, _pool, _tokenIds);
    }

    function batchStakeNFT(
        address[] calldata _poolList,
        input[] calldata InputArray
    ) external {
        for (uint256 i = 0; i < _poolList.length; ) {
            IPool(_poolList[i]).stakeNFT(InputArray[i].tokenIds, msg.sender);
            emit StakeNFT(msg.sender, _poolList[i], InputArray[i].tokenIds);
            unchecked {
                ++i;
            }
        }
    }

    //@notice swap NFT → FT
    function swapNFTforFT(
        address _pool,
        uint256[] calldata _tokenIds,
        uint256 _minExpectFee,
        address _supporter
    ) external {
        require(_tokenIds.length > 0, "Not 0");
        IPool.PoolInfo memory _poolInfo = IPool(_pool).getPoolInfo();
        address _paymentToken = IPool(_pool).paymentToken();
        uint256 _totalFee = IPool(_pool).getCalcSellInfo(
            _tokenIds.length,
            _poolInfo.spotPrice
        );

        uint256 _profitAmount = IPool(_pool).swapNFTforFT(
            _tokenIds,
            _minExpectFee,
            msg.sender
        );
        _updateFee(_supporter, _paymentToken, _profitAmount);
        emit SwapNFTforFT(msg.sender, _pool, _tokenIds, _totalFee, _supporter);
    }

    //@notice batchSwapNFTforFT
    function batchSwapNFTforFT(
        address[] calldata _poolList,
        input[] calldata InputArray,
        uint256[] calldata _minExpects,
        address _supporter
    ) external payable {
        for (uint256 i = 0; i < _poolList.length; ) {
            require(InputArray[i].tokenIds.length > 0, "Not 0");
            IPool.PoolInfo memory _poolInfo = IPool(_poolList[i]).getPoolInfo();
            address _paymentToken = IPool(_poolList[i]).paymentToken();
            uint256 _totalFee = IPool(_poolList[i]).getCalcSellInfo(
                InputArray[i].tokenIds.length,
                _poolInfo.spotPrice
            );

            uint256 _profitAmount = IPool(_poolList[i]).swapNFTforFT(
                InputArray[i].tokenIds,
                _minExpects[i],
                msg.sender
            );

            _updateFee(_supporter, _paymentToken, _profitAmount);

            emit SwapNFTforFT(
                msg.sender,
                _poolList[i],
                InputArray[i].tokenIds,
                _totalFee,
                _supporter
            );
            unchecked {
                ++i;
            }
        }
    }

    //@notice swap FT → NFT
    function swapFTforNFT(
        address _pool,
        uint256[] calldata _tokenIds,
        address _supporter
    ) external payable {
        require(_tokenIds.length > 0, "Not 0");
        IPool.PoolInfo memory _poolInfo = IPool(_pool).getPoolInfo();
        address _paymentToken = IPool(_pool).paymentToken();
        uint256 _totalFee = IPool(_pool).getCalcBuyInfo(
            _tokenIds.length,
            _poolInfo.spotPrice
        );

        uint256 _profitAmount = IPool(_pool).swapFTforNFT{value: msg.value}(
            _tokenIds,
            msg.sender
        );
        _updateFee(_supporter, _paymentToken, _profitAmount);
        emit SwapFTforNFT(msg.sender, _pool, _tokenIds, _totalFee, _supporter);
    }

    //@notice batchSwapFTforNFT
    function batchSwapFTforNFT(
        address[] calldata _poolList,
        input[] calldata InputArray,
        address _supporter
    ) external payable {
        uint256 _remainFee = msg.value;
        for (uint256 i = 0; i < _poolList.length; ) {
            require(InputArray[i].tokenIds.length > 0, "Not 0");
            IPool.PoolInfo memory _poolInfo = IPool(_poolList[i]).getPoolInfo();
            address _paymentToken = IPool(_poolList[i]).paymentToken();
            uint256 _totalFee = IPool(_poolList[i]).getCalcBuyInfo(
                InputArray[i].tokenIds.length,
                _poolInfo.spotPrice
            );

            uint256 _profitAmount;
            if (_paymentToken == address(0)) {
                require(_remainFee >= _totalFee, "not enogh value");
                _remainFee -= _totalFee;

                _profitAmount = IPool(_poolList[i]).swapFTforNFT{
                    value: _totalFee
                }(InputArray[i].tokenIds, msg.sender);
            } else {
                _profitAmount = IPool(_poolList[i]).swapFTforNFT(
                    InputArray[i].tokenIds,
                    msg.sender
                );
            }

            _updateFee(_supporter, _paymentToken, _profitAmount);
            emit SwapFTforNFT(
                msg.sender,
                _poolList[i],
                InputArray[i].tokenIds,
                _totalFee,
                _supporter
            );
            unchecked {
                ++i;
            }
        }
        if (_remainFee > 0) {
            payable(msg.sender).transfer(_remainFee);
        }
    }

    //@notice withdraw NFT and Fee
    function withdrawNFT(address _pool, uint256[] calldata _tokenIds) external {
        uint256 _totalFee = IPool(_pool).withdrawNFT(_tokenIds, msg.sender);
        emit WithdrawNFT(msg.sender, _pool, _tokenIds, _totalFee);
    }

    //@notice withdraw part NFT
    function withdrawNFTpart(address _pool, uint256[] calldata _tokenIds) external {
      IPool(_pool).withdrawNFTpart(_tokenIds, msg.sender);
      emit WithdrawNFTpart(msg.sender, _pool, _tokenIds);
    }

    //@notice withdraw protocol fee
    function withdrawProtocolFee(address _paymentToken)
        external
        payable
        onlyOwner
    {
        uint256 _totalFee = totalProtocolFee[_paymentToken];
        uint256 _totalBalance = totalFee[_paymentToken];
        if (_paymentToken == address(0)) {
            //check
            require(_totalFee > 0 || address(this).balance > _totalBalance, "Not Fee");

            //effect
            totalProtocolFee[_paymentToken] = 0;
            totalFee[_paymentToken] -= _totalFee;
            uint256 subProtocolFee = address(this).balance - _totalBalance;
            _totalFee += subProtocolFee;
            
            //intaraction
            payable(msg.sender).transfer(_totalFee);
        } else {
            //check
            require(_totalFee > 0 || IERC20(_paymentToken).balanceOf(address(this)) > totalFee[_paymentToken], "Not Fee");

            //effect
            totalProtocolFee[_paymentToken] = 0;
            totalFee[_paymentToken] -= _totalFee;
            uint256 subProtocolFee = IERC20(_paymentToken).balanceOf(address(this)) - totalFee[_paymentToken];
            _totalFee += subProtocolFee;

            //intaraction
            IERC20(_paymentToken).transfer(msg.sender, _totalFee);
        }
    }

    function withdrawFee(address _pool) external payable {
      IPool(_pool).withdrawFee(msg.sender);
    }

    //@notice withdraw support fee
    function withdrawSupportFee(address _paymentToken) external payable {
        uint256 _totalFee = supporterFee[msg.sender][_paymentToken];

        //check
        require(_totalFee > 0, "Not Fee");

        //effect
        supporterFee[msg.sender][_paymentToken] = 0;
        totalFee[_paymentToken] -= _totalFee;


        //intaraction
        if (_paymentToken == address(0)) {
            payable(msg.sender).transfer(_totalFee);
        } else {
            IERC20(_paymentToken).transfer(msg.sender, _totalFee);
        }
    }

    function reset(
        address _pool,
        address _bondingCurve,
        uint256 _newSpotPrice, 
        uint256 _newDelta, 
        uint256 _newSpread
    ) external {
        IPool(_pool).reset(_bondingCurve,_newSpotPrice,_newDelta,_newSpread, msg.sender);
        emit UpdatePoolParam(_pool);
    }

    function withdrawOtherFT(address _pool,uint256 _amount, address _user) external payable {
      IPool(_pool).withdrawOtherFT(_amount, _user);
    }

    //@notice withdraw FT
    function withdrawOtherNFT(address _pool, address _collection, uint256 _tokenId, address _user)external{
      IPool(_pool).withdrawOtherNFT(_collection, _tokenId, _user);
    }

    //GET
    //@notice get approve of collection
    function getIsCollectionApprove(address _collection)
        external
        view
        returns (bool)
    {
        return isCollectionApprove[_collection];
    }

    //@notice get approve of bonding curve
    function getIsBondingCurveApprove(address _bondingCurve)
        external
        view
        returns (bool)
    {
        return isBondingCurveApprove[_bondingCurve];
    }

    //@notice get approve of bonding curve
    function getIsPaymentTokenApprove(address _paymentToken)
        external
        view
        returns (bool)
    {
        return isPaymentTokenApprove[_paymentToken];
    }

    //@notice get approve of bonding curve
    function getIsFactoryApprove(address _factory)
        external
        view
        returns (bool)
    {
        return isFactoryApprove[_factory];
    }

    //@notice get approve of bonding curve
    function getIsSupporterApprove(address _supporter)
        external
        view
        returns (bool)
    {
        return isSupporterApprove[_supporter];
    }

    //@notice get fee of protocol
    function getTotalProtocolFee(address _paymentToken) external view returns(uint256){
      uint256 _totalFee = totalProtocolFee[_paymentToken];
        if (_paymentToken == address(0)) {
            uint256 subProtocolFee = address(this).balance - totalFee[_paymentToken];
            _totalFee += subProtocolFee;
        } else {
            uint256 subProtocolFee = IERC20(_paymentToken).balanceOf(address(this)) - totalFee[_paymentToken];
            _totalFee += subProtocolFee;
        }
        return _totalFee;
    }

    //@notice get fee of supporter
    function getSupporterFee(address _supporter, address _paymentToken)external view returns(uint256){
      return supporterFee[_supporter][_paymentToken];
    }

    //SET
    //@notice approve for bonding curve
    function setCollectionApprove(address _collection, bool _approve)
        external
        onlyOwner
    {
        isCollectionApprove[_collection] = _approve;
        emit UpdateCollection(_collection, _approve);
    }

    //@notice approve for bonding curve
    function setBondingCurveApprove(address _bondingCurve, bool _approve)
        external
        onlyOwner
    {
        isBondingCurveApprove[_bondingCurve] = _approve;
        emit UpdateBondingCurve(_bondingCurve, _approve);
    }

    //@notice approve for bonding curve
    function setPaymentTokenApprove(address _paymentToken, bool _approve)
        external
        onlyOwner
    {
        isPaymentTokenApprove[_paymentToken] = _approve;
        emit UpdatePaymentToken(_paymentToken, _approve);
    }

    //@notice set approve for factory
    function setFactoryApprove(address _factory, bool _approve)
        external
        onlyOwner
    {
        isFactoryApprove[_factory] = _approve;
        emit UpdateFactory(_factory, _approve);
    }

    //@notice set approve for supporter
    function setSupporterApprove(address _supporter, bool _approve)
        external
        onlyOwner
    {
        isSupporterApprove[_supporter] = _approve;
        emit UpdateSupporter(_supporter, _approve);
    }

    //@notice set protocolFeeRatio for pool
    function setSupporterFeeRatio(
        uint256 _newSupporterFeeRatio
    ) external onlyOwner {
        supporterFeeRatio = _newSupporterFeeRatio;
    }

    //@notice set protocolFeeRatio for pool
    function setPoolProtocolFeeRatio(
        address _pool,
        uint256 _newProtocolFeeRatio
    ) external onlyOwner {
        IPool(_pool).setProtocolFeeRatio(_newProtocolFeeRatio);
    }

    //@notice set protocolFeeRatio
    function setPoolRouter(address _pool, address _newRouter)
        external
        onlyOwner
    {
        IPool(_pool).setRouter(_newRouter);
    }

    //@notice set pool
    function setPool(address _pool, bool _approve) external onlyFactory {
        emit UpdatePool(_pool, _approve);
    }

    //INTERNAL
    //@notice calc update fee
    function _updateFee(
        address _supporter,
        address _paymentToken,
        uint256 _profitAmount
    ) internal {
        totalFee[_paymentToken] += _profitAmount;
        if (_supporter != address(0)) {
            uint256 _supporterFee = _profitAmount.fmul(
                supporterFeeRatio,
                FixedPointMathLib.WAD
            );
            uint256 _protocolFee = _profitAmount - _supporterFee;
            totalProtocolFee[_paymentToken] += _protocolFee;
            supporterFee[_supporter][_paymentToken] += _supporterFee;
        } else if (_supporter == address(0)) {
            totalProtocolFee[_paymentToken] += _profitAmount;
        }
    }

    //@notice receive関数
    fallback() external payable{}
    receive() external payable {}
}