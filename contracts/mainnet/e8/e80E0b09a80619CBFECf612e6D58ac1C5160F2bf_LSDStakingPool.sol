/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDStorage {
    // Depoly status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns (address);

    function setGuardian(address _newAddress) external;

    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function getUint(bytes32 _key) external view returns (uint256);

    function getString(bytes32 _key) external view returns (string memory);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int256);

    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;

    function setUint(bytes32 _key, uint256 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int256 _value) external;

    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;

    function subUint(bytes32 _key, uint256 _amount) external;
}

pragma solidity ^0.8.9;
/// @title Base settings / modifiers for each contract in LSD

abstract contract LSDBase {
    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contact where primary persistant storage is maintained
    ILSDStorage lsdStorage;

    /*** Modifiers ***********************************************************/

    /**
     * @dev Throws if called by any sender that doesn't match a LSD network contract
     */
    modifier onlyLSDNetworkContract() {
        require(
            getBool(
                keccak256(abi.encodePacked("contract.exists", msg.sender))
            ),
            "Invalid contract"
        );
        _;
    }

    /**
     * @dev Throws if called by any sender that doesn't match one of the supplied contract
     */
    modifier onlyLSDContract(
        string memory _contractName,
        address _contractAddress
    ) {
        require(
            _contractAddress ==
                getAddress(
                    keccak256(
                        abi.encodePacked("contract.address", _contractName)
                    )
                ),
            "Invalid contract"
        );
        _;
    }

    /*** Methods **********************************************************************/

    /// @dev Set the main LSD storage address
    constructor(ILSDStorage _lsdStorageAddress) {
        // Update the contract address
        lsdStorage = ILSDStorage(_lsdStorageAddress);
    }

    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName)
        internal
        view
        returns (address)
    {
        // Get the current contract address
        address contractAddress = getAddress(
            keccak256(abi.encodePacked("contract.address", _contractName))
        );
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        return contractAddress;
    }

    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress)
        internal
        view
        returns (string memory)
    {
        // Get the contract name
        string memory contractName = getString(
            keccak256(abi.encodePacked("contract.name", _contractAddress))
        );
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /*** LSD Storage Methods ********************************************************/

    // Note: Uused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) {
        return lsdStorage.getAddress(_key);
    }

    function getUint(bytes32 _key) internal view returns (uint256) {
        return lsdStorage.getUint(_key);
    }

    function getString(bytes32 _key) internal view returns (string memory) {
        return lsdStorage.getString(_key);
    }

    function getBytes(bytes32 _key) internal view returns (bytes memory) {
        return lsdStorage.getBytes(_key);
    }

    function getBool(bytes32 _key) internal view returns (bool) {
        return lsdStorage.getBool(_key);
    }

    function getInt(bytes32 _key) internal view returns (int256) {
        return lsdStorage.getInt(_key);
    }

    function getBytes32(bytes32 _key) internal view returns (bytes32) {
        return lsdStorage.getBytes32(_key);
    }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal {
        lsdStorage.setAddress(_key, _value);
    }

    function setUint(bytes32 _key, uint256 _value) internal {
        lsdStorage.setUint(_key, _value);
    }

    function setString(bytes32 _key, string memory _value) internal {
        lsdStorage.setString(_key, _value);
    }

    function setBytes(bytes32 _key, bytes memory _value) internal {
        lsdStorage.setBytes(_key, _value);
    }

    function setBool(bytes32 _key, bool _value) internal {
        lsdStorage.setBool(_key, _value);
    }

    function setInt(bytes32 _key, int256 _value) internal {
        lsdStorage.setInt(_key, _value);
    }

    function setBytes32(bytes32 _key, bytes32 _value) internal {
        lsdStorage.setBytes32(_key, _value);
    }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal {
        lsdStorage.deleteAddress(_key);
    }

    function deleteUint(bytes32 _key) internal {
        lsdStorage.deleteUint(_key);
    }

    function deleteString(bytes32 _key) internal {
        lsdStorage.deleteString(_key);
    }

    function deleteBytes(bytes32 _key) internal {
        lsdStorage.deleteBytes(_key);
    }

    function deleteBool(bytes32 _key) internal {
        lsdStorage.deleteBool(_key);
    }

    function deleteInt(bytes32 _key) internal {
        lsdStorage.deleteInt(_key);
    }

    function deleteBytes32(bytes32 _key) internal {
        lsdStorage.deleteBytes32(_key);
    }

    /// @dev Storage arithmetic methods
    function addUint(bytes32 _key, uint256 _amount) internal {
        lsdStorage.addUint(_key, _amount);
    }

    function subUint(bytes32 _key, uint256 _amount) internal {
        lsdStorage.subUint(_key, _amount);
    }
}

pragma solidity ^0.8.9;

interface ILSDStakingPool {
    function getTotalLSD() external view returns (uint256);

    //--------------------------------------------------
    function addLiquidity(uint256 _lsdTokenAmount) external payable;

    function removeLiquidity(uint256 _amount) external;

    function getTotalLPTokenBalance() external view returns (uint256);

