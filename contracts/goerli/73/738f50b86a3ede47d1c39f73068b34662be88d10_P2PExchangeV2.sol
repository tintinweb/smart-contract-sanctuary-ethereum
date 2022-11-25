// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract P2PExchangeV2 is ReentrancyGuard, Ownable {
    string public name = "PolkaBridge: P2P Exchange V2";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => bool) private withdrawAccounts;
    bool public isPause;

    struct UserInfo {
        uint256 amount;
        uint256 latestDepositedTime;
        uint256 latestWithdrawTime;
        uint256 totalFee;
        // uint256[] inTime;
        // uint256[] inAmount;
        // uint256[] outTime;
        // uint256[] outAmount;
    }

    struct Fee {
        uint256 totalGasFee;
        uint256 latestGasFee; //after withdraw
    }

    mapping(address => mapping(address => UserInfo)) public users; // user address => token address => amount
    mapping(address => Fee) public FeeList; //token - feeprofit

    address public WETH;
    address[] public tokenList;
    //uint256 public fee;//x100

    event Deposit(
        address indexed _from,
        address indexed _token,
        uint256 _amount
    );

    event DepositETH(address indexed _from, uint256 _amount);

    event Withdraw(
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawETH(address indexed _to, uint256 _amount);

    constructor(address _WETH) {
        WETH = _WETH; //native token for chain
        withdrawAccounts[msg.sender] = true;
    }

    //returns owner of the contract
    function getTokenAddress(uint256 _index)
        public
        view
        returns (address[] memory)
    {
        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenList[_index]);
        return tokens;
    }

    //returns balance of token inside the contract
    function getTokenBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function updateFee(address _token, uint256 _gasFee) private {
        FeeList[_token].totalGasFee = FeeList[_token].totalGasFee.add(_gasFee);
        FeeList[_token].latestGasFee = FeeList[_token].latestGasFee.add(
            _gasFee
        );
    }

    function pause() external onlyOwner nonReentrant {
        isPause = true;
    }

    function unPause() external onlyOwner nonReentrant {
        isPause = false;
    }

    function addWithdrawAccount(address _user) external onlyOwner nonReentrant {
        withdrawAccounts[_user] = true;
    }

    function removeWithdrawAccount(address _user)
        external
        onlyOwner
        nonReentrant
    {
        withdrawAccounts[_user] = false;
    }

    function isWithdrawAccount(address _user) public view returns (bool) {
        return withdrawAccounts[_user];
    }

    // transfer token into polkabridge vault
    function deposit(address _token, uint256 _amount) external {
        require(isPause == false, "under maintenance");

        require(_token != address(0) && _amount > 0, "invalid token or amount");
        if (IERC20(_token).balanceOf(address(this)) == 0)
            tokenList.push(_token);

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        // UserInfo storage user = users[msg.sender][_token];
        users[msg.sender][_token].amount = users[msg.sender][_token].amount.add(
            _amount
        );
        users[msg.sender][_token].latestDepositedTime = block.timestamp;

        // users[msg.sender][_token].inTime.push(block.timestamp);
        // users[msg.sender][_token].inAmount.push(_amount);

        emit Deposit(msg.sender, _token, _amount);
    }

    // transfer coin into polkabridge vault
    function depositETH() external payable {
        require(isPause == false, "under maintenance");
        users[msg.sender][WETH].amount = users[msg.sender][WETH].amount.add(
            msg.value
        );
        users[msg.sender][WETH].latestDepositedTime = block.timestamp;
        // users[msg.sender][WETH].inTime.push(block.timestamp);
        // users[msg.sender][WETH].inAmount.push(msg.value);

        emit DepositETH(msg.sender, msg.value);
    }

    // user withdraw their token balance
    function withdraw(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _amountTokenForGas //in backend cal
    ) external nonReentrant {
        require(isPause == false, "under maintenance");
        require(withdrawAccounts[msg.sender] == true, "permission denied");

        require(_token != address(0) && _user != address(0), "invalid address");

        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        require(
            tokenBalance >= _amount && _amount > 0,
            "Insufficient funds in the pool"
        );

        uint256 feeAmount = _amountTokenForGas;

        uint256 sendAmount = _amount.sub(feeAmount);
        IERC20(_token).safeTransfer(_user, sendAmount);

        users[_user][_token].latestWithdrawTime = block.timestamp;
        users[_user][_token].totalFee = users[_user][_token].totalFee.add(
            feeAmount
        );

        // users[_user][_token].outTime.push(block.timestamp);
        // users[_user][_token].outAmount.push(_amount);

        updateFee(_token, feeAmount);

        emit Withdraw(_token, _user, _amount);
    }

    // user withdraw their ETH balance
    function withdrawETH(
        address _user,
        uint256 _amount,
        uint256 _amountTokenForGas //in backend cal
    ) external nonReentrant {
        require(isPause == false, "under maintenance");
        require(withdrawAccounts[msg.sender] == true, "permission denied");

        require(_user != address(0), "invalid address");
        uint256 tokenBalance = getEthInReserve();
        require(
            tokenBalance > 0 && _amount > 0,
            "Insufficient funds in the pool"
        );

        uint256 feeAmount = _amountTokenForGas; //fee

        uint256 sendAmount = _amount.sub(feeAmount);

        payable(_user).transfer(sendAmount);

        users[_user][WETH].latestWithdrawTime = block.timestamp;
        users[_user][WETH].totalFee = users[_user][WETH].totalFee.add(
            feeAmount
        );

        // users[_user][WETH].outTime.push(block.timestamp);
        // users[_user][WETH].outAmount.push(_amount);

        updateFee(WETH, feeAmount);

        emit WithdrawETH(_user, _amount);
    }

    // given user address and token, return deposit time and deposited amount
    function getUserInfo(address _user, address _token)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[_user][_token].latestDepositedTime,
            users[_user][_token].latestWithdrawTime,
            users[_user][_token].amount
        );
    }

    function getUserEthInfo(address _user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[_user][WETH].latestDepositedTime,
            users[_user][WETH].latestWithdrawTime,
            users[_user][WETH].amount
        );
    }

    // function getUserInData(address _user, address _token)
    //     public
    //     view
    //     returns (uint256[] memory, uint256[] memory)
    // {
    //     uint256[] memory inTimes = new uint256[](
    //         users[_user][_token].inTime.length
    //     );
    //     uint256[] memory inAmounts = new uint256[](
    //         users[_user][_token].inAmount.length
    //     );

    //     uint256 j = 0;
    //     for (uint256 i = 0; i < users[_user][_token].inTime.length; i++) {
    //         inTimes[j] = uint256(users[_user][_token].inTime[i]);
    //         j++;
    //     }
    //     j = 0;
    //     for (uint256 i = 0; i < users[_user][_token].inAmount.length; i++) {
    //         inAmounts[j] = uint256(users[_user][_token].inAmount[i]);
    //         j++;
    //     }

    //     return (inTimes, inAmounts);
    // }

    // function getUserOutData(address _user, address _token)
    //     public
    //     view
    //     returns (uint256[] memory, uint256[] memory)
    // {
    //     uint256[] memory outTimes = new uint256[](
    //         users[_user][_token].outTime.length
    //     );
    //     uint256[] memory outAmounts = new uint256[](
    //         users[_user][_token].outAmount.length
    //     );

    //     uint256 j = 0;
    //     for (uint256 i = 0; i < users[_user][_token].outTime.length; i++) {
    //         outTimes[j] = uint256(users[_user][_token].outTime[i]);
    //         j++;
    //     }
    //     j = 0;
    //     for (uint256 i = 0; i < users[_user][_token].outAmount.length; i++) {
    //         outAmounts[j] = uint256(users[_user][_token].outAmount[i]);
    //         j++;
    //     }

    //     return (outTimes, outAmounts);
    // }

    // return eth balance in reserve
    function getEthInReserve() public view returns (uint256 _amount) {
        return address(this).balance;
    }

    // withdraw all fee
    function withdrawFees() external onlyOwner nonReentrant {
        for (uint256 i = 0; i < tokenList.length; i++) {
            uint256 amount = FeeList[tokenList[i]].latestGasFee;

            if (amount > 0) {
                IERC20(tokenList[i]).safeTransfer(msg.sender, amount);

                FeeList[tokenList[i]].latestGasFee = 0;
            }
        }

        uint256 ethAmount = FeeList[WETH].latestGasFee;
        if (ethAmount > 0) {
            payable(msg.sender).transfer(ethAmount);

            FeeList[WETH].latestGasFee = 0;
        }
    }

    // withdraw fee token
    function withdrawTokenFees(address _token) external onlyOwner nonReentrant {
        uint256 amount = FeeList[_token].latestGasFee;
        if (amount > 0) {
            IERC20(_token).safeTransfer(msg.sender, amount);

            FeeList[_token].latestGasFee = 0;
        }
    }

    // withdraw fee ETH
    function withdrawETHFees() external onlyOwner nonReentrant {
        uint256 amount = FeeList[WETH].latestGasFee;
        if (amount > 0) {
            payable(msg.sender).transfer(amount);

            FeeList[WETH].latestGasFee = 0;
        }
    }

    function emergencyWithdraw(address _user, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_user != address(0) && _amount > 0, "invalid data");

        for (uint256 i = 0; i < tokenList.length; i++) {
            uint256 balance = IERC20(tokenList[i]).balanceOf(address(this));
            if (balance > 0) {
                IERC20(tokenList[i]).safeTransfer(msg.sender, balance);
            }
        }

        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}