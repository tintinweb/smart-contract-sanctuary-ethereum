pragma solidity ^0.8.0;


import "./interfaces/IERC20.sol";
import "./NetherOracle.sol";
import "./interfaces/IVault.sol";
import "./interfaces/INether.sol";
import "./interfaces/IMasonry.sol";

   
   
   
   
    contract TreasuryTest is Ownable {
        IMetaStablePool public pool;
        INether public nether;
        IERC20 public core;
        IERC20 public nBond;
        IERC20 public balancerWeth;
        NetherOracle public oracle;
        IMasonry public masonry;

        IVault public vault;
        bytes32 public poolId;

        IVault.SwapKind public val;
        int256[] public deltas;

        IAsset public token1;
        IAsset public token2;
        IAsset public Zero_ETH;

        uint256 private seniorageThreshold = 1020000000000000000;
        uint256 private poolImbalance = 102;
        uint256 private bonusExpansion = 0;
        uint256 public bondAllocation = 0;
        uint256 public bondDiscount = 101;


        uint256 public circulatingBondAmount;
        event Received(address, uint);

        constructor(address _address

        ) {
            pool = IMetaStablePool(0xe053685f16968a350c8dEA6420281a41f72cE3AA);
            vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
            nether = INether(0x5CA15C0781F9033430a6d8BACfC9Ad313Fd3F1d9);
            balancerWeth = IERC20(0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1);
            //core = IERC20(_core);
            nBond = IERC20(0x2ae28ea8162099c1F3a92045EC5a6ad1919d7564);
            oracle = NetherOracle(_address);

            token1 = IAsset(0x5CA15C0781F9033430a6d8BACfC9Ad313Fd3F1d9);
            token2 = IAsset(0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1);
            poolId = 0xe053685f16968a350c8dea6420281a41f72ce3aa00020000000000000000006b;
            Zero_ETH = IAsset(0x0000000000000000000000000000000000000000);
        }

        // function getPreviousEpochPrice() internal {
        //     uint256[] twap = oracle.getTwap();
        // }

    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

        
        function sellNBonds(uint256 _amount) external payable {
            uint256[] memory balances = getPoolBalances();
            require(balances[0]>balances[1] * poolImbalance / 100, "peg above one");
            require(_amount > 0, "amount must be bigger than zero");
            address sender = msg.sender;
            balancerWeth.transferFrom(msg.sender, address(this), _amount);
            uint256 mintNBonds = _amount;
            nBond.testmint(sender, mintNBonds);
            balancerWeth.approve(address(vault), _amount);
            uint256 receivedNether = trade(token2,token1,_amount);
            nether.burn(receivedNether);
            
            }


        function sellNBondsETH() external payable{
            uint256[] memory balances = getPoolBalances();
            require(balances[0]>balances[1] * poolImbalance / 100, "peg above one");
            require(msg.value > 0, "amount must be bigger than zero");
            uint256 amount = msg.value;
            address sender = msg.sender;
            uint256 mintNBonds = msg.value;

            nBond.testmint(sender, mintNBonds);


            IVault.SwapKind swapKind = IVault.SwapKind.GIVEN_IN;
            //bytes memory swapData = abi.encode(swapKind);

            IVault.SingleSwap memory swapDescription = IVault.SingleSwap({
                poolId: poolId,
                kind: swapKind,
                assetIn: Zero_ETH,
                assetOut: token1,
                amount: amount,
                userData: "0x"
            });

            IVault.FundManagement memory fundManagement;
            fundManagement = IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });
            uint256 limit = 1;
            uint256 deadline = block.timestamp + 60;
            uint256 receivedNether = vault.swap{value: amount}(swapDescription, fundManagement, limit, deadline);
            nether.burn(receivedNether);
        }



        function buyNBondsETH(uint256 _amount) external {
                require(nBond.balanceOf(msg.sender) >= _amount, "sender must have nBonds");
                require(bondAllocation > _amount, "treasury doesnt have enough eth to pay yet");
                nBond.burnFrom(msg.sender, _amount);
                bondAllocation -= _amount;
                balancerWeth.transfer(msg.sender, _amount);

            }




        function seniorage() external {
                require(deltas[0] != 0, "deltas are back to zero wait for next epoch");
                nether.approve(address(vault), 100000000000000000000);
                uint256[] memory balances = getPoolBalances();
                require(balances[1]>balances[0], "price must be above 1");
                require(int256(balances[0]) + deltas[0] < int256(balances[1]) + deltas[1], "balance off");

                uint256 mintAmount = uint256(deltas[0]);
                
                nether.testmint(address(this), mintAmount);
                
                uint256 receivedWETH = trade(token1, token2, mintAmount);
                balances = getPoolBalances();
                assert(balances[1] > balances[0]);
    /*             if(bonusExpansion > 0) {
                    nether.mint(address(this), bonusExpansion * mintAmount / 100);
                    receivedWETH += tradeNetherForEther(bonusExpansion * mintAmount / 100);
                } */

                circulatingBondAmount = nBond.totalSupply();
                if(bondAllocation < circulatingBondAmount){
                   uint256 uncollateralizedBond = circulatingBondAmount - bondAllocation;
                    if (receivedWETH > uncollateralizedBond){
                        bondAllocation += uncollateralizedBond;
                        //allocateToMasonry(receivedWETH-uncollateralizedBond);
                    } else {
                        bondAllocation += receivedWETH;

                    }
                    
                } else if(bondAllocation >= circulatingBondAmount) {
                    //allocateToMasonry(receivedWETH);
                }
                deltas[0] = 0;
                deltas[1] = 0;

                

            
        }


        function allocateToMasonry(uint256 _seniorageRev) internal{
            payable(address(masonry)).transfer(_seniorageRev);
        }

        function trade(IAsset _tokenin, IAsset _tokenout,uint256 _tradeAmount) internal returns(uint256) {
            IVault.SwapKind swapKind = IVault.SwapKind.GIVEN_IN;
            //bytes memory swapData = abi.encode(swapKind);

            IVault.SingleSwap memory swapDescription = IVault.SingleSwap({
                poolId: poolId,
                kind: swapKind,
                assetIn: _tokenin,
                assetOut: _tokenout,
                amount: _tradeAmount,
                userData: "0x"
            });

            IVault.FundManagement memory fundManagement;
            fundManagement = IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });
            uint256 limit = 1;
            uint256 deadline = block.timestamp + 60;
            uint256 receivedNether = vault.swap(swapDescription, fundManagement, limit, deadline);
            return receivedNether;
        }


        function callQueryBatchSwap(uint256 _tradeAmount)
            internal
            returns (int256[] memory)
        {
            //uint256[] memory a = new uint256[](1);
            //a[0] = 5;
            //return _address.staticcall(abi.encodeWithSignature("arr(uint256[])",a));

            IAsset[] memory tokens = new IAsset[](2);
            tokens[0] = token1;
            tokens[1] = token2;
            IVault.SwapKind swapKind = IVault.SwapKind.GIVEN_IN;

            IVault.BatchSwapStep[] memory swapSteps = new IVault.BatchSwapStep[](1);
            IVault.BatchSwapStep memory swapStep = IVault.BatchSwapStep({
                poolId: poolId,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: _tradeAmount,
                userData: "0x"
            });

            swapSteps[0] = swapStep;

            IVault.FundManagement memory fundManagement;
            fundManagement = IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });

            int256[] memory deltasMem;
            deltasMem = vault.queryBatchSwap(
                swapKind,
                swapSteps,
                tokens,
                fundManagement
            );
            return deltasMem;
        }



        function calculateMintAmount(int256 _errorMargin)
            public
            returns  (int256[] memory)
        {

            uint256 previousEpochPrice = oracle.getTwap();
            if (previousEpochPrice > seniorageThreshold) {


            uint256[] memory balances = getPoolBalances();
            uint256 midVal = (balances[0] + balances[1]) / 2;
            uint256 approximateMintAmount = (balances[1] - midVal);
            uint256 max_amount_in = balances[0] * 290 / 1000;
            
            if (max_amount_in < approximateMintAmount) {
                deltas = callQueryBatchSwap(max_amount_in);
                return deltas;
            }  else {
            int256[] memory deltasMemo = callQueryBatchSwap(approximateMintAmount);
            deltas = deltasMemo;
            int256 errorMargin = _errorMargin;
            

            while (
                int256(balances[0]) + deltasMemo[0] >
                int256(balances[1]) + deltasMemo[1]
            ) {
                approximateMintAmount -= uint256(errorMargin);
                deltasMemo = callQueryBatchSwap(approximateMintAmount);
            }
                        
            deltas = deltasMemo;
            
            return deltas;
            }} else {
                revert("price below threshold");
            }
        }

        ///////////// VIEW FUNCTIONS /////////////
        function getPoolBalances() internal view returns (uint256[] memory) {
            (, uint256[] memory balances, ) = vault.getPoolTokens(poolId);
            return balances;
        }


        function checkBondSale() external view returns(bool) {
            uint256[] memory balances = getPoolBalances();
            if(balances[0]>balances[1] * poolImbalance / 100) {
                return true;
            } else {
                return false;
            }
        
        }

        function checkAboveOne() internal view returns(bool) {
            (, uint256[] memory balances, ) = vault.getPoolTokens(poolId);
            if (balances[1] > balances[0]) {
                return true;
            } else {
                return false;
            }
        }


            function getCurrentNetherPrice() internal returns(uint256) {
            return oracle.getCurrentPrice();
        }




    //////////////GOVERNANCE//////////////

        function setBonusExpansion(uint256 _bonusExpansion) external onlyOwner {
            bonusExpansion = _bonusExpansion;
        }

    //////// HELPERS ///////////

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
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

    function mint(address to, uint256 amount) external;
    
    function burn(uint256 amount) external; 

        function testmint(address to, uint256 amount) external;
           function burnFrom(address account, uint256 amount) external;
}

