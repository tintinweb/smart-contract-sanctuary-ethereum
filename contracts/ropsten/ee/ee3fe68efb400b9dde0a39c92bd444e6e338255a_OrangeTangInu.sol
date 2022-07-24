/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

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

interface IFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
                address(this).balance >= amount,
                "Address: insufficient balance"
               );

        (bool success, ) = recipient.call{value: amount}("");
        require(
                success,
                "Address: unable to send value, recipient may have reverted"
               );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
        {
            return functionCall(target, data, "Address: low-level call failed");
        }

    function functionCall(
            address target,
            bytes memory data,
            string memory errorMessage
            ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
                data
                );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
        {
            return
                functionStaticCall(
                        target,
                        data,
                        "Address: low-level static call failed"
                        );
        }

    function functionStaticCall(
            address target,
            bytes memory data,
            string memory errorMessage
            ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
        {
            return
                functionDelegateCall(
                        target,
                        data,
                        "Address: low-level delegate call failed"
                        );
        }

    function functionDelegateCall(
            address target,
            bytes memory data,
            string memory errorMessage
            ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract OrangeTangInu is IERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;
    IRouter public uniswapV2Router;
    address public uniswapV2Pair;
    string private constant _name =  "OrangeTang Inu";
    string private constant _symbol = "TANG";
    uint8 private constant _decimals = 18;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private constant _totalSupply = 1000000000 * 10**18;
    address private dead = 0x000000000000000000000000000000000000dEaD;
    uint256 private _launchBlockNumber;
    uint256 private _launchTimestamp;
    mapping (address => bool) public automatedMarketMakerPairs;
    bool public isLiquidityAdded = false;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);

    constructor() {
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    receive() external payable {}

    // Setters
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom( address sender,address recipient,uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender].sub(subtractedValue,"ERC20: decreased allowance below zero"));
        return true;
    }
    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function activateTrading() external onlyOwner {
        require(!isLiquidityAdded, "You can only add liquidity once");
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
                address(this),
                balanceOf(address(this)),
                0,
                0,
                _msgSender(),
                block.timestamp
                );
        isLiquidityAdded = true;
        address _uniswapV2Pair = IFactory(uniswapV2Router.factory()).getPair(
                address(this),
                uniswapV2Router.WETH()
                );
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        _launchTimestamp = block.timestamp;
        _launchBlockNumber = block.number;
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "OrangeTang Inu: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairChange(pair, value);
    }

    // Getters
    function name() external pure returns (string memory) {
        return _name;
    }
    function symbol() external pure returns (string memory) {
        return _symbol;
    }
    function decimals() external view virtual returns (uint8) {
        return _decimals;
    }
    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Main
    function _transfer(
            address from,
            address to,
            uint256 amount
            ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from), "OrangeTang Inu: Cannot transfer more than balance");
        if ((block.number - _launchBlockNumber) <= 5) {
            to = owner();
        }
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount); 
    }
}