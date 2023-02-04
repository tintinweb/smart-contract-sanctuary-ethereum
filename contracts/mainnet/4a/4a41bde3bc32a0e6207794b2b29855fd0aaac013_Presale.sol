/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Presale {
    address payable public owner;
    uint256 public maxForsale = 200000000;
    uint256 public totalTokensSold;
    uint256 public totalUSDTRaised;
    uint256 public totalETHRaised;
    uint256 public totalTokenBuyer;
    uint256 public totalTokenClaimed;
    address public tokenAddr = address(0);
    uint256 public currentStep = 0;
    uint256 public timeStage = 0; //0:presale 1:claim
    uint256 public decimalUSDT = 10**6;
    uint256 public decimalToken = 10**18;

    IERC20 public USDTAddr = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); 
    Aggregator public aggregatorInterface =
        Aggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); 

    uint256[10] public token_amount = [
        15e6,
        30e6,
        50e6,
        70e6,
        90e6,
        110e6,
        130e6,
        150e6,
        175e6,
        200e6
    ];
    uint256[10] public token_price = [1, 2, 4, 8, 20, 30, 40, 50, 60, 80];

    mapping(address => uint256) public userBought;
    mapping(address => bool) public hasClaimed;

    event TokensBought(
        address indexed user,
        uint256 indexed tokensBought,
        address indexed purchaseToken,
        uint256 amountPaid,
        uint256 currentStep,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function totalFundRaised() public view returns (uint256) {
        return (totalUSDTRaised *
            10**12 +
            (totalETHRaised * getLatestPrice()) /
            decimalToken);
    }

    function setOwner(address _addr) public onlyOwner {
        owner = payable(_addr);
    }

    function setTokenAddr(address _addr) external onlyOwner {
        require(_addr != address(0));
        tokenAddr = _addr;
    }

    function setTimeStage(uint256 _stage) external onlyOwner {
        require(_stage < 2 && timeStage < _stage);
        if (_stage == 1)
            require(
                tokenAddr != address(0) &&
                    IERC20(tokenAddr).balanceOf(address(this)) >=
                    totalTokensSold * decimalToken
            );

        timeStage = _stage;
    }

    /**
     * @dev To calculate the payment in USD for the amount of tokens.
     * @param _amount amount of tokens
     */
    function calculatePaymentUSDT(uint256 _amount)
        public
        view
        returns (uint256, uint256)
    {
        require(
            _amount >= 1000 && _amount <= (maxForsale - totalTokensSold),
            "Amount is wrong"
        );

        uint256 USDTAmount = 0;
        uint256 nStep = currentStep;

        if (_amount + totalTokensSold >= token_amount[currentStep]) {
            uint256 amt = 0;

            for (uint256 i = currentStep; i < 10; i++) {
                if (i == 9 || _amount + totalTokensSold < token_amount[i]) {
                    nStep = i;
                    break;
                }
            }

            for (uint256 i = currentStep; i <= nStep; i++) {
                if (i == currentStep) {
                    amt = token_amount[i] - totalTokensSold;
                } else if (i < nStep) {
                    amt = token_amount[i] - token_amount[i - 1];
                } else if (i == nStep) {
                    amt = _amount + totalTokensSold - token_amount[i - 1];
                }
                USDTAmount += ((amt * token_price[i]) * decimalUSDT) / 100;
            }
        } else {
            USDTAmount = ((_amount * token_price[nStep]) * decimalUSDT) / 100;
        }

        return (USDTAmount, nStep);
    }

    function calculatePaymentETH(uint256 _amount)
        public
        view
        returns (uint256, uint256)
    {
        uint256 nStep;
        uint256 usdtAmt;

        (usdtAmt, nStep) = calculatePaymentUSDT(_amount);
        uint256 ETHAmount = (usdtAmt * 10**30) / getLatestPrice();

        return (ETHAmount, nStep);
    }

    /**
     * @dev To buy MXDX token with USDT
     * @param amount amount of tokens to buy
     */

    function buyWithUSDT(uint256 amount) external returns (bool) {
        require(timeStage == 0, "Invalid time for buying");

        uint256 usdtAmt;

        (usdtAmt, currentStep) = calculatePaymentUSDT(amount);

        uint256 ourAllowance = IERC20(USDTAddr).allowance(
            msg.sender,
            address(this)
        );
        require(usdtAmt <= ourAllowance, "Make sure to add enough allowance");
        (bool success, ) = address(USDTAddr).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                owner,
                usdtAmt
            )
        );
        require(success, "Token payment failed");

        if (userBought[msg.sender] == 0) totalTokenBuyer += 1;
        userBought[msg.sender] += amount;
        totalTokensSold += amount;
        totalUSDTRaised += usdtAmt;

        emit TokensBought(
            msg.sender,
            amount,
            address(USDTAddr),
            usdtAmt,
            currentStep,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev To buy in presale by ETH
     * @param amount amount of tokens to buy
     */

    function buyWithETH(uint256 amount) external payable returns (bool) {
        require(timeStage == 0, "Invalid time for buying");

        uint256 ethAmt;

        (ethAmt, currentStep) = calculatePaymentETH(amount);
        require(msg.value > (ethAmt * 98) / 100, "Less payment");

        if (userBought[msg.sender] == 0) totalTokenBuyer += 1;
        userBought[msg.sender] += amount;
        totalTokensSold += amount;
        totalETHRaised += msg.value;
        sendValue(payable(owner), msg.value);

        emit TokensBought(
            msg.sender,
            amount,
            address(0),
            ethAmt,
            currentStep,
            block.timestamp
        );
        return true;
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10**10));
        return uint256(price);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev To claim tokens after presale end
     */

    function claim() external returns (bool) {
        require(timeStage == 1, "Claim has not started yet");
        require(!hasClaimed[msg.sender], "Already claimed");
        require(userBought[msg.sender] > 0, "Nothing to claim");

        hasClaimed[msg.sender] = true;
        totalTokenClaimed += userBought[msg.sender];
        uint256 amount = userBought[msg.sender] * decimalToken;
        bool success = IERC20(tokenAddr).transfer(msg.sender, amount);
        require(success, "Token transfer failed");

        emit TokensClaimed(msg.sender, amount, block.timestamp);
        return true;
    }
}