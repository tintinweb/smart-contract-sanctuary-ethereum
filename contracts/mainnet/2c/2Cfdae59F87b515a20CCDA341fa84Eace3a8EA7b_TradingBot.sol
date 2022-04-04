// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;
import "./ITrading.sol";
import "./IERC20.sol";
abstract contract DyDxPool is ITrading {
    function getAccountWei(Info memory account, uint256 marketId) public view virtual returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public virtual;
}
contract DyDxFlashLoan is ITrading {
    /*///////////////////////////////////////////////////////////////
                        State Variables
    //////////////////////////////////////////////////////////////*/
    DyDxPool pool = DyDxPool(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
    /// @dev Assets availabe for flashloan at DyDx
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public SAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    /*///////////////////////////////////////////////////////////////
                       Mappings
    //////////////////////////////////////////////////////////////*/
    mapping(address => uint256) public currencies;
    /*///////////////////////////////////////////////////////////////
                       Modifiers
    //////////////////////////////////////////////////////////////*/
    modifier onlyPool() {
        require(msg.sender == address(pool), "FlashLoan: could be called by DyDx pool only");
        _;
    }
    constructor() {
        currencies[WETH] = 1;
        currencies[SAI] = 2;
        currencies[USDC] = 3;
        currencies[DAI] = 4;
    }
    function tokenToMarketId(address token) public view returns (uint256) {
        uint256 marketId = currencies[token];
        require(marketId != 0, "FlashLoan: Unsupported token");
        return marketId - 1;
    }
    // the DyDx will call `callFunction(address sender, Info memory accountInfo, bytes memory data) public` after during `operate` call
    function flashloan(
        address token,
        uint256 amount,
        bytes memory data
    ) internal {
        IERC20(token).approve(address(pool), amount + 1);
        Info[] memory infos = new Info[](1);
        ActionArgs[] memory args = new ActionArgs[](3);
        infos[0] = Info(address(this), 0);
        AssetAmount memory wamt = AssetAmount(false, AssetDenomination.Wei, AssetReference.Delta, amount);
        ActionArgs memory withdraw;
        withdraw.actionType = ActionType.Withdraw;
        withdraw.accountId = 0;
        withdraw.amount = wamt;
        withdraw.primaryMarketId = tokenToMarketId(token);
        withdraw.otherAddress = address(this);
        args[0] = withdraw;
        ActionArgs memory call;
        call.actionType = ActionType.Call;
        call.accountId = 0;
        call.otherAddress = address(this);
        call.data = data;
        args[1] = call;
        ActionArgs memory deposit;
        AssetAmount memory damt = AssetAmount(true, AssetDenomination.Wei, AssetReference.Delta, amount + 1);
        deposit.actionType = ActionType.Deposit;
        deposit.accountId = 0;
        deposit.amount = damt;
        deposit.primaryMarketId = tokenToMarketId(token);
        deposit.otherAddress = address(this);
        args[2] = deposit;
        pool.operate(infos, args);
    }
}
contract TradingBot is DyDxFlashLoan {
    /*///////////////////////////////////////////////////////////////
                        State Variables
    //////////////////////////////////////////////////////////////*/
    //  uint256 reserve = 2 ether;
    uint256 public loan;
    // Addresses
    address payable owner;
    /// @dev OneInch Router Config
    address private oneInchRouter;
    // ZRX Config
    address public ZRX_EXCHANGE_ADDRESS;
    address public ZRX_ERC20_PROXY_ADDRESS;
    /// @dev Fee collector
    address ZRX_STAKING_PROXY = 0xa26e80e7Dea86279c6d778D702Cc413E6CFfA777;
    /*///////////////////////////////////////////////////////////////
                        Modifiers
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner!");
        _;
    }
    constructor(address router_) payable {
        oneInchRouter = router_;
        _getWeth(msg.value);
        _approveWeth(msg.value);
        owner = payable(msg.sender);
        ZRX_EXCHANGE_ADDRESS = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
        ZRX_ERC20_PROXY_ADDRESS = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    }
    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/
    /// @dev Lets the contract receive native tokens e.g ether
    receive() external payable {}
    /// @dev Keep this function in case the contract receives tokens!
    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(owner, balance);
    }
    /// @dev Keep this function in case the contract keeps leftover ether!
    function withdrawEther() public onlyOwner {
        address self = address(this); // workaround for a possible solidity bug
        uint256 balance = self.balance;
        owner.transfer(balance);
    }
    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/
    /// @dev Lets a contract admin set the URI for the contract-level metadata.
    function setRouter(address _newRouter) external onlyOwner {
        oneInchRouter = _newRouter;
    }
    /// @dev Lets a contract admin set the  zrx exchange address
    function setZRXExchangeAddress(address _newZRXExchangeAddress) external onlyOwner {
        ZRX_EXCHANGE_ADDRESS = _newZRXExchangeAddress;
    }
    /// @dev Lets a contract admin set the  zrx erc20 proxy address
    function setZRXERC20ProxyAddress(address _newZRXERC20ProxyAddress) external onlyOwner {
        ZRX_ERC20_PROXY_ADDRESS = _newZRXERC20ProxyAddress;
    }
    /*///////////////////////////////////////////////////////////////
                        Getter functions
    //////////////////////////////////////////////////////////////*/
    /// @dev Fetches the current oneinch router
    function getRouter() external view returns (address) {
        return oneInchRouter;
    }
    function getFlashloan(
        address flashToken,
        uint256 flashAmount,
        address arbToken,
        bytes calldata zrxData,
        bytes calldata oneInchData
    ) external payable onlyOwner {
        uint256 balanceBefore = IERC20(flashToken).balanceOf(address(this));
        emit FlashTokenBeforeBalance(balanceBefore);
        bytes memory data = abi.encode(flashToken, flashAmount, balanceBefore, arbToken, zrxData, oneInchData);
        flashloan(flashToken, flashAmount, data);
        // execution goes to `callFunction`
        // and this point we have succefully paid the dept
        uint256 balanceAfter = IERC20(flashToken).balanceOf(address(this));
        IERC20(flashToken).transfer(owner, balanceAfter);
    }
    function callFunction(
        address, /* sender */
        Info calldata, /* accountInfo */
        bytes calldata data
    ) external onlyPool {
        (
            address flashToken,
            uint256 flashAmount,
            uint256 balanceBefore,
            address arbToken,
            bytes memory zrxData,
            bytes memory oneInchData
        ) = abi.decode(data, (address, uint256, uint256, address, bytes, bytes));
        uint256 balanceAfter = IERC20(flashToken).balanceOf(address(this));
        emit FlashTokenAfterBalance(balanceAfter);
        require(balanceAfter - balanceBefore == flashAmount, "contract did not get the loan");
        loan = balanceAfter;
        // do whatever you want with the money
        // the dept will be automatically withdrawn from this contract at the end of execution
        _arb(flashToken, arbToken, flashAmount, zrxData, oneInchData);
    }
    function arb(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        bytes memory _0xData,
        bytes memory _oneInchData
    ) public payable onlyOwner {
        _arb(_fromToken, _toToken, _fromAmount, _0xData, _oneInchData);
    }
    function _arb(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        bytes memory _0xData,
        bytes memory _oneInchData
    ) internal {
        // Track original balance
        uint256 _startBalance = IERC20(_fromToken).balanceOf(address(this));
        emit StartBalance(_startBalance);
        // Perform the arb trade
        _trade(_fromToken, _toToken, _fromAmount, _0xData, _oneInchData);
        // Track result balance
        uint256 _endBalance = IERC20(_fromToken).balanceOf(address(this));
        emit EndBalance(_endBalance);
        // Require that arbitrage is profitable
        require(_endBalance > _startBalance, "End balance must exceed start balance.");
    }
    function trade(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        bytes memory _0xData,
        bytes memory _1inchData
    ) public payable onlyOwner {
        _trade(_fromToken, _toToken, _fromAmount, _0xData, _1inchData);
    }
    function _trade(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        bytes memory _0xData,
        bytes memory _1inchData
    ) internal {
        // Track the balance of the token RECEIVED from the trade
        uint256 _beforeBalance = IERC20(_toToken).balanceOf(address(this));
        emit ZRXBeforeDAIBalance(_beforeBalance);
        emit ZRXBeforeWETHBalance(IERC20(_fromToken).balanceOf(address(this)));
        // Swap on 0x: give _fromToken, receive _toToken
        _zrxSwap(_fromToken, _fromAmount, _0xData);
        // Calculate the how much of the token we received
        uint256 _afterBalance = IERC20(_toToken).balanceOf(address(this));
        emit ZRXAfterDAIBalance(_afterBalance);
        emit ZRXAfterWETHBalance(IERC20(_fromToken).balanceOf(address(this)));
        // Read _toToken balance after swap
        uint256 _toAmount = _afterBalance - _beforeBalance;
        // Swap on 1Inch: give _toToken, receive _fromToken
        _oneInchSwap(_toToken, _fromToken, _toAmount, _1inchData);
    }
    function zrxSwap(
        address _from,
        uint256 _amount,
        bytes memory _calldataHexString
    ) public payable onlyOwner {
        _zrxSwap(_from, _amount, _calldataHexString);
    }
    function _zrxSwap(
        address _from,
        uint256 _amount,
        bytes memory _calldataHexString
    ) internal {
        // Approve tokens
        IERC20 _fromIERC20 = IERC20(_from);
        _fromIERC20.approve(ZRX_ERC20_PROXY_ADDRESS, _amount);
        // Swap tokens
        (bool success, ) = address(ZRX_EXCHANGE_ADDRESS).call{ value: msg.value }(_calldataHexString);
        require(success, "SWAP_CALL_FAILED");
        // Reset approval
        _fromIERC20.approve(ZRX_ERC20_PROXY_ADDRESS, 0);
    }
    function oneInchSwap(
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _oneInchCallData
    ) public payable onlyOwner {
        _oneInchSwap(_from, _to, _amount, _oneInchCallData);
    }
    //_oneInchCalldata is a tx data from /swap endpoint of 1inch api
    function _oneInchSwap(
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _oneInchCallData
    ) internal {
        // Setup contracts
        IERC20 _fromIERC20 = IERC20(_from);
        uint256 _beforeBalance = IERC20(_to).balanceOf(address(this));
        emit OneInchBeforeWETHBalance(_beforeBalance);
        emit OneInchBeforeDAIBalance(IERC20(_from).balanceOf(address(this)));
        // Approve tokens
        _fromIERC20.approve(oneInchRouter, _amount);
        // Swap tokens: give _from, get _to
        (bool success, bytes memory _data) = oneInchRouter.call(_oneInchCallData);
        require(success, "1INCH_SWAP_CALL_FAILED");
        uint256 _afterBalance = IERC20(_to).balanceOf(address(this));
        emit OneInchAfterWETHBalance(_afterBalance);
        emit OneInchAfterDAIBalance(IERC20(_from).balanceOf(address(this)));
        // Reset approval
        _fromIERC20.approve(oneInchRouter, 0);
    }
    function getWeth() public payable onlyOwner {
        _getWeth(msg.value);
    }
    function _getWeth(uint256 _amount) internal {
        (bool success, ) = WETH.call{ value: _amount }("");
        require(success, "failed to get weth");
    }
    function approveWeth(uint256 _amount) public onlyOwner {
        _approveWeth(_amount);
    }
    function _approveWeth(uint256 _amount) internal {
        IERC20(WETH).approve(ZRX_STAKING_PROXY, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";

interface ITrading {
    /*///////////////////////////////////////////////////////////////
                            Enums
    //////////////////////////////////////////////////////////////*/
    enum ActionType {
        /// @notice supply tokens
        Deposit,
        /// @notice borrow tokens
        Withdraw,
        /// @notice transfer balance between accounts
        Transfer,
        /// @notice buy an amount of some token (externally)
        Buy,
        /// @notice sell an amount of some token (externally)
        Sell,
        /// @notice trade tokens against another account
        Trade,
        /// @notice liquidate an undercollateralized or expiring account
        Liquidate,
        /// @notice use excess tokens to zero-out a completely negative account
        Vaporize,
        /// @notice send arbitrary data to an address
        Call
    }

    enum AssetDenomination {
        Wei // the amount is denominated in wei
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    /*///////////////////////////////////////////////////////////////
                            Structs
    //////////////////////////////////////////////////////////////*/
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 guaranteedAmount;
        uint256 flags;
        address referrer;
        bytes permit;
    }

    struct Val {
        uint256 value;
    }
    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/
    event StartBalance(uint256 balance);
    event EndBalance(uint256 balance);
    event ZRXBeforeDAIBalance(uint256 balance);
    event ZRXAfterDAIBalance(uint256 balance);
    event ZRXBeforeWETHBalance(uint256 balance);
    event ZRXAfterWETHBalance(uint256 balance);
    event OneInchBeforeDAIBalance(uint256 balance);
    event OneInchAfterDAIBalance(uint256 balance);
    event OneInchBeforeWETHBalance(uint256 balance);
    event OneInchAfterWETHBalance(uint256 balance);
    event FlashTokenBeforeBalance(uint256 balance);
    event FlashTokenAfterBalance(uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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