import "./interfaces/IMetaStablePool.sol";
import "./interfaces/Epoch.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IMasonry.sol";


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract NetherOracle is Epoch {

    enum Variable { PAIR_PRICE, BPT_PRICE, INVARIANT }
        IMetaStablePool public pool;
        uint256 public price;
        uint256[] public twapArr;
        uint256 public twap;

        uint256 public epochPeriod;
        IVault public vault;
        bytes32 public poolId;

        IAsset private token1;
        IAsset private token2;

        uint256 public oracleIndex;



    constructor( uint256 _epochPeriod) Epoch(_epochPeriod,block.timestamp,0)  {
        pool = IMetaStablePool(0xe053685f16968a350c8dEA6420281a41f72cE3AA);
        epochPeriod = _epochPeriod;
        vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        poolId = 0xe053685f16968a350c8dea6420281a41f72ce3aa00020000000000000000006b;

        token1 = IAsset(0x5CA15C0781F9033430a6d8BACfC9Ad313Fd3F1d9);
        token2 = IAsset(0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1);
    }

    
    function getCurrentPrice() external returns(uint256) {
        price = pool.getLatest(IMetaStablePool.Variable.PAIR_PRICE);
        return price;

    }

    

    function getTwap() external checkEpoch returns(uint256) {
        
        (,,,oracleIndex,) = pool.getOracleMiscData();
        if (oracleIndex < 1024) {
            (,uint256[] memory balances) = getPoolBalances();
            if(balances[0] * 102 / 100 < balances[1]) {
                twap = 2 ether;
                return twap;
            }

            
        } else {


        IMetaStablePool.OracleAverageQuery[] memory queries = new IMetaStablePool.OracleAverageQuery[](1);
        IMetaStablePool.OracleAverageQuery memory query = IMetaStablePool.OracleAverageQuery({
            variable: IMetaStablePool.Variable.PAIR_PRICE,
            secs: epochPeriod,
            ago: block.timestamp - nextEpochPoint()
          });
        queries[0] = query;
        


        twapArr = pool.getTimeWeightedAverage(queries);
        return (twapArr[0]);
    }}


    


        function getPoolBalances() public view returns (IERC20[] memory,uint256[] memory) {
            (IERC20[] memory tokens, uint256[] memory balances, ) = vault.getPoolTokens(poolId);
            return (tokens,balances);
        }






}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.



