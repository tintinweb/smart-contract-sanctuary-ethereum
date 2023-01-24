/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

/**
 * The Icebox is the coolest way to freeze tokens and liquidity on the planet!
 * Join the fun here: https://icebox.ski
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

interface IIGLOO {
    function balanceOf(address account) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function resetLastFreeze(address account) external;
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Icebox is ReentrancyGuard {
    struct Freeze {
        uint256 id;
        address user;
        address token;
        uint256 amount;
        uint256 supply;
        uint256 freezeDate;
        uint256 thawDate;
        bool frozen;
    }

    mapping (uint256 => Freeze) public freezes;
    mapping (address => uint256[]) public freezesByUser;
    uint256 public freezeCounter;

    address public treasuryMPG;
    address public treasuryIGLOO;
    uint256 public treasuryMPGBps;
    uint256 public treasuryIGLOOBps;
    uint256 public fee;
    uint256 public constant maxTokenValue = 15 * (10 ** 16);

    IIGLOO public IGLOO;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IFactory public factory = IFactory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IERC20 public WETH = IERC20(weth);
    IRouter public router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    event FeeReceived(uint256 indexed id, uint256 indexed amount, uint256 indexed timestamp);

    modifier onlyTreasury() {
        require(msg.sender == treasuryMPG || msg.sender == treasuryIGLOO);
        _;
    }

    constructor(address _treasuryMPG, address _treasuryIGLOO, uint256 _treasuryMPGBps, uint256 _treasuryIGLOOBps, uint256 _fee, address _igloo) {
        treasuryMPG = _treasuryMPG;
        treasuryIGLOO = _treasuryIGLOO;
        require(_treasuryMPGBps + _treasuryIGLOOBps == 10000);
        treasuryMPGBps = _treasuryMPGBps;
        treasuryIGLOOBps = _treasuryIGLOOBps;
        fee = _fee;
        IGLOO = IIGLOO(_igloo);
    }

    function freeze(address _token, uint256 _amount, uint256 _seconds) external payable nonReentrant {
        require(msg.value == fee);
        IERC20 _Token = IERC20(_token);
        require(_Token.balanceOf(msg.sender) >= _amount, "Balance too low");
        require(_Token.allowance(msg.sender, address(this)) >= _amount, "Allowance too low");
        uint256 _balance = _Token.balanceOf(address(this));
        _Token.transferFrom(msg.sender, address(this), _amount);
        require(_Token.balanceOf(address(this)) == _balance + _amount);

        freezes[freezeCounter] = Freeze({
            id: freezeCounter,
            user: msg.sender,
            token: _token,
            amount: _amount,
            supply: _Token.totalSupply(),
            freezeDate: block.timestamp,
            thawDate: block.timestamp + _seconds,
            frozen: true
        });
        freezesByUser[msg.sender].push(freezeCounter);
        freezeCounter = freezeCounter + 1;

        if (treasuryMPGBps > 0) {
            payable(treasuryMPG).call{value: fee * treasuryMPGBps / 10000}("");
        }
        if (treasuryIGLOOBps > 0) {
            payable(treasuryIGLOO).call{value: fee * treasuryIGLOOBps / 10000}("");
        }
        emit FeeReceived(freezeCounter - 1, fee, block.timestamp);

        IPair _pair = IPair(_token);
        try _pair.token0() {
            (uint112 _reserveIn, uint112 _reserveOut, ) = _pair.getReserves();
            if (_pair.token0() == weth) {
                if (factory.getPair(weth, _pair.token1()) == _token) {
                    uint256 _months = _seconds / 2629800;
                    if (_months >= 1) {
                        if (_months > 36) {
                            _months = 36;
                        }
                        uint256 _tokens = IGLOO.balanceOf(address(this)) * _months / 1000000;
                        uint256 _amountOut = router.getAmountOut(_tokens, _reserveOut, _reserveIn);
                        if (_amountOut >= maxTokenValue) {
                            _tokens = router.getAmountIn(maxTokenValue, _reserveOut, _reserveIn);
                        }
                        try IGLOO.transfer(msg.sender, _tokens) { IGLOO.resetLastFreeze(msg.sender); } catch {}
                    }
                }
            } else if (_pair.token1() == weth) {
                if (factory.getPair(_pair.token0(), weth) == _token) {
                    uint256 _months = _seconds / 2629800;
                    _months = 36;
                    if (_months >= 1) {
                        if (_months > 36) {
                            _months = 36;
                        }
                        uint256 _tokens = IGLOO.balanceOf(address(this)) * _months / 10000;
                        uint256 _amountOut = router.getAmountOut(_tokens, _reserveIn, _reserveOut);
                        if (_amountOut >= maxTokenValue) {
                            _tokens = router.getAmountIn(maxTokenValue, _reserveIn, _reserveOut);
                        }
                        try IGLOO.transfer(msg.sender, _tokens) { IGLOO.resetLastFreeze(msg.sender); } catch {}
                    }
                }
            }
        } catch {}
    }

    function transfer(uint256 _id, address _user) external nonReentrant {
        require(freezeCounter > _id);
        Freeze storage _freeze = freezes[_id];
        require(_freeze.frozen);
        require(_freeze.user == msg.sender);
        _freeze.user = _user;
        freezes[_freeze.id] = _freeze;
        freezesByUser[_user].push(freezeCounter);
    }

    function refreeze(uint256 _id, uint256 _seconds) external nonReentrant {
        require(freezeCounter > _id);
        Freeze storage _freeze = freezes[_id];
        require(_freeze.frozen);
        require(_freeze.user == msg.sender);
        require(block.timestamp + _seconds >= _freeze.thawDate);
        if (block.timestamp >= _freeze.thawDate) {
            require(block.timestamp + _seconds >= block.timestamp);
        }
        _freeze.thawDate = block.timestamp + _seconds;
        freezes[_freeze.id] = _freeze;
    }

    function unfreeze(uint256 _id) external nonReentrant {
        require(freezeCounter > _id);
        Freeze storage _freeze = freezes[_id];
        require(_freeze.frozen);
        require(block.timestamp >= _freeze.thawDate);
        require(_freeze.user == msg.sender);

        _freeze.frozen = false;
        freezes[_freeze.id] = _freeze;

        IERC20 _Token = IERC20(_freeze.token);
        _Token.transfer(_freeze.user, _freeze.amount);
    }

    function setFee(uint256 _fee) external nonReentrant onlyTreasury {
        require(1 ether >= fee);
        fee = _fee;
    }

    function setTreasuryMPG(address _treasuryMPG) external nonReentrant onlyTreasury {
        treasuryMPG = _treasuryMPG;
    }

    function setTreasuryIGLOO(address _treasuryIGLOO) external nonReentrant onlyTreasury {
        treasuryIGLOO = _treasuryIGLOO;
    }

    function setTreasuryBps(uint256 _treasuryMPGBps, uint256 _treasuryIGLOOBps) external nonReentrant onlyTreasury {
        require(_treasuryMPGBps + _treasuryIGLOOBps == 10000);
        treasuryMPGBps = _treasuryMPGBps;
        treasuryIGLOOBps = _treasuryIGLOOBps;
    }

    function reqFee() external view returns (uint256) {
        return fee;
    }

    function reqTreasuryMPG() external view returns (address) {
        return treasuryMPG;
    }

    function reqTreasuryIGLOO() external view returns (address) {
        return treasuryIGLOO;
    }

    function reqTreasuryBps() external view returns (uint256, uint256) {
        return (treasuryMPGBps, treasuryIGLOOBps);
    }

    function reqIgloo() external view returns (address) {
        return address(IGLOO);
    }

    function reqNumFreezes() external view returns (uint256) {
        return freezeCounter;
    }

    function reqFreeze(uint256 _id, bool _updatedSupply) public view returns (Freeze memory) {
        Freeze memory _freeze = freezes[_id];
        if (_updatedSupply) {
            _freeze.supply = IERC20(_freeze.token).totalSupply();
        }
        return _freeze;
    }

    function reqFreezes(uint256 _from, uint256 _to, bool _updatedSupply) external view returns (Freeze[] memory) {
        Freeze[] memory _freezes = new Freeze[](_to - _from);
        uint256 _i = 0;
        for (uint256 _j = _from; _j < _to; _j++) {
            _freezes[_i] = reqFreeze(_j, _updatedSupply);
            _i++;
        }
        return _freezes;
    }

    function reqFreezeIDsByUser(address _user) external view returns (uint256[] memory) {
        return freezesByUser[_user];
    }

    function reqFreezesByUser(address _user, bool _updatedSupply) external view returns (Freeze[] memory) {
        Freeze[] memory _freezes = new Freeze[](freezesByUser[_user].length);
        uint256 _i = 0;
        for (uint256 _j = 0; _j < freezesByUser[_user].length; _j++) {
            Freeze memory _freeze = reqFreeze(freezesByUser[_user][_j], _updatedSupply);
            if (_freeze.user == _user) {
                _freezes[_i] = _freeze;
                _i++;
            }
        }
        return _freezes;
    }

    receive() external payable {}
}