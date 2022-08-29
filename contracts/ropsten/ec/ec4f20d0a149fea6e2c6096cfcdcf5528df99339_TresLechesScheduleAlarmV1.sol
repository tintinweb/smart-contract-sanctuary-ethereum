/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

/*
    Website: https://tresleches.finance
    Contract Name: TresLechesScheduleAlarmV1
    Instagram: https://www.instagram.com/treslechestoken
    Twitter: https://twitter.com/treslechestoken
    Telegram: https://t.me/TresLechesCakeOfficial_EN
    Contract Version: 1.01



*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.16;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface ISmartSwapRouter02 {
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
        
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}


contract TresLechesScheduleAlarmV1 is Context {
    IERC20 public tresLechesToken;
    ISmartSwapRouter02 public smartSwap;
    address payable public devWallet;
    address public owner;
    uint256 public fee;
    uint256 public orderCount;
    uint256 public totalFeeCollected;
    
    struct userData {
        uint256 _id;
        uint256 amountIn;
        uint256 time;
        address caller;
        address[] path;
    }
    
    mapping(address => mapping(uint256 => userData)) private Data;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;
    mapping (address => bool) public permit;

    event markOrder(
        uint256 id,
        address indexed user,
        address indexed to,
        address swapFromToken,
        address swapToToken,
        uint256 amountToSwap
    );

    event Cancel(
        uint256 id,
        address indexed user,
        address swapFromToken,
        address swapToToken,
        uint256 amountIn,
        uint256 timestamp
    );

    event fulfilOrder(
        address indexed caller,
        address indexed to,
        address swapFromToken,
        address swapToToken,
        uint256 amountToSwap,
        uint256 time
    );

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    error Denied();
    error invalid();
    error Allowance();

    constructor(address _tresLechesToken, address _routerContract, address dev, uint256 timeFee)  {
        tresLechesToken = IERC20(_tresLechesToken);
        smartSwap = ISmartSwapRouter02(_routerContract);
        fee = timeFee;
        devWallet = payable(dev);
        owner = _msgSender();
    }

    receive() external payable {}

    function grantAccess(address addr, bool status) external onlyOwner {
        permit[addr] = status;
    }

    function updatetresLechesFee(uint256 _newFee) external onlyOwner {
        fee = _newFee;
    }

    function changeRouterContract(address _newRouter) external onlyOwner {
        smartSwap = ISmartSwapRouter02(_newRouter);
    }

    function checkAllowance(address swapFrom, address user, uint256 amount) internal view {
        uint256 allowToSpend = IERC20(swapFrom).allowance(user, address(this));
        uint256 allowForFee = tresLechesToken.allowance(user, address(this));
        if(allowForFee < fee) revert Allowance();
        if (swapFrom != address(0)) {            
            require(allowToSpend >= amount, "Approval Check Fail before Swap");
        }
    }

    function swapExactTokens(
        uint256 _orderID,
        address[] calldata path,
        address _user, 
        uint256 _amountIn
        ) external {    
              
        if (_orderID > orderCount) {
            orderCount = orderCount + 1;
        }
        if(!permit[_msgSender()]) revert Denied();
        checkAllowance(path[0], _user, _amountIn);
        tresLechesToken.transferFrom(_user, devWallet, fee);
        totalFeeCollected = totalFeeCollected + fee;
        IERC20(path[0]).approve(address(smartSwap), _amountIn);
        uint256[] memory outputAmount = smartSwap.getAmountsOut(
            _amountIn,
            path
        );
        require(IERC20(path[0]).transferFrom(_user, address(this), _amountIn));
        smartSwap.swapExactTokensForTokens(
            _amountIn,
            outputAmount[1],
            path,
            _user,
            block.timestamp + 1200
        );
        
        emit fulfilOrder(
            _msgSender(),
            _user,
            address(path[0]),
            path[1],
            _amountIn,
            block.timestamp
        );
    }

    function swapTokensForETH(
        uint256 _orderID,
        address[] calldata path,
        address _user, 
        uint256 _amountIn
        ) external {
        if (_orderID > orderCount) {
            orderCount = orderCount + 1;
        }
        if(!permit[_msgSender()]) revert Denied();
        checkAllowance(address(0), _user, _amountIn);
        tresLechesToken.transferFrom(_user, devWallet, fee);
        totalFeeCollected = totalFeeCollected + fee;
        IERC20(path[0]).approve(address(smartSwap), _amountIn);
        uint256[] memory outputAmount = smartSwap.getAmountsOut(
            _amountIn,
            path
        );
        require(IERC20(path[0]).transferFrom(_user, address(this), _amountIn));
        smartSwap.swapExactTokensForETH(
            _amountIn,
            outputAmount[1],
            path,
            _user,
            block.timestamp + 1200
        );
        
        emit fulfilOrder(
            _msgSender(),
            _user,
            address(path[0]),
            path[1],
            _amountIn,
            block.timestamp
        );
    }

    function setPeriodToSwapETHForTokens(
        address[] calldata path,
        uint256 _timeOf
        ) external payable{
        
        orderCount = orderCount + 1;
        userData storage _userData = Data[_msgSender()][orderCount];  
        _userData._id = orderCount;
        _userData.caller = _msgSender();
        _userData.amountIn = msg.value;
        _userData.path = [path[0], path[1]];
        _userData.time = block.timestamp;
        _userData.time = _timeOf;
        emit markOrder(
            _userData._id,
            _msgSender(),
            _msgSender(),
            path[0],
            path[1],
            msg.value
        );
    }

   function SwapETHForTokens(uint256 _id, address _user) external {
        if(!permit[_msgSender()]) revert Denied();
        require(_id > 0 && _id <= orderCount, "Error: wrong id");
        if(orderCancelled[_id]) revert invalid();
        userData memory _userData = Data[_user][_id]; 
        tresLechesToken.transferFrom(_user, devWallet, fee);
        totalFeeCollected = totalFeeCollected + fee;
        IERC20(_userData.path[1]).approve(address(smartSwap), _userData.amountIn);
        userData storage st = Data[_user][_id];
        uint256[] memory outputAmount = smartSwap.getAmountsOut(
            _userData.amountIn,
            _userData.path
        );
        // update the time this trx occure.
        st.time = block.timestamp;
        if(_userData.path[0] == smartSwap.WETH()) {
            smartSwap.swapExactETHForTokens{value: _userData.amountIn}(
                outputAmount[1],
                _userData.path,
                _user,
                block.timestamp + 1200
            );
        }
        emit fulfilOrder(
            _msgSender(),
            _user,
            _userData.path[0],
            _userData.path[1],
            _userData.amountIn,
            block.timestamp
        );
    }

    function withdrawToken(address _token, address _user, uint256 _amount) external onlyOwner {
     require(_user != address(0), "_user: ZERO");
        IERC20(_token).transfer(_user, _amount);
    }

    function withdrawETH(address _user, uint256 _amount) external onlyOwner {
        require(_user != address(0), "_user: ZERO");
        payable(_user).transfer(_amount);
    }

    function getUserData(address _user, uint256 _id) external view returns(userData memory _userData) {
        _userData = Data[_user][_id];        
    }
}