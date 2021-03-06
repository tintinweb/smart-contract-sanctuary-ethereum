/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapRouter {
    function factory() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

interface IUSD {
    function owner() external view returns (address);

    function burn(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}

interface IDepositUSD {
    function withdrawToken(
        address token_,
        address to_,
        uint256 amount_
    ) external;
}

contract UsdMinter {
    address public usdTokenAddress; // usd token address
    address public depositAddress; // ??????????????????

    // address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // uniswapRouter
    // address public usdtAddress = 0x55d398326f99059fF775485246999027B3197955; // usdt
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // uniswapRouter
    address public usdtAddress = 0x99924AA7BBc915Cb2BEE65d72343734b370a06f1; // usdt

    address public tokenAddress; // token
    address public pairAddress; // token/usdt pair address

    uint256 public hourLimitTime; // ???????????????????????????
    uint256 public dayLimitTime; // ?????????????????????
    uint256 public hourMintLimitAmount; // ???????????????????????????usd??????
    uint256 public dayMintLimitAmount; // ????????????????????????usd??????
    uint256 public hourBurnLimitAmount; // ???????????????????????????usd??????
    uint256 public dayBurnLimitAmount; // ????????????????????????usd??????

    uint256 public maxMintLimit = 5; // ??????????????????????????? LP 0.5%
    uint256 public maxBurnLimit = 5; // ??????????????????????????? LP 0.5%

    uint256 public hourMintLimit = 1000 * 1e6; // ????????????????????? ?????????
    uint256 public hourBurnLimit = 1000 * 1e6; // ?????????????????????
    uint256 public dayMintLimit = 10000 * 1e6; // ??????????????????
    uint256 public dayBurnLimit = 10000 * 1e6; // ??????????????????

    constructor(
        address token_,
        address usd_,
        address deposit_
    ) {
        pairAddress = IUniswapFactory(IUniswapRouter(routerAddress).factory())
            .getPair(tokenAddress, usdtAddress);

        usdTokenAddress = usd_;
        tokenAddress = token_;
        depositAddress = deposit_;
    }

    modifier onlyOwner() {
        require(
            msg.sender == IUSD(usdTokenAddress).owner(),
            "Only owner can set limit"
        );
        _;
    }

    function setMaxLimit(uint256 maxMintLimit_, uint256 maxBurnLimit_)
        external
        onlyOwner
        returns (bool)
    {
        maxMintLimit = maxMintLimit_;
        maxBurnLimit = maxBurnLimit_;
        return true;
    }

    function setLimit(
        uint256 hourMintLimit_,
        uint256 hourBurnLimit_,
        uint256 dayMintLimit_,
        uint256 dayBurnLimit_
    ) external onlyOwner returns (bool) {
        hourMintLimit = hourMintLimit_;
        hourBurnLimit = hourBurnLimit_;
        dayMintLimit = dayMintLimit_;
        dayBurnLimit = dayBurnLimit_;
        return true;
    }

    function mintUsd(uint256 tokenAmount) public {
        //???????????????????????????????????????1%
        uint256 tokenLP = IERC20(tokenAddress).balanceOf(pairAddress);
        uint256 maxAmount = (tokenLP * maxMintLimit) / 1000;
        require(tokenAmount <= maxAmount, "amount max limit error");

        uint256 beforeBalance = IERC20(tokenAddress).balanceOf(address(this));

        //????????????
        TransferHelper.safeTransferFrom(
            tokenAddress,
            msg.sender,
            depositAddress, //??????????????????
            tokenAmount
        );

        uint256 afterBalance = IERC20(tokenAddress).balanceOf(address(this));
        //?????????????????????(?????????fee???Token)
        uint256 amount = afterBalance - beforeBalance;
        require(amount > 0, "amount error");

        uint256 usdAmount = getSwapPrice(amount, tokenAddress, usdtAddress);
        require(usdAmount > 0, "usd amount error");

        // ????????????????????? 1%
        uint256 _epoch_hour = block.timestamp / 3600;
        if (_epoch_hour > hourLimitTime) {
            hourLimitTime = _epoch_hour;
            hourMintLimitAmount = 0;
        }

        require(
            usdAmount + hourMintLimitAmount <= hourMintLimit,
            "hour mint limit error"
        );
        hourMintLimitAmount = hourMintLimitAmount + usdAmount;

        // ?????????????????? 2%
        uint256 _epoch_day = block.timestamp / 86400;
        if (_epoch_day > dayLimitTime) {
            dayLimitTime = _epoch_day;
            dayMintLimitAmount = 0;
        }
        require(
            usdAmount + dayMintLimitAmount <= dayMintLimit,
            "day mint limit error"
        );
        dayMintLimitAmount = dayMintLimitAmount + usdAmount;

        IUSD(usdTokenAddress).mint(msg.sender, usdAmount);
    }

    // usd=>token
    function burnUsd(uint256 usdAmount) public {
        uint256 tokenAmount = getSwapPrice(
            usdAmount,
            usdTokenAddress,
            tokenAddress
        );
        require(tokenAmount > 0, "token amount error");
        require(tokenAmount <= IERC20(usdtAddress).balanceOf(address(this)));

        //???????????????????????????????????????1%
        uint256 tokenLP = IERC20(usdtAddress).balanceOf(pairAddress);
        uint256 maxAmount = (tokenLP * maxBurnLimit) / 1000;
        require(usdAmount <= maxAmount, "amount max limit error");

        // ????????????????????? 1%
        uint256 _epoch_hour = block.timestamp / 3600;
        if (_epoch_hour > hourLimitTime) {
            hourLimitTime = _epoch_hour;
            hourBurnLimitAmount = 0;
        }
        require(
            usdAmount + hourBurnLimitAmount <= hourBurnLimit,
            "hour burn limit error"
        );
        hourBurnLimitAmount = hourBurnLimitAmount + usdAmount;

        // ?????????????????? 2%
        uint256 _epoch_day = block.timestamp / 86400;
        if (_epoch_day > dayLimitTime) {
            dayLimitTime = _epoch_day;
            dayBurnLimitAmount = 0;
        }
        require(
            usdAmount + dayBurnLimitAmount <= dayBurnLimit,
            "day burn limit error"
        );
        dayBurnLimitAmount = dayBurnLimitAmount + usdAmount;

        IUSD(usdTokenAddress).burn(msg.sender, usdAmount);
        IDepositUSD(depositAddress).withdrawToken(
            tokenAddress,
            msg.sender,
            tokenAmount
        );
    }

    // ??????????????????
    function getSwapPrice(
        uint256 amount,
        address tokenA,
        address tokenB
    ) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uint256[] memory amounts = IUniswapRouter(routerAddress).getAmountsOut(
            amount,
            path
        );
        return amounts[1];
    }
}