pragma solidity ^0.8.0;

interface IQuickswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IQuickswapV2Router02 {
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPegSwap { 
  function swap(
    uint256 amount,
    address source,
    address target
  )
    external;
}

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
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
            if (returndata.length > 0) {
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

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

interface IDice4Utopia {
    function deposit(address user, uint256 matic) external payable;
}

pragma solidity ^0.8.0;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}

contract Ido is Ownable, NoDelegateCall {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address public alphaACreed;
    address public Dice4Utopia_com;
    address public DAOAddress;

    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address public constant Mapper_LINK_TOKEN = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39; 
    address public constant PegSwap = 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;
    address public constant LINK_TOKEN = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1; 

    address public constant QuickswapFactory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    address public constant QuickswapRouter02 = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    uint256 public minAmount = 10e18;
    uint256 public maxAmount = 10000e18;
    uint256 public salePrice = 1e18;
    uint256 public startTimestamp = block.timestamp + 7 days;
    uint256 public endTimestamp = block.timestamp + 183 days;
    uint256 public toTalAmount = 600_000e18;
    uint256 public sellAmount;

    uint256 public Leap_Of_Faith = 1000;
    uint256 public rechargeLinkMaxMatic = 140e18;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    bool public saleStarted = false;

    mapping(address => bool) public boughtACreed;
    mapping(address => bool) public whiteListed;

    event DaoAddressChanged(address msgSender, address alphaDaoAddress);
    event addLiquidity(
        address msgSender,
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor() Ownable() {
        _status = _NOT_ENTERED;
    }

    uint256 onlyOnce = 0;

    function initOnce(address alphaACreed_, address Dice4Utopia_com_)
        external
        onlyOwner
    {
        require(onlyOnce == 0);
        alphaACreed = alphaACreed_;
        Dice4Utopia_com = Dice4Utopia_com_;
        onlyOnce = 1;
    }

    function initialize(
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _toTalAmount,
        uint256 _salePrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external onlyOwner returns (bool) {
        require(_salePrice >= salePrice, "Fair For Dao2Utopia.com !");
        salePrice = _salePrice;

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        minAmount = _minAmount;

        maxAmount = _maxAmount;

        toTalAmount = _toTalAmount;

        saleStarted = true;
        return true;
    }

    function setStart() external onlyOwner returns (bool) {
        saleStarted = !saleStarted;
        return saleStarted;
    }

    function setEndTimestamp(uint256 _endTimestamp)
        external
        onlyOwner
        returns (bool)
    {
        endTimestamp = _endTimestamp;
        return true;
    }

    function getEndTimestamp() external view returns (uint256) {
        return endTimestamp;
    }

    function isTimeEnd() external view returns (bool) {
        return block.timestamp > endTimestamp;
    }

    function getFullReleaseTimestamp() external view returns (uint256) {
        return endTimestamp + 182 days;
    }

    function setLeap_Of_Faith(uint256 leap_of_faith) external returns (bool) {
        require(leap_of_faith >= 100, "At least 100 times");
        require(
            msg.sender == DAOAddress && DAOAddress != address(0),
            "Only DAOAddress can be called"
        );

        Leap_Of_Faith = leap_of_faith;
        return true;
    }

    function setRechargeLinkMaxMatic(uint256 linkMaxAmount) external onlyOwner { 
        rechargeLinkMaxMatic = linkMaxAmount;
    }

    function sermon(uint256 _val)
        external
        nonReentrant
        noDelegateCall
        returns (bool)
    {
        address user = msg.sender;
        require(user == tx.origin, "Please be EOA account");

        uint256 sermonAmount = _val.div(Leap_Of_Faith);

        // IDice4Utopia(Dice4Utopia_com).deposit{value: sermonAmount}(user);
        IDice4Utopia(Dice4Utopia_com).deposit{value: 0}(user, sermonAmount);

        uint256 realAmount = _calculateSaleQuote(sermonAmount);

        IERC20(alphaACreed).safeTransfer(msg.sender, realAmount);
        return true;
    }

    function purchaseaACreed(uint256 _val, address _user)
        external
        nonReentrant
        noDelegateCall
        returns (bool)
    {
        require(
            msg.sender == tx.origin && msg.sender == _user,
            "Please be EOA account"
        );

        // IDice4Utopia(Dice4Utopia_com).deposit{value: _val.div(2)}(_user);
        IDice4Utopia(Dice4Utopia_com).deposit{value: 0}(_user, _val.div(2));

        uint256 _purchaseAmount = whiteListed[_user] == true
            ? _calculateSaleQuote(_val).mul(103).div(100)
            : _calculateSaleQuote(_val);

        IERC20(alphaACreed).safeTransfer(msg.sender, _purchaseAmount);
        return true;
    }

    function _calculateSaleQuote(uint256 paymentAmount_)
        internal
        view
        returns (uint256)
    {
        return uint256(1e18).mul(paymentAmount_).div(salePrice);
    }

    function calculateSaleQuote(uint256 paymentAmount_)
        external
        view
        returns (uint256)
    {
        return _calculateSaleQuote(paymentAmount_);
    }

    function withdrawErc20(
        address _erc20,
        address _to,
        uint256 _val
    ) external returns (bool) {
        /// One year is given after IDO ends to access governance system,
        /// so that Dice4Utopia_com can generate enough income to distribute to early investors.
        require(
            block.timestamp > endTimestamp + 182 days,
            "The company's products generate revenue"
        );
        require(
            msg.sender == DAOAddress && DAOAddress != address(0),
            "Only DAOAddress can be called"
        );
        IERC20(_erc20).safeTransfer(_to, _val);
        return true;
    }

    function withdrawMatic(address payable _to, uint256 _val)
        external
        returns (bool)
    {
        /// One year is given after IDO ends to access governance system,
        /// so that Dice4Utopia_com can generate enough income to distribute to early investors.
        require(
            block.timestamp > endTimestamp + 182 days,
            "The company's products generate revenue"
        );
        require(
            msg.sender == DAOAddress && DAOAddress != address(0),
            "Only DAOAddress can be called"
        );
        _to.transfer(_val);
        return true;
    }

    function setDAOAddress(address _alphaDaoAddress) external onlyOwner {
        require(
            _alphaDaoAddress.isContract(),
            "setDAOAddress: _alphaDaoAddress must be a DAO contract"
        );
        emit DaoAddressChanged(msg.sender, _alphaDaoAddress);
        DAOAddress = _alphaDaoAddress;
    }

    function whiteListBuyers(address[] memory _buyers)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 i; i < _buyers.length; i++) {
            whiteListed[_buyers[i]] = true;
        }
        return true;
    }

    // function addLiquidityETH(
    //     address token,
    //     uint256 amountTokenDesired,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function addLiquidityByAnyOne()
        external
        payable
        nonReentrant
        noDelegateCall
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        require(
            block.timestamp > endTimestamp || sellAmount >= toTalAmount,
            "IDO is not over"
        );
        require(msg.sender == tx.origin, "Please be EOA account");
        // Half to add liquidity, half to new assassins
        uint256 _AssassinCreed_ = IERC20(alphaACreed)
            .balanceOf(address(this))
            .div(2);
        uint256 _Matic_ = address(this).balance;
        require(_Matic_ > 0, "Matic balance equal zero");
        require(_AssassinCreed_ > 0, "ACreed balance equal zero");
        (uint256 ACreed, uint256 Matic) = _AssassinCreed_ >= _Matic_
            ? (_Matic_, _Matic_)
            : (_AssassinCreed_, _AssassinCreed_);

        IERC20(alphaACreed).approve(QuickswapRouter02, ACreed);

        (amountToken, amountETH, liquidity) = IQuickswapV2Router02(
            QuickswapRouter02
        ).addLiquidityETH{value: Matic}(
            alphaACreed,
            ACreed,
            0,
            0,
            address(this),
            block.timestamp + 693676800 // 1991-12-26
        );
        endTimestamp = endTimestamp + 365 days;
        emit addLiquidity(msg.sender, amountToken, amountETH, liquidity);
    }

