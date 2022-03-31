// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./supply/SupplyTreasuryFundForCompound.sol";
import "./convex/IConvexBoosterV2.sol";
import "./supply/ISupplyBooster.sol";

interface ILendingMarket {
    function addMarketPool(
        uint256 _convexBoosterPid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold
    ) external;
}

interface ISupplyRewardFactoryExtra is ISupplyRewardFactory {
    function addOwner(address _newOwner) external;
}

contract GenerateLendingPoolsV2 {
    address public convexBooster;
    address public lendingMarket;

    address public supplyBooster;
    address public supplyRewardFactory;

    address public compoundComptroller;

    address public deployer;

    constructor(address _deployer) public {
        deployer = _deployer;
    }

    function setLendingContract(
        address _supplyBooster,
        address _convexBooster,
        address _lendingMarket,
        address _supplyRewardFactory,
        address _compoundComptroller
    ) public {
        require(deployer == msg.sender, "!authorized auth");

        supplyBooster = _supplyBooster;
        convexBooster = _convexBooster;
        lendingMarket = _lendingMarket;
        supplyRewardFactory = _supplyRewardFactory;
        compoundComptroller = _compoundComptroller;
    }

    function addConvexBoosterPool(uint256 _originConvexPid) public {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        IConvexBoosterV2(convexBooster).addConvexPool(_originConvexPid);
    }

    function addConvexBoosterPool(
        uint256 _originConvexPid,
        address _curveSwapAddress,
        address _curveZapAddress,
        address _basePoolAddress,
        bool _isMeta,
        bool _isMetaFactory
    ) public {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        IConvexBoosterV2(convexBooster).addConvexPool(
            _originConvexPid,
            _curveSwapAddress,
            _curveZapAddress,
            _basePoolAddress,
            _isMeta,
            _isMetaFactory
        );
    }

    function addLendingMarketPool(
        uint256 _convexBoosterPid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds
    ) public {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        ILendingMarket(lendingMarket).addMarketPool(
            _convexBoosterPid,
            _supplyBoosterPids,
            _curveCoinIds,
            100,
            50
        );
    }

    function addSupplyPoolForCEther(address _compoundCToken) public {
        _addSupplyPool(_compoundCToken, false);
    }

    function addSupplyPoolForCToken(address _compoundCToken) public {
        _addSupplyPool(_compoundCToken, true);
    }

    function _addSupplyPool(address _compoundCToken, bool _isErc20) internal {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        SupplyTreasuryFundForCompound supplyTreasuryFund = new SupplyTreasuryFundForCompound(
                supplyBooster,
                _compoundCToken,
                compoundComptroller,
                supplyRewardFactory
            );

        address underlyToken;

        // 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5 = cEther
        if (_isErc20) {
            underlyToken = ICompoundCErc20(_compoundCToken).underlying();
        } else {
            underlyToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        }

        ISupplyRewardFactoryExtra(supplyRewardFactory).addOwner(
            address(supplyTreasuryFund)
        );

        ISupplyBooster(supplyBooster).addSupplyPool(
            underlyToken,
            address(supplyTreasuryFund)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../common/IBaseReward.sol";

interface ICompoundComptroller {
    /*** Assets You Are In ***/
    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function getAssetsIn(address account)
        external
        view
        returns (address[] memory);

    function checkMembership(address account, address cToken)
        external
        view
        returns (bool);

    function claimComp(address holder) external;

    function claimComp(address holder, address[] memory cTokens) external;

    function getCompAddress() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function accountAssets(address user)
        external
        view
        returns (address[] memory);

    function markets(address _cToken)
        external
        view
        returns (bool isListed, uint256 collateralFactorMantissa);
}

interface ICompound {
    function borrow(uint256 borrowAmount) external returns (uint256);

    function isCToken(address) external view returns (bool);

    function comptroller() external view returns (ICompoundComptroller);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function accrualBlockNumber() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function borrowBalanceStored(address user) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function decimals() external view returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function interestRateModel() external view returns (address);
}

interface ICompoundCEther is ICompound {
    function repayBorrow() external payable;

    function mint() external payable;
}

interface ICompoundCErc20 is ICompound {
    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function underlying() external returns (address); // like usdc usdt
}

interface ISupplyRewardFactory {
    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _owner
    ) external returns (address);
}

contract SupplyTreasuryFundForCompound is ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public rewardCompPool;
    address public supplyRewardFactory;
    address public virtualBalance;
    address public compAddress;
    address public compoundComptroller;
    address public underlyToken;
    address public lpToken;
    address public owner;
    uint256 public totalUnderlyToken;
    uint256 public frozenUnderlyToken;
    bool public isErc20;
    bool private initialized;

    modifier onlyInitialized() {
        require(initialized, "!initialized");
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "SupplyTreasuryFundForCompound: !authorized"
        );
        _;
    }

    constructor(
        address _owner,
        address _lpToken,
        address _compoundComptroller,
        address _supplyRewardFactory
    ) public {
        owner = _owner;
        compoundComptroller = _compoundComptroller;
        lpToken = _lpToken;
        supplyRewardFactory = _supplyRewardFactory;
    }

    // call by Owner (SupplyBooster)
    function initialize(
        address _virtualBalance,
        address _underlyToken,
        bool _isErc20
    ) public onlyOwner {
        require(!initialized, "initialized");

        compAddress = ICompoundComptroller(compoundComptroller).getCompAddress();

        underlyToken = _underlyToken;

        virtualBalance = _virtualBalance;
        isErc20 = _isErc20;

        rewardCompPool = ISupplyRewardFactory(supplyRewardFactory).createReward(
                compAddress,
                virtualBalance,
                address(this)
            );

        initialized = true;
    }

    function _mintEther(uint256 _amount) internal {
        ICompoundCEther(lpToken).mint{value: _amount}();
    }

    function _mintErc20(uint256 _amount) internal {
        ICompoundCErc20(lpToken).mint(_amount);
    }

    receive() external payable {}

    function migrate(address _newTreasuryFund, bool _setReward)
        external
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        uint256 cTokens = IERC20(lpToken).balanceOf(address(this));

        uint256 redeemState = ICompound(lpToken).redeem(cTokens);

        require(
            redeemState == 0,
            "SupplyTreasuryFundForCompound: !redeemState"
        );

        uint256 bal;

        if (isErc20) {
            bal = IERC20(underlyToken).balanceOf(address(this));

            IERC20(underlyToken).safeTransfer(owner, bal);
        } else {
            bal = address(this).balance;

            if (bal > 0) {
                payable(owner).sendValue(bal);
            }
        }

        if (_setReward) {
            IBaseReward(rewardCompPool).addOwner(_newTreasuryFund);
            IBaseReward(rewardCompPool).removeOwner(address(this));
        }

        return bal;
    }

    function _depositFor(address _for, uint256 _amount) internal {
        totalUnderlyToken = totalUnderlyToken.add(_amount);

        if (isErc20) {
            IERC20(underlyToken).safeApprove(lpToken, 0);
            IERC20(underlyToken).safeApprove(lpToken, _amount);

            _mintErc20(_amount);
        } else {
            _mintEther(_amount);
        }

        if (_for != address(0)) {
            IBaseReward(rewardCompPool).stake(_for);
        }
    }

    function depositFor(address _for)
        public
        payable
        onlyInitialized
        onlyOwner
        nonReentrant
    {
        _depositFor(_for, msg.value);
    }

    function depositFor(address _for, uint256 _amount)
        public
        onlyInitialized
        onlyOwner
        nonReentrant
    {
        _depositFor(_for, _amount);
    }

    function withdrawFor(address _to, uint256 _amount)
        public
        onlyInitialized
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        IBaseReward(rewardCompPool).withdraw(_to);

        require(
            totalUnderlyToken >= _amount,
            "SupplyTreasuryFundForCompound: !insufficient balance"
        );

        totalUnderlyToken = totalUnderlyToken.sub(_amount);

        uint256 redeemState = ICompound(lpToken).redeemUnderlying(_amount);

        require(
            redeemState == 0,
            "SupplyTreasuryFundForCompound: !redeemState"
        );

        uint256 bal;

        if (isErc20) {
            bal = IERC20(underlyToken).balanceOf(address(this));

            IERC20(underlyToken).safeTransfer(_to, bal);
        } else {
            bal = address(this).balance;

            if (bal > 0) {
                payable(_to).sendValue(bal);
            }
        }

        return bal;
    }

    function borrow(
        address _to,
        uint256 _lendingAmount,
        uint256 _lendingInterest
    ) public onlyInitialized nonReentrant onlyOwner returns (uint256) {
        totalUnderlyToken = totalUnderlyToken.sub(_lendingAmount);
        frozenUnderlyToken = frozenUnderlyToken.add(_lendingAmount);

        uint256 redeemState = ICompound(lpToken).redeemUnderlying(
            _lendingAmount
        );

        require(
            redeemState == 0,
            "SupplyTreasuryFundForCompound: !redeemState"
        );

        if (isErc20) {
            IERC20(underlyToken).safeTransfer(
                _to,
                _lendingAmount.sub(_lendingInterest)
            );

            if (_lendingInterest > 0) {
                IERC20(underlyToken).safeTransfer(owner, _lendingInterest);
            }
        } else {
            payable(_to).sendValue(_lendingAmount.sub(_lendingInterest));
            if (_lendingInterest > 0) {
                payable(owner).sendValue(_lendingInterest);
            }
        }

        return _lendingInterest;
    }

    function repayBorrow()
        public
        payable
        onlyInitialized
        nonReentrant
        onlyOwner
    {
        _mintEther(msg.value);

        totalUnderlyToken = totalUnderlyToken.add(msg.value);
        frozenUnderlyToken = frozenUnderlyToken.sub(msg.value);
    }

    function repayBorrow(uint256 _lendingAmount)
        public
        onlyInitialized
        nonReentrant
        onlyOwner
    {
        IERC20(underlyToken).safeApprove(lpToken, 0);
        IERC20(underlyToken).safeApprove(lpToken, _lendingAmount);

        _mintErc20(_lendingAmount);

        totalUnderlyToken = totalUnderlyToken.add(_lendingAmount);
        frozenUnderlyToken = frozenUnderlyToken.sub(_lendingAmount);
    }

    function getBalance() public view returns (uint256) {
        uint256 exchangeRateStored = ICompound(lpToken).exchangeRateStored();
        uint256 cTokens = IERC20(lpToken).balanceOf(address(this));

        return exchangeRateStored.mul(cTokens).div(1e18);
    }

    function claim()
        public
        onlyInitialized
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        ICompoundComptroller(compoundComptroller).claimComp(address(this));

        uint256 balanceOfComp = IERC20(compAddress).balanceOf(address(this));

        if (balanceOfComp > 0) {
            IERC20(compAddress).safeTransfer(rewardCompPool, balanceOfComp);

            IBaseReward(rewardCompPool).notifyRewardAmount(balanceOfComp);
        }

        uint256 bal;
        uint256 cTokens = IERC20(lpToken).balanceOf(address(this));

        // If Uses withdraws all the money, the remaining ctoken is profit.
        if (totalUnderlyToken == 0 && frozenUnderlyToken == 0) {
            if (cTokens > 0) {
                uint256 redeemState = ICompound(lpToken).redeem(cTokens);

                require(
                    redeemState == 0,
                    "SupplyTreasuryFundForCompound: !redeemState"
                );

                if (isErc20) {
                    bal = IERC20(underlyToken).balanceOf(address(this));

                    IERC20(underlyToken).safeTransfer(owner, bal);
                } else {
                    bal = address(this).balance;

                    if (bal > 0) {
                        payable(owner).sendValue(bal);
                    }
                }

                return bal;
            }
        }

        uint256 exchangeRateStored = ICompound(lpToken).exchangeRateCurrent();

        // ctoken price
        uint256 cTokenPrice = cTokens.mul(exchangeRateStored).div(1e18);

        if (cTokenPrice > totalUnderlyToken.add(frozenUnderlyToken)) {
            uint256 interestCToken = cTokenPrice
                .sub(totalUnderlyToken.add(frozenUnderlyToken))
                .mul(1e18)
                .div(exchangeRateStored);

            uint256 redeemState = ICompound(lpToken).redeem(interestCToken);

            require(
                redeemState == 0,
                "SupplyTreasuryFundForCompound: !redeemState"
            );

            if (isErc20) {
                bal = IERC20(underlyToken).balanceOf(address(this));

                IERC20(underlyToken).safeTransfer(owner, bal);
            } else {
                bal = address(this).balance;

                if (bal > 0) {
                    payable(owner).sendValue(bal);
                }
            }
        }

        return bal;
    }

    function getReward(address _for) public onlyOwner nonReentrant {
        if (IBaseReward(rewardCompPool).earned(_for) > 0) {
            IBaseReward(rewardCompPool).getReward(_for);
        }
    }

    function getBorrowRatePerBlock() public view returns (uint256) {
        return ICompound(lpToken).borrowRatePerBlock();
    }

    /* function getCollateralFactorMantissa() public view returns (uint256) {
        ICompoundComptroller comptroller = ICompound(lpToken).comptroller();
        (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(
            lpToken
        );

        return isListed ? collateralFactorMantissa : 800000000000000000;
    } */
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./IConvexBooster.sol";

