/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
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

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract Ownable{
    address private _owner;
    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

interface IUniswapV2Router {

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

  function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

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
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MultiBuy is Ownable {
    using SafeMath for uint256;
    address public SwapAddress;
    address public WETH;
    uint256 public BiGNum = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    mapping(address => bool) public WhiteList;

    fallback() external payable {} //允许合约接收eth

    function Initialize(address _SwapAddress, address _WETH) external onlyOwner {
    SwapAddress = _SwapAddress;
    WETH = _WETH;
    WhiteList[msg.sender] = true;
    }

    function setWhitelist(address[] memory addresses, bool value) public onlyOwner{
        for (uint i = 0; i < addresses.length; i++) {
            WhiteList[addresses[i]] = value;
        }
    }

    function approve_first(address _tokenIn, uint256 _amountIn) external onlyOwner {
        IERC20(_tokenIn).approve(SwapAddress, _amountIn);
    }

    function withdraw_Token(address _tokenIn, uint256 _amountOut) external onlyOwner {
        if(_amountOut == 0){
            IERC20(_tokenIn).transfer(msg.sender, IERC20(_tokenIn).balanceOf(address(this))); //0代表全部提款
        } else {
            IERC20(_tokenIn).transfer(msg.sender, _amountOut);
        }
    }

    function deposit_ETH() payable public {
    }

    function withdraw_ETH(uint256 _amountOut) external onlyOwner {
        if(_amountOut == 0){
            payable(msg.sender).transfer(address(this).balance); //0代表全部提款
        } else {
            payable(msg.sender).transfer(_amountOut);
        }
    }

    function multiBuy(uint256 _multiTimes, uint256[] memory _amountIn, uint256[] memory _amountOutMin, address[] memory path, address[] memory _toWallet) external {
    require(WhiteList[msg.sender], "You can't do this dude.");
    require(_multiTimes >= 1, "Invalide _multiTimes"); // multiTimes代指每个钱包的购买次数，用来应对单次购买限额与持仓限额不同的情况
    require(_amountIn.length == _amountOutMin.length, "Amount setUp wrong!");
    require(_amountIn.length == _toWallet.length, "Amount setUp cannot match wallet amount!");
    for(uint multiTimes = 0; multiTimes < _multiTimes; multiTimes++){
        for(uint walletIndex = 0; walletIndex < _toWallet.length; walletIndex++){
            if (path[0] == WETH) {
                IUniswapV2Router(SwapAddress).swapExactETHForTokens{value: _amountIn[walletIndex]}(_amountOutMin[walletIndex], path, _toWallet[walletIndex], block.timestamp);
            } else {
                IUniswapV2Router(SwapAddress).swapExactTokensForTokens(_amountIn[walletIndex], _amountOutMin[walletIndex], path, _toWallet[walletIndex], block.timestamp);
            }
            }
    }
    }

    function multiBuyExactToken(uint256 _multiTimes, uint256[] memory _amountInMax, uint256[] memory _amountOut, address[] memory path, address[] memory _toWallet) external {
    require(WhiteList[msg.sender], "You can't do this dude.");
    require(_multiTimes >= 1, "Invalide _multiTimes"); // multiTimes代指每个钱包的购买次数，用来应对单次购买限额与持仓限额不同的情况
    require(_amountInMax.length == _amountOut.length, "Amount setUp wrong!");
    require(_amountInMax.length == _toWallet.length, "Amount setUp cannot match wallet amount!");
    for(uint multiTimes = 0; multiTimes < _multiTimes; multiTimes++){
        for(uint walletIndex = 0; walletIndex < _toWallet.length; walletIndex++){
            if (path[0] == WETH) {
                IUniswapV2Router(SwapAddress).swapETHForExactTokens{value: _amountInMax[walletIndex]}(_amountOut[walletIndex], path, _toWallet[walletIndex], block.timestamp);
            } else {
                IUniswapV2Router(SwapAddress).swapTokensForExactTokens(_amountInMax[walletIndex], _amountOut[walletIndex], path, _toWallet[walletIndex], block.timestamp);
            }
            }
    }
    }

        function AVAXmultiBuy(uint256 _multiTimes, uint256[] memory _amountIn, uint256[] memory _amountOutMin, address[] memory path, address[] memory _toWallet) external {
    require(WhiteList[msg.sender], "You can't do this dude.");
    require(_multiTimes >= 1, "Invalide _multiTimes"); // multiTimes代指每个钱包的购买次数，用来应对单次购买限额与持仓限额不同的情况
    require(_amountIn.length == _amountOutMin.length, "Amount setUp wrong!");
    require(_amountIn.length == _toWallet.length, "Amount setUp cannot match wallet amount!");
    for(uint multiTimes = 0; multiTimes < _multiTimes; multiTimes++){
        for(uint walletIndex = 0; walletIndex < _toWallet.length; walletIndex++){
            if (path[0] == WETH) {
                IUniswapV2Router(SwapAddress).swapExactAVAXForTokens{value: _amountIn[walletIndex]}(_amountOutMin[walletIndex], path, _toWallet[walletIndex], block.timestamp);
            } else {
                IUniswapV2Router(SwapAddress).swapExactTokensForTokens(_amountIn[walletIndex], _amountOutMin[walletIndex], path, _toWallet[walletIndex], block.timestamp);
            }
            }
    }
    }

    function AVAXmultiBuyExactToken(uint256 _multiTimes, uint256[] memory _amountInMax, uint256[] memory _amountOut, address[] memory path, address[] memory _toWallet) external {
    require(WhiteList[msg.sender], "You can't do this dude.");
    require(_multiTimes >= 1, "Invalide _multiTimes"); // multiTimes代指每个钱包的购买次数，用来应对单次购买限额与持仓限额不同的情况
    require(_amountInMax.length == _amountOut.length, "Amount setUp wrong!");
    require(_amountInMax.length == _toWallet.length, "Amount setUp cannot match wallet amount!");
    for(uint multiTimes = 0; multiTimes < _multiTimes; multiTimes++){
        for(uint walletIndex = 0; walletIndex < _toWallet.length; walletIndex++){
            if (path[0] == WETH) {
                IUniswapV2Router(SwapAddress).swapAVAXForExactTokens{value: _amountInMax[walletIndex]}(_amountOut[walletIndex], path, _toWallet[walletIndex], block.timestamp);
            } else {
                IUniswapV2Router(SwapAddress).swapTokensForExactTokens(_amountInMax[walletIndex], _amountOut[walletIndex], path, _toWallet[walletIndex], block.timestamp);
            }
            }
    }
    }

}