    function getClaimAmountByLiquidity(
        address _address
    ) external view returns (uint256);

    function claimByLiquidity() external;

    function getTotalRewardsByLiquidity() external view returns (uint256);

    function getStakedLP(address _address) external view returns (uint256);

    function getEarnedByLiquidity(
        address _address
    ) external view returns (uint256);
}

pragma solidity ^0.8.9;

interface ILSDOwner {
    function getApy() external view returns (uint256);

    function getStakeApr() external view returns (uint256);

    function getBonusApr() external view returns (uint256);

    function getBonusEnabled() external view returns (bool);

    function getBonusPeriod() external view returns (uint256);

    function getMultiplier() external view returns (uint256);

    function getLIDOApy() external view returns (uint256);

    function getRPApy() external view returns (uint256);

    function getSWISEApy() external view returns (uint256);

    function getProtocolFee() external view returns (uint256);

    function getMinimumDepositAmount() external view returns (uint256);

    function setApy(uint256 _apy) external;

    function setStakeApr(uint256 _stakeApr) external;

    function setBonusApr(uint256 _bonusApr) external;

    function setBonusPeriod(uint256 _bonusPeriod) external;

    function setBonusEnabled(bool _bonusEnabled) external;

    function setMultiplier(uint256 _multiplier) external;

    function setRPApy(uint256 _rpApy) external;

    function setLIDOApy(uint256 _lidoApy) external;

    function setSWISEApy(uint256 _swiseApy) external;

    function setProtocolFee(uint256 _protocalFee) external;

    function setMinimumDepositAmount(uint256 _minimumDepositAmount) external;

    function upgrade(
        string memory _type,
        string memory _name,
        string memory _contractAbi,
        address _contractAddress
    ) external;
}

pragma solidity ^0.8.9;

interface ILSDToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

pragma solidity ^0.8.9;
interface ILSDTokenVELSD is IERC20 {
    function mint(address _address, uint256 _amount) external;

