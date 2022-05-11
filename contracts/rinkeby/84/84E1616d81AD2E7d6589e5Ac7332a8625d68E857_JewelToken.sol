// SPDX-License-Identifier: OTHER
pragma solidity ^0.8.0;

import "./Whitelisted.sol";
import "./interfaces/IGame.sol";
import "./interfaces/ILinkCoordinator.sol";
import "./interfaces/ILinkToken.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";

contract JewelToken is Whitelisted {
    string public name = "Jewel Protocol";
    string public symbol = "JWL";
    uint256 public sypplyCap = 10 ** 24;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    Link private _link;
    Uniswap private _uniswap;
    mapping(uint256 => address) private _randomRequests;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private _pendingYield;
    int256 private _yieldPerUnit;
    mapping(address => int256) private _redeemedYield;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    struct Link {
        uint256 fee;
        uint64 subscriptionId;
        bytes32 keyHash;
        address coordinator;
        address token;
    }

    struct Uniswap {
        address weth;
        address swapRouter;
    }

    constructor(address linkAddress, address linkCoordinator, bytes32 linkKeyHash, address wethAddress, address swapRouterAddress) {
        _link.fee = 0.25 * 10 ** 18;
        _link.coordinator = linkCoordinator;
        _link.token = linkAddress;
        _link.keyHash = linkKeyHash;
        _link.subscriptionId = ILinkCoordinator(_link.coordinator).createSubscription();
        ILinkCoordinator(_link.coordinator).addConsumer(_link.subscriptionId, address(this));
        _uniswap.weth = wethAddress;
        _uniswap.swapRouter = swapRouterAddress;
    }

    receive() external payable {
        if (isWhitelisted[msg.sender]) {
            uint256 yield = msg.value + _pendingYield;
            unchecked {
                _yieldPerUnit += int256(yield / totalSupply);
                _pendingYield = yield % totalSupply;
            }
        } else {
            require(totalSupply + msg.value <= sypplyCap, "Jewel: supply cap exceeded");
            unchecked {
                totalSupply += msg.value;
                balanceOf[msg.sender] += msg.value;
                _redeemedYield[msg.sender] += _yieldPerUnit * int256(msg.value);
            }
            emit Transfer(address(0), msg.sender, msg.value);
        }
    }

    function yieldAllowance(address account) public view returns (int256) {
        int256 allowedYield = _yieldPerUnit * int256(balanceOf[account]);
        return allowedYield - _redeemedYield[account];
    }

    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Jewel: withdrawal amount exceeds balance");
        require(yieldAllowance(msg.sender) >= 0, "Jewel: must forfeit negative dividends first");
        unchecked {
            totalSupply -= amount;
            balanceOf[msg.sender] -= amount;
        }
        payable(msg.sender).transfer(amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function forfeit(uint256 amount) external {
        require(yieldAllowance(msg.sender) <= -int256(amount), "Jewel: forfeit amount exceeds negative yield");
        unchecked {
            _redeemedYield[msg.sender] -= int256(amount);
            balanceOf[msg.sender] -= amount;
            totalSupply -= amount;
        }
        emit Transfer(msg.sender, address(0), amount);
    }

    function payout(uint256 amount, address to) public onlyWhitelisted {
        require(to != address(0), "Jewel: cannot payout to the zero address");
        if (amount < _pendingYield) {
            unchecked {
                _pendingYield -= amount;
            }
        } else {
            uint256 yield = amount - _pendingYield;
            unchecked {
                _yieldPerUnit -= int256(yield / totalSupply) + 1; //TODO: is this correct?
                _pendingYield = totalSupply - (yield % totalSupply);
            }
        }
        payable(to).transfer(amount);
    }

    function withdrawYield(uint256 amount) external {
        require(yieldAllowance(msg.sender) >= int256(amount), "Jewel: withdrawal amount exceeds yield");
        unchecked {
            _redeemedYield[msg.sender] += int256(amount);
        }
        payable(msg.sender).transfer(amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Jewel: cannot transfer to the zero address");
        require(balanceOf[msg.sender] >= amount, "Jewel: transfer amount exceeds balance");
        unchecked {
            balanceOf[msg.sender] -= amount;
            balanceOf[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Jewel: cannot approve the zero address");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(from != address(0), "Jewel: cannot transfer from the zero address");
        require(to != address(0), "Jewel: cannot transfer to the zero address");
        require(allowance[from][msg.sender] >= amount, "Jewel: insufficient allowance");
        require(balanceOf[from] >= amount, "Jewel: transfer amount exceeds balance");
        unchecked {
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
            allowance[from][msg.sender] -= amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function _topUpSubscription() internal {
        uint256 maximumIn = 10 ** 15; //TODO: is this a good way?
        require(address(this).balance > maximumIn, "Jewel: no ETH balance to swap for LINK");
        payout(maximumIn, payable(_uniswap.weth));
        IWETH(_uniswap.weth).approve(_uniswap.swapRouter, maximumIn);
        ISwapRouter.ExactOutputSingleParams memory swapParams = ISwapRouter.ExactOutputSingleParams({
            tokenIn: _uniswap.weth, 
            tokenOut: _link.token, 
            fee: 3000, 
            recipient: address(this), 
            deadline: block.timestamp,
            amountOut: _link.fee,
            amountInMaximum: maximumIn,
            sqrtPriceLimitX96: 0
        });
        uint256 amountIn = ISwapRouter(_uniswap.swapRouter).exactOutputSingle(swapParams);
        uint256 refund = maximumIn - amountIn;
        IWETH(_uniswap.weth).approve(_uniswap.swapRouter, 0);
        IWETH(_uniswap.weth).withdraw(refund);
        ILinkToken(_link.token).transferAndCall(_link.coordinator, _link.fee, abi.encode(_link.subscriptionId));
    }

    function requestRandomWords(uint32 numberOfWords) external onlyWhitelisted returns (uint256)  { 
        _topUpSubscription();
        uint256 requestId = ILinkCoordinator(_link.coordinator).requestRandomWords(_link.keyHash, _link.subscriptionId, 3, 100000, numberOfWords);
        _randomRequests[requestId] = msg.sender;
        return requestId;
    }

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        require(msg.sender == _link.coordinator, "Jewel: only coordinator can fulfill random words request");
        IGame(payable(_randomRequests[requestId])).fulfillRandomWords(requestId, randomWords);
    }
}

// SPDX-License-Identifier: OTHER
pragma solidity ^0.8.0;

abstract contract Whitelisted {
    mapping(address => bool) public isWhitelisted;

    constructor() {
        isWhitelisted[msg.sender] = true;
    }

    function addToWhitelist(address approvedAddress) external onlyWhitelisted {
        isWhitelisted[approvedAddress] = true;
    }

    function _addToWhitelist(address approvedAddress) internal {
        isWhitelisted[approvedAddress] = true;
    }

    function removeFromWhitelist(address revokedAddress) external onlyWhitelisted {
        isWhitelisted[revokedAddress] = false;
    }

    function _removeFromWhitelist(address revokedAddress) internal {
        isWhitelisted[revokedAddress] = false;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "Whitelistable: address is not whitelisted to perform this action");
        _;
    }
}

// SPDX-License-Identifier: OTHER
pragma solidity ^0.8.0;

interface IGame {
    function fulfillRandomWords(uint256, uint256[] memory) external;
}

// SPDX-License-Identifier: OTHER
pragma solidity ^0.8.0;

interface ILinkCoordinator {
    function createSubscription() external returns (uint64);
    function addConsumer(uint64, address) external;
    function requestRandomWords(bytes32, uint64, uint16, uint32, uint32) external returns (uint256);
}

// SPDX-License-Identifier: OTHER
pragma solidity ^0.8.0;

interface ILinkToken {
    function transferAndCall(address, uint256, bytes calldata) external returns (bool);
}

// SPDX-License-Identifier: OTHER
pragma solidity ^0.8.0;

interface ISwapRouter {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    
    function exactOutputSingle(ExactOutputSingleParams calldata) external payable returns (uint256);
}

// SPDX-License-Identifier: OTHER
pragma solidity ^0.8.0;

interface IWETH {
    function approve(address, uint256) external returns (bool);
    function withdraw(uint256) external;
}