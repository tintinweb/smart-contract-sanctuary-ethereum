// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract SPACEP is ERC20, Ownable, ERC20Burnable {

    uint256 public constant BURN_FEE_PERCENT = 1;
    uint256 public constant BURN_FEE_PERCENT_MEV = 5;

    address[] public __pairAddresses;

    mapping(address => bool) private __pairs;
    mapping(address => bool) private __taxlessList;
    mapping(address => uint256) private __walletLastTxBlock;

    bool private __tradingEnabled = false;

    event TradingEnabled(bool enabled);
    event TaxLess(address indexed wallet, bool value);
    event AddPair(address indexed router, address indexed pair);

    constructor(address _router) ERC20("SPACEP", "SPACEP") {
        __taxlessList[msg.sender] = true;
        __taxlessList[address(this)] = true;
        __taxlessList[address(0)] = true;

        _mint(msg.sender, 100_000_000_000_000 ether);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        addPair(_router, _uniswapV2Router.WETH());
    }

    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) override internal virtual {
        require(__taxlessList[sender] || __taxlessList[recipient] || __tradingEnabled, "Trade not enabled");
        super._beforeTokenTransfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        // this is to verify if user is selling tokens
        if (!__taxlessList[sender] && !__taxlessList[recipient] && __pairs[recipient]) {
            uint256 burnAmount;
            if (isSecondTxInSameBlock(sender)) {
                burnAmount = amount * BURN_FEE_PERCENT_MEV / 100;  // Calculate fee of the transaction amount for mevs
            } else {
                burnAmount = amount * BURN_FEE_PERCENT / 100;  // Calculate fee of the transaction amount for humans
            }
            uint256 sendAmount = amount - burnAmount;

            _burn(sender, burnAmount);  // Burns the token
            super._transfer(sender, recipient, sendAmount);  // Transfer rest % of the transaction
        } else {
            // user is buying tokens, we store the block number.
            if (!__taxlessList[sender] && !__taxlessList[recipient] && __pairs[sender]) {
                __walletLastTxBlock[recipient] = block.number;
            }
            super._transfer(sender, recipient, amount);
        }
    }
    
    function isSecondTxInSameBlock(address _from) internal view returns(bool) {
        return __walletLastTxBlock[_from] == block.number;
    }

    function enableTrading() external onlyOwner {
        __tradingEnabled = true;
        emit TradingEnabled(true);
    }

    function setIsTaxless(address _address, bool value) external onlyOwner {
        __taxlessList[_address] = value;
        emit TaxLess(_address, value);
    }

    function addPair(address _router, address _token) public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _token);
        __pairAddresses.push(pair);
        __pairs[pair] = true;
        emit AddPair(_router, pair);
    }

    function getPair(uint256 _index) external view returns(address) {
        return __pairAddresses[_index];
    }

    function isTaxLess(
        address _address
    ) external view returns (bool is_tax_less) {
        return __taxlessList[_address];
    }

    function isPair(address _pair) external view returns (bool is_pair) {
        return __pairs[_pair];
    }
}