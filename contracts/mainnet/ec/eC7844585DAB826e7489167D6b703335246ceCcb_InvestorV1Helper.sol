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
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import './interfaces/IInvestorV1Factory.sol';
import './interfaces/IInvestorV1Pool.sol';


contract InvestorV1Helper {
    struct PoolInfo {
        address pooladdr;
        string  name;
        string status;
        uint256 capacity;
        uint256 funded;
        uint256 exited;
        uint256 staked;
        uint256 oraclePrice;
        uint24 apy;
        uint24 fee;
        uint256 mystake;
        uint256 myfund;
        uint256 myrevenue;
        bool claimed;
    }

    address public factory;
    address public owner;

    address public constant HSF = 0xbA6B0dbb2bA8dAA8F5D6817946393Aef8D3A4487;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(address _factory) {
        factory = _factory;
        owner = msg.sender;
    }

    function setOwner(address _owner) public {
        require(msg.sender == owner, "InvestorV1Helper: not owner");
        owner = _owner;
    }

    function setFactory(address _factory) public {
        require(msg.sender == owner, "InvestorV1Helper: not owner");
        factory = _factory;
    }

    function getAllPools(address _account) public view returns (PoolInfo[] memory) {
        uint256 poolLen = IInvestorV1Factory(factory).pools();
        PoolInfo[] memory pl = new PoolInfo[](poolLen);
        for(uint i=0; i<poolLen; i++) {
            address targetPool = IInvestorV1Factory(factory).poolList(i);
            pl[i] = PoolInfo({
                pooladdr: targetPool,
                name: IInvestorV1Pool(targetPool).name(),
                status: IInvestorV1Pool(targetPool).getPoolState(),
                capacity: IInvestorV1Pool(targetPool).capacity(),
                funded: IInvestorV1Pool(targetPool).funded(),
                exited: IInvestorV1Pool(targetPool).exited(),
                staked: IInvestorV1Pool(targetPool).restaked(),
                oraclePrice: IInvestorV1Pool(targetPool).oraclePrice(),
                apy: IInvestorV1Pool(targetPool).interestRate(),
                fee: IInvestorV1Pool(targetPool).fee(),
                mystake: IInvestorV1Pool(targetPool).restakeAmt(_account),
                myfund: IInvestorV1Pool(targetPool).pooledAmt(_account),
                myrevenue: IInvestorV1Pool(targetPool).expectedRevenue(_account),
                claimed:  IInvestorV1Pool(targetPool).claimed(_account)
            });
        }
        return pl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1Factory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event DAOChanged(address indexed oldDAO, address indexed newDAO);

    event PoolCreated(
        address operator,
        string name,
        uint256 fundId,
        uint256 capacity,
        uint256 startTime,
        uint256 stageTime,
        uint256 endTime,
        uint24 fee,
        uint24 interestRate,
        address pool
    );

    function owner() external view returns (address); 
    function dao() external view returns (address); 

    function pools() external view returns (uint256);

    function poolList(uint256 index) external view returns (address);

    function createPool(
        address operator,
        string memory name,
        uint256 capacity,
        uint256 oraclePrice,
        uint256 startTime,
        uint256 stageTime,
        uint256 endTime,
        uint24 fee,
        uint24 interestRate
    ) external returns (address pool);

    function setOwner(address _owner) external;
    function setDAO(address _dao) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './IInvestorV1PoolImmutables.sol';
import './IInvestorV1PoolState.sol';
import './IInvestorV1PoolDerivedState.sol';
import './IInvestorV1PoolActions.sol';
import './IInvestorV1PoolOperatorActions.sol';
import './IInvestorV1PoolEvents.sol';

interface IInvestorV1Pool is 
    IInvestorV1PoolImmutables,
    IInvestorV1PoolState,
    IInvestorV1PoolDerivedState,
    IInvestorV1PoolActions,
    IInvestorV1PoolOperatorActions,
    IInvestorV1PoolEvents 
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolActions {
    function update() external returns (bool);
    function deposit(uint256 amount) external returns (bool);
    function withdraw(uint256 amount, address to) external returns (bool);
    function exit(uint256 amount, address to) external returns (bool);
    function claim(address to) external returns (bool);
    function restake(uint256 amount) external returns (bool);
    function unstake(uint256 amount, address to) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolDerivedState {
    function expectedRestakeRevenue(uint256 amount) external view returns (uint256);
    function expectedRevenue(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolEvents {
    event PoolOpened(address operator, uint256 startTime, uint256 tokenDeposit);
    event PoolActiviated(uint256 funded);
    event PoolLiquidated(uint256 liquidityFund);
    event PoolDishonored(uint256 requiredFund, uint256 liquidityFund);
    event PoolReverted(uint256 minCapacity, uint256 funded);

    event OraclePriceChanged(uint256 oraclePrice);
    event PoolDetailLinkChanged(string link);
    event ColletralHashChanged(string oldHash, string newHash);
    event ColletralLinkChanged(string oldLink, string newLink);

    event Deposit(address token, address from, uint256 amount);
    event Withdrawal(address token, address from, address to, uint256 amount);
    event Claim(address from, address to, uint256 amount);
    event Exited(address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolImmutables {
    function factory() external view returns (address);
    function operator() external view returns (address);
    function name() external view returns (string memory);
    function capacity() external view returns (uint256);
    function fundId() external view returns (uint256);
    function startTime() external view returns (uint256);
    function stageTime() external view returns (uint256);
    function endTime() external view returns (uint256);
    function fee() external view returns (uint24);
    function interestRate() external view returns (uint24);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolOperatorActions {
    function setOraclePrice(uint256 _oraclePrice) external returns (bool);
    function setColletralHash(string memory _newHash) external returns (bool);
    function setColletralLink(string memory _newLink) external returns (bool);
    function setPoolDetailLink(string memory _newLink) external returns (bool);
    function rescue(address target) external returns (bool);
    function pullDeposit() external returns (bool);
    function liquidate() external returns (bool);
    function openPool() external returns (bool);
    function closePool() external returns (bool);
    function revertPool() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IInvestorV1PoolState {
    function funded() external view returns (uint256);
    function exited() external view returns (uint256);
    function restaked() external view returns (uint256);
    function oraclePrice() external view returns (uint256);
    function getPoolState() external view returns (string memory);
    function pooledAmt(address user) external view returns (uint256);
    function restakeAmt(address user) external view returns (uint256);
    function claimed(address user) external view returns (bool);
    function collateralDocument() external view returns (string memory);
    function detailLink() external view returns (string memory);
    function collateralHash() external view returns (string memory);
    function depositors() external view returns (uint256);
    function restakers() external view returns (uint256);
    function depositorList(uint256 index) external view returns (address);
    function restakerList(uint256 index) external view returns (address);
    function getInfo(address _account) external view returns (string memory, string memory, uint256, uint256, uint256, uint256, uint256, uint24);
    function getExtra() external view returns (address, uint256, uint256, uint256, string memory, string memory, string memory);
}