    // function removeLiquidityETH(
    //     address token,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityETHByDAO(uint256 liquidity, address payable to)
        external
        nonReentrant
        returns (uint256 amountToken, uint256 amountETH)
    {
        require(
            msg.sender == DAOAddress && DAOAddress != address(0),
            "Only DAOAddress can be called"
        );
        address pair = getThePair();
        uint256 lp = IERC20(pair).balanceOf(address(this));
        require(liquidity <= lp, "liquidity greater than lp");
        IERC20(pair).approve(QuickswapRouter02, lp); // type(uint256).max

        (amountToken, amountETH) = IQuickswapV2Router02(QuickswapRouter02)
            .removeLiquidityETH(
                alphaACreed,
                liquidity,
                0,
                0,
                to,
                block.timestamp + 693676800 // 1991-12-26
            );
    }

    function getLp() external view returns (uint256 lp) {
        lp = IERC20(getThePair()).balanceOf(address(this));
    }

    function getThePair() public view returns (address) {
        return
            IQuickswapV2Factory(QuickswapFactory).getPair(alphaACreed, WMATIC);
    }

    function getACreedPrice_USDC() external view returns (uint256[] memory) {
        address[] memory path = new address[](3);
        path[0] = alphaACreed;
        path[1] = WMATIC;
        path[2] = USDC;
        uint256[] memory amounts = IQuickswapV2Router02(QuickswapRouter02)
            .getAmountsOut(1e18, path);
        return amounts;
    }

    // function swapETHForExactTokens(
    //     uint256 amountOut,
    //     address[] calldata path,
    //     address to,
    //     uint256 deadline
    // ) external payable returns (uint256[] memory amounts);
    function rechargeChainLinkByAnyOne()
        external
        nonReentrant
        noDelegateCall
    {
        require(msg.sender == tx.origin, "rechargeChainLinkByAnyOne::Please be EOA account");

        uint256 Dice4Utopia_ChainLink = IERC20(LINK_TOKEN).balanceOf(Dice4Utopia_com);
        require(Dice4Utopia_ChainLink <= 10e18, "rechargeChainLinkByAnyOne::The ChainLink token balance of Dice4Utopia_com is sufficient");
        address[] memory path = new address[](2);
        path[0] = WMATIC;
        path[1] = Mapper_LINK_TOKEN;

        uint256[] memory amounts = IQuickswapV2Router02(
            QuickswapRouter02
        ).swapETHForExactTokens{value: rechargeLinkMaxMatic}(
            10e18,
            path,
            address(this),
            block.timestamp + 693676800 // 1991-12-26
        );
        require(amounts.length == 2,"rechargeChainLinkByAnyOne::ERROR");
        IERC20(Mapper_LINK_TOKEN).approve(PegSwap, amounts[1]);

        IPegSwap(PegSwap).swap(amounts[1], Mapper_LINK_TOKEN, LINK_TOKEN);

        IERC20(LINK_TOKEN).transfer(Dice4Utopia_com, amounts[1]);
    }


    function balanceAddress(address _address_) external view returns (uint256) {
        return address(_address_).balance;
    }

    fallback() external payable {}

    receive() external payable {}
}