interface IConvexBoosterV2 is IConvexBooster {
    function liquidate(
        uint256 _convexPid,
        int128 _curveCoinId,
        address _user,
        uint256 _amount
    ) external override returns (address, uint256);

    function depositFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user
    ) external override returns (bool);

    function withdrawFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user,
        bool _freezeTokens
    ) external override returns (bool);

    function poolInfo(uint256 _convexPid)
        external
        view
        override
        returns (
            uint256 originConvexPid,
            address curveSwapAddress,
            address lpToken,
            address originCrvRewards,
            address originStash,
            address virtualBalance,
            address rewardCrvPool,
            address rewardCvxPool,
            bool shutdown
        );

    function addConvexPool(uint256 _originConvexPid) external override;

    function addConvexPool(uint256 _originConvexPid, address _curveSwapAddress, address _curveZapAddress, address _basePoolAddress, bool _isMeta, bool _isMetaFactory)
        external;

    function getPoolZapAddress(address _lpToken)
        external
        view
        returns (address);

    function getPoolToken(uint256 _pid) external view returns (address);

    function calculateTokenAmount(
        uint256 _pid,
        uint256 _tokens,
        int128 _curveCoinId
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface ISupplyBooster {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address underlyToken,
            address rewardInterestPool,
            address supplyTreasuryFund,
            address virtualBalance,
            bool isErc20,
            bool shutdown
        );

    function liquidate(bytes32 _lendingId, uint256 _lendingInterest)
        external
        payable
        returns (address);

    function getLendingUnderlyToken(bytes32 _lendingId)
        external
        view
        returns (address);

    function borrow(
        uint256 _pid,
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _lendingInterest,
        uint256 _borrowNumbers
    ) external;

    // ether
    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _lendingInterest
    ) external payable;

    // erc20
    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _lendingInterest
    ) external;

    function addSupplyPool(address _underlyToken, address _supplyTreasuryFund)
        external
        returns (bool);

    function getBorrowRatePerBlock(uint256 _pid)
        external
        view
        returns (uint256);

    function getUtilizationRate(uint256 _pid) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface IBaseReward {
    function earned(address account) external view returns (uint256);
    function stake(address _for) external;
    function withdraw(address _for) external;
    function getReward(address _for) external;
    function notifyRewardAmount(uint256 reward) external;
    function addOwner(address _newOwner) external;
    function addOwners(address[] calldata _newOwners) external;
    function removeOwner(address _owner) external;
    function isOwner(address _owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface IConvexBooster {
    function liquidate(
        uint256 _convexPid,
        int128 _curveCoinId,
        address _user,
        uint256 _amount
    ) external returns (address, uint256);

    function depositFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user
    ) external returns (bool);

    function withdrawFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user,
        bool _freezeTokens
    ) external returns (bool);

    function poolInfo(uint256 _convexPid)
        external
        view
        returns (
            uint256 originConvexPid,
            address curveSwapAddress,
            address lpToken,
            address originCrvRewards,
            address originStash,
            address virtualBalance,
            address rewardCrvPool,
            address rewardCvxPool,
            bool shutdown
        );

    function addConvexPool(uint256 _originConvexPid) external;
}