    function burn(address _address, uint256 _amount) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.9;
// The main entry to stake LSD token.

contract LSDStakingPool is LSDBase, ILSDStakingPool {
    // events
    event Claimed(
        address indexed userAddress,
        uint256 amount,
        uint256 claimTime
    );
    event AddLiquidity(
        address indexed userAddress,
        uint256 amount,
        uint256 addTime
    );

    event RemoveLiquidity(
        address indexed userAddress,
        uint256 amount,
        uint256 removeTime
    );

    struct UserByLSD {
        uint256 balance;
        uint256 claimAmount;
        uint256 firstTime;
        uint256 lastTime;
        uint256 earnedAmount;
    }

    struct UserByLiquidity {
        uint256 balance;
        uint256 claimAmount;
        uint256 firstTime;
        uint256 lastTime;
        uint256 earnedAmount;
    }

    uint256 private totalRewardsByLiquidity;
    mapping(address => UserByLiquidity) public usersByLiquidity;

    uint256 private ONE_DAY_IN_SECS = 24 * 60 * 60;
    uint constant MAX_UINT = 2 ** 256 - 1;
    address uniLPAddress = 0xB92FE026Bd8F5539079c06F4e44f88515E7304C9;

    // Construct
    constructor(ILSDStorage _lsdStorageAddress) LSDBase(_lsdStorageAddress) {
        version = 1;
    }

    // get total staking LSD
    function getTotalLSD() public view override returns (uint256) {
        ILSDToken lsdToken = ILSDToken(getContractAddress("lsdToken"));
        return lsdToken.balanceOf(address(this));
    }

    // remove LSD - This is a switch
    function removeLSD(
        uint256 amount
    ) public onlyLSDContract("lsdDaoContract", msg.sender) {
        ILSDToken lsdToken = ILSDToken(getContractAddress("lsdToken"));
        lsdToken.transfer(msg.sender, amount);
    }

    function addLiquidity(uint256 _lsdTokenAmount) public payable override {
        ILSDToken lsdToken = ILSDToken(getContractAddress("lsdToken"));
        // check the balance
        require(lsdToken.balanceOf(msg.sender) >= _lsdTokenAmount);
        // transfer tokens to this contract.
        lsdToken.transferFrom(msg.sender, address(this), _lsdTokenAmount);
        // check allowance
        require(
            lsdToken.allowance(msg.sender, address(this)) >= _lsdTokenAmount,
            "Invalid allowance"
        );

        if (
            lsdToken.allowance(
                address(this),
                getContractAddress("uniswapRouter")
            ) < _lsdTokenAmount
        ) {
            lsdToken.approve(getContractAddress("uniswapRouter"), MAX_UINT);
        }

        uint256 beforeLiquidity = getTotalLPTokenBalance();
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(
            getContractAddress("uniswapRouter")
        );

        uniswapRouter.addLiquidityETH{value: msg.value}(
            getContractAddress("lsdToken"),
            _lsdTokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 15
        );
        uint256 afterLiquidity = getTotalLPTokenBalance();
        uint256 balance = afterLiquidity - beforeLiquidity;

        // check if already staked user
        UserByLiquidity storage user = usersByLiquidity[msg.sender];
        if (user.firstTime == 0) {
            user.balance = balance;
            user.claimAmount = 0;
            user.earnedAmount = 0;
            user.firstTime = block.timestamp;
            user.lastTime = block.timestamp;
        } else {
            uint256 excessAmount = getClaimAmountByLiquidity(msg.sender);
            user.balance += balance;
            user.claimAmount = excessAmount;
            user.lastTime = block.timestamp;
        }

        // submit event
        emit AddLiquidity(msg.sender, balance, block.timestamp);
    }

    // Remove Liquidity
    function removeLiquidity(uint256 _amount) public override {
        UserByLiquidity storage user = usersByLiquidity[msg.sender];
        require(user.balance >= _amount, "Invalid amount");

        uint256 excessAmount = getClaimAmountByLiquidity(msg.sender);
        user.balance -= _amount;
        user.claimAmount = excessAmount;
        user.lastTime = block.timestamp;

        IUniswapV2Pair pair = IUniswapV2Pair(uniLPAddress);
        pair.transfer(msg.sender, _amount);

        // submit event
        emit RemoveLiquidity(msg.sender, _amount, block.timestamp);
    }

    // Get Claim Amount By Liquidity Staking
    function getClaimAmountByLiquidity(
        address _address
    ) public view override returns (uint256) {
        UserByLiquidity memory user = usersByLiquidity[_address];

        if (block.timestamp >= user.lastTime + ONE_DAY_IN_SECS) {
            IUniswapV2Pair pair = IUniswapV2Pair(uniLPAddress);
            (
                uint112 _reserve0,
                uint112 _reserve1,
                uint32 _blockTimestampLast
            ) = pair.getReserves();
            uint256 totalSupply = pair.totalSupply();

            uint256 balance = (user.balance * _reserve0 * 2) / totalSupply;

            ILSDOwner lsdOwner = ILSDOwner(getContractAddress("lsdOwner"));
            uint256 apr = lsdOwner.getStakeApr();
            uint256 bonusApr = lsdOwner.getBonusApr();
            uint256 bonusPeriod = lsdOwner.getBonusPeriod();
            bool bonusEnabled = lsdOwner.getBonusEnabled();

            uint256 bonusFinishTime = user.firstTime +
                bonusPeriod *
                ONE_DAY_IN_SECS;

            uint256 dayPassedFromLastDay = (block.timestamp - user.lastTime) /
                ONE_DAY_IN_SECS;

            uint256 dayPassedFromFirstDay = (block.timestamp - user.firstTime) /
                ONE_DAY_IN_SECS;

            if (bonusEnabled) {
                if (user.lastTime > bonusFinishTime) {
                    return
                        user.claimAmount +
                        ((balance * dayPassedFromLastDay * apr) / (365 * 100));
                } else if (dayPassedFromFirstDay > bonusPeriod) {
                    return
                        user.claimAmount +
                        (balance *
                            ((dayPassedFromFirstDay - bonusPeriod) *
                                apr +
                                (bonusPeriod +
                                    dayPassedFromLastDay -
                                    dayPassedFromFirstDay) *
                                bonusApr)) /
                        (365 * 100);
                } else {
                    return
                        user.claimAmount +
                        (balance * dayPassedFromLastDay * bonusApr) /
                        (365 * 100);
                }
            } else {
                return
                    user.claimAmount +
                    (balance * apr * dayPassedFromLastDay) /
                    (365 * 100);
            }
        } else {
            return user.claimAmount;
        }
    }

    function getTotalLPTokenBalance() public view override returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniLPAddress);
        return pair.balanceOf(address(this));
    }

    // Claim bonus by Liquidity
    function claimByLiquidity() public override {
        uint256 excessAmount = getClaimAmountByLiquidity(msg.sender);
        require(excessAmount > 0, "Invalid call");
        require(excessAmount <= getTotalLSD());

        ILSDToken lsdToken = ILSDToken(getContractAddress("lsdToken"));
        lsdToken.transfer(msg.sender, excessAmount);

        UserByLiquidity storage user = usersByLiquidity[msg.sender];
        user.lastTime = block.timestamp;
        user.claimAmount = 0;
        user.earnedAmount += excessAmount;
        totalRewardsByLiquidity += excessAmount;
        // emit claim event
        emit Claimed(msg.sender, excessAmount, block.timestamp);
    }

    // Get total rewards by liquidity
    function getTotalRewardsByLiquidity()
        public
        view
        override
        returns (uint256)
    {
        return totalRewardsByLiquidity;
    }

    // Get Staked LP
    function getStakedLP(
        address _address
    ) public view override returns (uint256) {
        UserByLiquidity memory user = usersByLiquidity[_address];
        return user.balance;
    }

    function getEarnedByLiquidity(
        address _address
    ) public view override returns (uint256) {
        UserByLiquidity memory user = usersByLiquidity[_address];
        return user.earnedAmount;
    }

    // This is a switch
    function removeLPToken()
        public
        onlyLSDContract("lsdDaoContract", msg.sender)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(uniLPAddress);
        pair.transfer(msg.sender, getTotalLPTokenBalance());
    }
}