pragma solidity ^0.8.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */

 import "./IERC20.sol";
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IVault {


    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest memory request
    ) external payable;



    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;



    struct SingleSwap {
   bytes32 poolId;
   SwapKind kind;
   IAsset assetIn;
   IAsset assetOut;
   uint256 amount;
   bytes userData;
}

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
}

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    )
        external
        payable

        returns (uint256 amountCalculated);



    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;

        
    }
    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas); 

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INether {
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


    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external; 
    function testmint(address to, uint256 amount) external;
}

interface IMasonry {

}

pragma solidity ^0.8.0;

interface IMetaStablePool {
    function enableOracle() external;

    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }

    function getLatest(Variable variable) external returns (uint256);

    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }

    function getRate() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        returns (uint256[] memory results);

    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    function approve(address spender, uint256 amount) external returns (bool);
    function totalSupply() external returns (uint256);

    function getOracleMiscData()
        external
        view
        returns (
            int256 logInvariant,
            int256 logTotalSupply,
            uint256 oracleSampleCreationTimestamp,
            uint256 oracleIndex,
            bool oracleEnabled
        );

    function getPoolId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Operator.sol";

contract Epoch is Operator {
    using SafeMath for uint256;

    uint256 private period;
    uint256 private startTime;
    uint256 private lastEpochTime;
    uint256 private epoch;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _period,
        uint256 _startTime,
        uint256 _startEpoch
    ) {
        period = _period;
        startTime = _startTime;
        epoch = _startEpoch;
        lastEpochTime = startTime.sub(period);
    }

    /* ========== Modifier ========== */

    modifier checkStartTime() {
        require(block.timestamp >= startTime, "Epoch: not started yet");

        _;
    }

    modifier checkEpoch() {
        uint256 _nextEpochPoint = nextEpochPoint();
        if (block.timestamp < _nextEpochPoint) {
            require(
                msg.sender == operator(),
                "Epoch: only operator allowed for pre-epoch"
            );
            _;
        } else {
            _;

            for (;;) {
                lastEpochTime = _nextEpochPoint;
                ++epoch;
                _nextEpochPoint = nextEpochPoint();
                if (block.timestamp < _nextEpochPoint) break;
            }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getCurrentEpoch() public view returns (uint256) {
        return epoch;
    }

    function getPeriod() public view returns (uint256) {
        return period;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getLastEpochTime() public view returns (uint256) {
        return lastEpochTime;
    }

    function nextEpochPoint() public view returns (uint256) {
        return lastEpochTime.add(period);
    }

    /* ========== GOVERNANCE ========== */

    function setPeriod(uint256 _period) external onlyOperator {
        require(
            _period >= 1 hours && _period <= 48 hours,
            "_period: out of range"
        );
        period = _period;
    }

    function setEpoch(uint256 _epoch) external onlyOperator {
        epoch = _epoch;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            "operator: caller is not the operator"
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(
            newOperator_ != address(0),
            "operator: zero address given for new operator"
        );
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
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