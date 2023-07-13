/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.11;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol

pragma solidity ^0.6.11;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.6.11;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

pragma solidity ^0.6.11;

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

pragma solidity >=0.6.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
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

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    uint256[49] private __gap;
}

contract OneEightyICO is ContextUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address public receiver;
    uint256 public tokenusdprice;

    IBEP20 public usdToken;
    IBEP20 public daiToken;
    IBEP20 public usdcToken;
    IBEP20 public rewardToken;

    mapping(address => uint256) public userAmount;
    AggregatorV3Interface public priceProviderEth;
    AggregatorV3Interface public priceProviderusdc;
    AggregatorV3Interface public priceProviderdai;
    uint256 public tokenLimit;
    uint256 public test1;

    function initialize(
        IBEP20 _usdToken,
        IBEP20 _daiToken,
        IBEP20 _usdcToken,
        IBEP20 _rewardToken,
        uint256 _tokenusdprice,
        AggregatorV3Interface ppEth,
        AggregatorV3Interface ppUsdc,
        AggregatorV3Interface ppDai
    ) public initializer {
        rewardToken = _rewardToken;
        usdToken = _usdToken;
        daiToken = _daiToken;
        usdcToken = _usdcToken;
        tokenusdprice = _tokenusdprice;
        receiver = msg.sender;
        priceProviderEth = ppEth;
        priceProviderusdc = ppUsdc;
        priceProviderdai = ppDai;
        tokenLimit = 5000 * 1e18;

        __Ownable_init();
    }

    function depositUSD(uint256 _amount) public {
        require(_amount > 0, "need amount > 0");
        usdToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        usdToken.transfer(receiver, _amount);
        require(userAmount[msg.sender] + _amount <= tokenLimit,"User Exceed the limit");
        userAmount[msg.sender] = userAmount[msg.sender] + _amount;
        uint256 perToken = tokenusdprice.mul(_amount);
        uint256 swapToken = perToken.div(1000000); 
        test1 = swapToken;
        rewardToken.transfer(msg.sender, swapToken);
    }

    function depositETH() public payable {
        require(msg.value > 0, "need amount > 0");
        payable(receiver).transfer(msg.value);
        (, int latestPrice, , , ) = priceProviderEth.latestRoundData();
        uint256 currentPrice = uint256(latestPrice);
        uint256 perETH = currentPrice / 100000000;
        uint256 _ethamount = perETH * msg.value;
        require(userAmount[msg.sender] + _ethamount <= tokenLimit,"User Exceed the limit");
        userAmount[msg.sender] = userAmount[msg.sender] + _ethamount;
        uint256 perToken = tokenusdprice.mul(_ethamount);
        uint256 swapToken = perToken.div(1000000);
        test1 =swapToken;
        rewardToken.transfer(msg.sender, swapToken);
    }

    function depositDai(uint256 _amount) public {
        require(_amount > 0, "need amount > 0");
        daiToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        daiToken.transfer(receiver, _amount);
        (, int latestPrice, , , ) = priceProviderdai.latestRoundData();
        uint256 currentPrice = uint256(latestPrice);
        // uint256 perDai = currentPrice / 100000000;
        uint256 _daiamount = currentPrice * _amount;
        require(userAmount[msg.sender] + (_daiamount/100000000) <= tokenLimit,"User Exceed the limit");
        userAmount[msg.sender] = userAmount[msg.sender] + (_daiamount/100000000);
        uint256 perToken = tokenusdprice.mul(_daiamount);
        uint256 swapToken = perToken.div(100000000000000);
        test1 =swapToken;
        rewardToken.transfer(msg.sender, swapToken);
    }

    function depositUsdc(uint256 _amount) public {
        require(_amount > 0, "need amount > 0");
        usdcToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        usdcToken.transfer(receiver, _amount);
        (, int latestPrice, , , ) = priceProviderusdc.latestRoundData();
        uint256 currentPrice = uint256(latestPrice);
        // uint256 perUsdc = currentPrice / 100000000;
        uint256 _usdcamount = currentPrice * _amount;
        require(userAmount[msg.sender] + (_usdcamount/100000000) <= tokenLimit,"User Exceed the limit");
        userAmount[msg.sender] = userAmount[msg.sender] + (_usdcamount/100000000);
        uint256 perToken = tokenusdprice.mul(_usdcamount);
        uint256 swapToken = perToken.div(100000000000000);
        test1 =swapToken;
        rewardToken.transfer(msg.sender, swapToken);
    }

    function getTokenfromusd(uint256 _amount) public view returns (uint256) {
        uint256 perToken = tokenusdprice.mul(_amount);
        return perToken.div(1000000);
    }

    function getTokenfromETH(uint256 _amount) public view returns (uint256) {
        (, int latestPrice, , , ) = priceProviderEth.latestRoundData();
        uint256 currentPrice = uint256(latestPrice);
        uint256 perETh = currentPrice / 100000000;
        uint256 _ethamount = perETh * _amount;
        uint256 perToken = tokenusdprice.mul(_ethamount);
        return perToken.div(1000000);
    }

    function getTokenfromDai(uint256 _amount) public view returns (uint256) {
        (, int latestPrice, , , ) = priceProviderdai.latestRoundData();
        uint256 currentPrice = uint256(latestPrice);
        // uint256 perDai = currentPrice / 100000000;
        uint256 _daiamount = currentPrice * _amount;
        uint256 perToken = tokenusdprice.mul(_daiamount);
        return perToken.div(100000000000000);
    }

    function getTokenfromUsdc(uint256 _amount) public view returns (uint256) {
        (, int latestPrice, , , ) = priceProviderusdc.latestRoundData();
        uint256 currentPrice = uint256(latestPrice);
        // uint256 perUsdc = currentPrice / 1;
        uint256 _usdcamount = currentPrice * _amount;
        uint256 perToken = tokenusdprice.mul(_usdcamount);
        return perToken.div(100000000000000);
    }

    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function getETHPrice() public view returns (uint256) {
        (, int latestPrice, , , ) = priceProviderEth.latestRoundData();
        uint256 currentPrice = uint256(latestPrice) * 100000000;
        return currentPrice;
    }

    function getDaiPrice() public view returns (uint256) {
        (, int latestPrice, , , ) = priceProviderdai.latestRoundData();
        uint256 currentPrice = uint256(latestPrice) * 100000000;
        return currentPrice;
    }

    function getUsdcPrice() public view returns (uint256) {
        (, int latestPrice, , , ) = priceProviderusdc.latestRoundData();
        uint256 currentPrice = uint256(latestPrice) * 100000000;
        return currentPrice;
    }

    function safeWithDrawBENG(uint256 _amount, address addr) public onlyOwner {
        rewardToken.transfer(addr, _amount);
    }

    function safeWithDrawusd(uint256 _amount, address addr) public onlyOwner {
        usdToken.transfer(addr, _amount);
    }

    function safeWithDrawUsdc(uint256 _amount, address addr) public onlyOwner {
        usdcToken.transfer(addr, _amount);
    }

    function safeWithDrawDai(uint256 _amount, address addr) public onlyOwner {
        daiToken.transfer(addr, _amount);
    }

    function safeWithDrawEth(uint256 _amount, address addr) public onlyOwner {
        payable(addr).transfer(_amount);
    }

    function settoken(uint256 price) public onlyOwner {
        tokenusdprice = price;
    }

    function setReceiver(address newreceiver) public onlyOwner {
        receiver = newreceiver;
    }

    function updateTokenLimit(uint256 _limit) public onlyOwner {
        tokenLimit = _limit * 1e18;
    }
}