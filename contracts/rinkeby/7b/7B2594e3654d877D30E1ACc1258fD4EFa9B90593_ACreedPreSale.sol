/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IQuickswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256 amountETH);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    // function factory() external pure returns (address);
    // function WETH() external pure returns (address);
    // function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    // function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    // function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    // function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
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
    function deposit(address user) external payable;
}

contract ACreedPreSale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address public alphaACreed;
    address public Dice4Utopia_com;
    address public DAOAddress;

    address public WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public QuickswapFactory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    address public QuickswapRouter02 = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    uint256 public minAmount = 10e18;
    uint256 public maxAmount = 1000e18;
    uint256 public salePrice = 1e18;
    uint256 public startTimestamp = block.timestamp + 60 days;
    uint256 public endTimestamp = block.timestamp + 183 days;
    uint256 public toTalAmount = 500_000e18;
    uint256 public sellAmount;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    bool public saleStarted = false;

    mapping(address => bool) public boughtACreed;
    mapping(address => bool) public whiteListed;

    event DaoAddressChanged(address msgSender, address alphaDaoAddress);

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
    function initOnce(address alphaACreed_, address Dice4Utopia_com_) external onlyOwner { 
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

    function getEndTimestamp() external view returns(uint256) { 
      return endTimestamp;
    }

    function purchaseaACreed(uint256 _val, address _user)
        external
        payable
        nonReentrant
        returns (bool)
    {   
        require(msg.value == _val, "input is not equal to sent value");
        require(_val >= minAmount, "Below minimum allocation");
        require(_val <= maxAmount, "More than allocation");
        sellAmount = sellAmount.add(_val);
        require(
            sellAmount <= toTalAmount,
            "The amount entered exceeds Fundraise Goal"
        );
        require(saleStarted == true, "Not started");
        require(boughtACreed[_user] == false, "Already participated");
        require(startTimestamp < block.timestamp, "Not started yet");

        boughtACreed[_user] = true;

        require(whiteListed[_user] == true, "Not whitelisted");
        require(block.timestamp < endTimestamp, "Sale over");

        IDice4Utopia(Dice4Utopia_com).deposit{value: _val.div(2)}(_user);

        uint256 _purchaseAmount = _calculateSaleQuote(_val);
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
      require(block.timestamp > endTimestamp + 182 days, "The company's products generate revenue");
      require(
          msg.sender == DAOAddress && DAOAddress != address(0), 
        "Only DAOAddress can be called"
        );
        IERC20(_erc20).safeTransfer(_to, _val);
        return true;
    }

    function withdrawMatic(
        address payable _to,
        uint256 _val
    ) external returns (bool) {
      /// One year is given after IDO ends to access governance system, 
      /// so that Dice4Utopia_com can generate enough income to distribute to early investors.
      require(block.timestamp > endTimestamp + 182 days, "The company's products generate revenue");
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
    function addLiquidityByAnyOne() external payable returns(uint256 amountToken, uint256 amountETH, uint256 liquidity){ 
        require(block.timestamp > endTimestamp || sellAmount == toTalAmount, "IDO is not over");

          uint256 _AssassinCreed_ = IERC20(alphaACreed).balanceOf(address(this));
          uint256 _Matic_ = address(this).balance;
        (uint256 ACreed,uint256 Matic) = _AssassinCreed_ >= _Matic_ ? (_Matic_,_Matic_) : (_AssassinCreed_,_AssassinCreed_); 

        IERC20(alphaACreed).approve(QuickswapRouter02, type(uint256).max);

        ( amountToken, amountETH, liquidity) = 
        IQuickswapV2Router02(QuickswapRouter02).addLiquidityETH{value: Matic}(
          alphaACreed, ACreed, 0, 0, address(this), block.timestamp+693676800  // 1991-12-26
        );
    }

    // function removeLiquidityETH(
    //     address token,
    //     uint256 liquidity,
    //     uint256 amountTokenMin,
    //     uint256 amountETHMin,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityETHByDAO(uint256 liquidity, address payable to) external returns(uint256 amountToken, uint256 amountETH) { 
        require(msg.sender == DAOAddress && DAOAddress != address(0), "Only DAOAddress can be called");
        IERC20(alphaACreed).approve(QuickswapRouter02, type(uint256).max);

        ( amountToken, amountETH) = IQuickswapV2Router02(QuickswapRouter02).removeLiquidityETH(
          alphaACreed, liquidity, 0, 0, to, block.timestamp+693676800  // 1991-12-26
          );
    }


    function getThePair() external view returns(address) { 
      return IQuickswapV2Factory(QuickswapFactory).getPair(alphaACreed, WMATIC);
    }

    function getACreedPrice_USDC() external view returns(uint256[] memory) { 
        address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        address[] memory path = new address[](3);
        path[0] = alphaACreed;
        path[1] = WMATIC;
        path[2] = USDC;
        uint256[] memory amounts = IQuickswapV2Router02(QuickswapRouter02).getAmountsOut(1e18,  path);
        return amounts;
    } 

    fallback() external payable {}
    receive() external payable {}

}