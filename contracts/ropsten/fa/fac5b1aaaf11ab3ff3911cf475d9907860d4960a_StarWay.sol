/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    return c;
  }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // don't need to define other functions, only using `transfer()` in this case
}

contract StarWay {
    using SafeMath for uint256;
    IERC20 public usdt = IERC20(0x92858042A7DE859192511491cdEB6E75f383B5Bf);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Register(address indexed _wallet, uint256 _userId);
    event UserExists(uint256 _userId);
    event Reinvest(uint256 _userId, uint8 _setType, uint8 _setLevel, uint256 _matrixId);
    event Upgrade(uint256 _userId, uint8 _setType, uint8 _setLevel, uint256 _matrixId);
    event NewSet(uint256 _userId, uint8 _setType, uint8 _setLevel, uint256 _matrixId);
    event SetExists(uint256 _matrixId);
    event PayUpline(uint256 _userId, uint256 matrixId, uint8 _setType, uint8 _setLevel, uint256 amount);


    struct Matrix {
        uint8 setType; // ?????? ???????? 1-4
        uint256 balance; // ????????????, ???????????????????????? ???? ???????????????? ?? ??????????????
        uint8 userCount; // ???????????????????? ?????????????????????? ????????????????
        uint256 received; // ?????????? ?????????????????????? ????????????????
    }

    struct User {
        uint256 id;
        mapping (uint8 => uint8) lastActiveLevels; // ?? ?????????? ?????????? ?? ?????????? ?????????? ?????????????????? ?????????????? ???? ???????? ???????????? (1-15)
        mapping (uint8 => mapping (uint8 => uint256)) userMatrices; // ?????????????? ?????????? ???? ?????????? ?? ??????????. ???????????? ???? ???????????????????? ???????????? ????????????
                                                                    // ?????? ???????? (1-4) -> ?????????????? ????????(1-15) -> ???????????????????? id ??????????????
    }

    mapping (address => User) users; // ???????????????? ???????????? ???????????????????????? -> ???????????????? ????????????????????????
    mapping(uint256 => Matrix) matrices; //???????????? id ?????????????? -> ???????????????? ?????????????? (???????????????????? ???????????????? ??????????????????)
    mapping(uint => address payable) idToAddress; // ???????????????? id ???????????????????????? ?? ???????????? ????????????????????????

    uint256 private price = 600; // ?????????????? ???????? ??????????

    uint8 public constant LAST_LEVEL = 15; // ???????? ???????????????????? ??????????????

    uint8 public constant MAX_SETS = 4; // ???????? ???????????????????? ?????????? ?? ?????????? ??????????????

    address payable _owner; // ???????????????? ??????????????????

    // ???????????????? ?????????????????????????? ?????????????????????? ?????????? ???? ????????????????
    uint8[2] public AS7Percentage = [10, 90];
    uint8[3] public AS15Percentage = [20, 30, 50];
    uint8[4] public AS31Percentage = [10, 20, 30, 40];

    uint256 public lastUserId; // ?????????????????? ?????????????? id ?????????? (???????????????????? ??????????????????)
    uint256 public lastMatrixId; // ?????????????????? ?????????????? id ?????????????? (???????????????????? ??????????????????)

    uint8[4] public maxUsersPerSet = [4, 6, 14, 30]; // ???????????????????????? ???????????????????? ???????????????? ???? ?????????????????????? ?? ????????

    uint256[4] public maxPaymentsPerSet = [2000, 1900, 2800, 2640]; // ???????????????????????? ?????????? ???????????????? ?????? ???????????????? ????????


    constructor () public {
        _owner = msg.sender;
        //emit OwnershipTransferred(address(0), _owner);
        lastUserId += 1;
        idToAddress[lastUserId] = _owner;

        User memory user = User({
                                    id: lastUserId
                                });
        users[_owner] = user;

        emit Register(_owner, lastUserId);
        for (uint8 i = 1; i <= 4 ; i++) {
            lastMatrixId += 1;

            Matrix memory matrix = Matrix({
                                        setType: i,
                                        balance: 0,
                                        userCount: 0,
                                        received:0
                                    });
            matrices[lastMatrixId] = matrix;
            users[_owner].lastActiveLevels[i] = 1;
            users[_owner].userMatrices[i][1] = lastMatrixId;

            emit NewSet(lastUserId, i, 1, lastMatrixId);
        }

    }



    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // ???????????????? ?????????????? ????????
    function getPrice() public view returns (uint256) {
        return price;
    }

    // ?????????????????? ?????????????? ????????
    function setPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must not be zero");
        price = newPrice;
    }

    // ???????????????? ???????????????????????? ???????????????? ???? ?????????? ?????????? ?????? 1 ????????????
    function getMaxPayments() public view returns (uint256, uint256, uint256, uint256) {
        return (maxPaymentsPerSet[0], maxPaymentsPerSet[1],maxPaymentsPerSet[2],maxPaymentsPerSet[3]);
    }

    // ?????????????????? ???????????????????????? ???????????????? ???? ?????????? ?????????? ?????? 1 ????????????
    function setMaxPayments(uint256[4] calldata _newMaxPayments) external onlyOwner {
        for (uint8 i = 0; i < maxPaymentsPerSet.length; i++) {
            maxPaymentsPerSet[i] = _newMaxPayments[i];
        }
    }


    //???????????? ???????? ???????????? ???? ??????????????
    function calculatePrice(uint8 _setLevel) public view returns (uint256) {
        return _setLevel==1?price:price.mul(2 ** uint256(_setLevel-1));
    }

    //???????????? ???????????????????????? ???????????????? ???????????? ???? ????????????????
    function calculateMaxPayments(uint8 _setType, uint8 _setLevel) public view returns (uint256) {
        return _setLevel==1?maxPaymentsPerSet[_setType-1]:maxPaymentsPerSet[_setType-1].mul(2 ** uint256(_setLevel-1));
    }

    // ????????????????, ?????????? ???? ?????????????????? ??????
    function setIsReadyToClose(uint256 _matrixId) public view returns (bool) {
        if (matrices[_matrixId].userCount >= maxUsersPerSet[matrices[_matrixId].setType-1]) {
            return true;
        } else {
            return false;
        }
    }

    // ?????????????????? ?????????????? ???? ????????
    function getMatrixBalance (uint256 _matrixId) external view returns (uint256) {
        return matrices[_matrixId].balance;

    }
    // ?????????????????? ???????????????????? ???????????????? ?? ????????
    function getMatrixUserCount (uint256 _matrixId) external view returns (uint256) {
        return matrices[_matrixId].userCount;

    }

    // ?????????????????? ???????? ????????
    function getMatrixType (uint256 _matrixId) external view returns (uint8) {
        return matrices[_matrixId].setType;

    }

    // ?????????????????? ?????????????????????? id ???????? ???? ????????????????????????, ???????? ?? ????????????
    function getUserMartrixId(uint256 _userId, uint8 _setType, uint8 _setLevel) public view returns (uint256) {
        return users[idToAddress[_userId]].userMatrices[_setType][_setLevel];
    }

    // ?????????????????? ?????????? ????????????????, ?????????????????????? ???? ??????
    function getMatrixPayments (uint256 _matrixId) external view returns (uint256) {
        return matrices[_matrixId].received;

    }

    // ???????????????? ?????????????????????????? ???????? ???? ?????????????????????? id
    function MatrixExists (uint256 _matrixId) external view returns (bool) {
        if (matrices[_matrixId].setType > 0) {
            return true;
        } else {
            return false;
        }

    }

    // ?????????????????????? ???????????? ????????????????????????
    function registerUser (address payable _wallet) internal {
        lastUserId+=1;
        idToAddress[lastUserId] = _wallet;

        User memory user = User({
                                    id: lastUserId
                                });
        users[_wallet] = user;

        emit Register(_wallet, lastUserId);

    }


    // ???????????????? ????????????
    function newMatrix(uint256[][] calldata incoming, uint256 _usdtAmount) external payable returns(bool) {
        require(incoming.length <= MAX_SETS, "You cannot buy more than 4 sets at a time."); // ???????????? ???????????????????? ???? ?????????? 4 ?????????? ???? ??????
        uint256 totalAmount = 0;
        // ???????????????????????? ???????????? ????????????????????????
        if (users[msg.sender].id == 0) {
            registerUser(msg.sender);
        }

        for (uint8 i = 0; i < incoming.length; i++) {
            require(incoming[i].length - 2 == incoming[i][0], "Invalid number of arguments"); // ??????????????????. ?????????? ???????????????????? ??????????????????
                                                                                              // ?????????????????????????????? ???????? ????????
            for (uint8 x = 2; x < incoming[i].length; x++) {
                require(incoming[i][x] != users[msg.sender].id, "Referral id cannot be same as user id");
                require(idToAddress[incoming[i][x]] != address(0), "Invalid referal id"); // ?????????????????? ?????????????????????????? ????????????????
                require(users[idToAddress[incoming[i][x]]].lastActiveLevels[uint8(incoming[i][0])] >= incoming[i][1],
                            "Referal has no sets of this level"); // ?????????????????? ?? ???????????????? ?????????????? ???????? ?????????????? ????????
            }
            // ??????????????????, ?????????? ???? ?????????? ???????? ???????????????? ???????? ?????????????? ?????? ?????????? ???????? ????????.
            if (i == 0) {
                require(users[msg.sender].lastActiveLevels[uint8(incoming[i][0])] == incoming[i][1]-1, "This level is unavailable for user");
            } else {
                if (incoming[i][0] == incoming[i-1][0]) {
                    require(incoming[i][1] == incoming[i-1][1] + 1, "This level is unavailable for user");
                } else {
                    require(users[msg.sender].lastActiveLevels[uint8(incoming[i][0])] == incoming[i][1]-1, "This level is unavailable for user");
                }

            }
            totalAmount = totalAmount.add(calculatePrice(uint8(incoming[i][1])));
        }
        require(_usdtAmount >= totalAmount, "Insufficient funds to buy all sets");
        require(usdt.allowance(msg.sender, address(this)) >= _usdtAmount, "Amount is not allowed by USDT holder");
        usdt.transferFrom(msg.sender, address(this), _usdtAmount);
        totalAmount = _usdtAmount; // ??????????, ???????????????????? ???????????? ??????????

        // ???????????????? ???? ???????? ???????????????? ??????????, ???????????????? ???????????? ???????? ?? ???????????????? ??????????????????????.
        for (uint8 i = 0; i < incoming.length; i++) {
            uint256 cost = calculatePrice(uint8(incoming[i][1])); //?????????????????? ?????????????????? ???????? ?? ?????????????????????? ???? ???????? ?? ???????????? ???? ?????????????? ????????.
            totalAmount = totalAmount.sub(cost.mul(5).div(6)); // ?????????????????? ?????????????????? ???????? ?? ?????????? ?????????? ??????????????.
            createMatrix(users[msg.sender].id, cost.mul(5).div(6), incoming[i]); // ?????????????? ??????????????
        }

        usdt.transfer(_owner, totalAmount);
    }


    function createMatrix(uint256 _userId, uint256 amount, uint256[] memory _setData) internal {
        uint8 _setType = uint8(_setData[0]);
        uint8 _setLevel = uint8(_setData[1]);
        lastMatrixId += 1;

        Matrix memory matrix = Matrix({
                                    setType: _setType,
                                    balance: 0,
                                    userCount: 0,
                                    received:0
                                });
        matrices[lastMatrixId] = matrix;
        users[idToAddress[_userId]].lastActiveLevels[_setType] = _setLevel;
        users[idToAddress[_userId]].userMatrices[_setType][_setLevel] = lastMatrixId;

        emit NewSet(_userId, _setType, _setLevel, lastMatrixId);

        if (_setData[0] == 1) {
            makePayment(_setData[2], _setType, _setLevel, amount);
        } else if (_setData[0] == 2) {
            uint256 ref1Payment = amount.mul(AS7Percentage[0]).div(100);
            makePayment(_setData[2], _setType, _setLevel, ref1Payment);
            uint256 ref2Payment = amount.sub(ref1Payment);
            makePayment(_setData[3], _setType, _setLevel, ref2Payment);
        } else if (_setData[0] == 3) {
            uint256 ref1Payment = amount.mul(AS15Percentage[0]).div(100);
            makePayment(_setData[2], _setType, _setLevel, ref1Payment);
            uint256 ref2Payment = amount.mul(AS15Percentage[1]).div(100);
            makePayment(_setData[3], _setType, _setLevel, ref2Payment);
            uint256 ref3Payment = amount.sub(ref1Payment).sub(ref2Payment);
            makePayment(_setData[4], _setType, _setLevel, ref3Payment);
        } else if (_setData[0] == 2) {
            uint256 ref1Payment = amount.mul(AS31Percentage[0]).div(100);
            makePayment(_setData[2], _setType, _setLevel, ref1Payment);
            uint256 ref2Payment = amount.mul(AS31Percentage[1]).div(100);
            makePayment(_setData[3], _setType, _setLevel, ref2Payment);
            uint256 ref3Payment = amount.mul(AS31Percentage[2]).div(100);
            makePayment(_setData[4], _setType, _setLevel, ref3Payment);
            uint256 ref4Payment = amount.sub(ref1Payment).sub(ref2Payment).sub(ref3Payment);
            makePayment(_setData[5], _setType, _setLevel, ref4Payment);
            }

    }


    function makePayment(uint256 _userId, uint8 _setType, uint8 _setLevel, uint256 amount) internal  {
        uint256 matrixId = users[idToAddress[_userId]].userMatrices[_setType][_setLevel];
        uint256 _MaxPayment = calculateMaxPayments(_setType, _setLevel);
        uint256 required;
        if (users[idToAddress[_userId]].lastActiveLevels[_setType] > _setLevel) {
            required = calculatePrice(_setLevel);
        } else {
            required = calculatePrice(_setLevel).add(calculatePrice(_setLevel+1));
        }
        uint256 left = _MaxPayment.sub(required).sub(matrices[matrixId].received.sub(matrices[matrixId].balance));
        if (left >= amount) {
            usdt.transfer(idToAddress[_userId], amount);
        } else {
            usdt.transfer(idToAddress[_userId], left);
            matrices[matrixId].balance = matrices[matrixId].balance.add(amount.sub(left));
        }
        matrices[matrixId].received = matrices[matrixId].received.add(amount);
        matrices[matrixId].userCount += 1;
        emit PayUpline(_userId, matrixId, _setType, _setLevel, amount);

    }

    function fundMatrix(uint256 _matrixId, uint256 _usdtAmount) external payable onlyOwner {
        require(matrices[_matrixId].setType > 0, "This set doesn't exit");
        require(usdt.allowance(msg.sender, address(this)) >= _usdtAmount, "Amount is not allowed by USDT holder");
        matrices[_matrixId].balance = matrices[_matrixId].balance.add(_usdtAmount);
        usdt.transferFrom(msg.sender, address(this), _usdtAmount);
    }


    function upgradeMatrix(uint256 _userId, uint256 _matrixId, uint256[] calldata _setData) external onlyOwner {
        uint8 _setType = uint8(_setData[0]);
        uint8 _setLevel = uint8(_setData[1]);
        require(_setLevel <= LAST_LEVEL, "Only 15 levels are available.");
        require(matrices[_matrixId].setType > 0, "Set doesn't exit.");
        require(users[idToAddress[_userId]].userMatrices[_setType][_setLevel] == 0, "User already has upgraded set");
        for (uint8 x = 2; x < _setData.length; x++) {
            require(_setData[x] != _userId, "Referral id cannot be same as user id");
            require(idToAddress[_setData[x]] != address(0), "Invalid referal id"); // ?????????????????? ?????????????????????????? ????????????????
            require(users[idToAddress[_setData[x]]].lastActiveLevels[uint8(_setData[0])] >= _setData[1],
                            "Referal has no sets of this level"); // ?????????????????? ?? ???????????????? ?????????????? ???????? ?????????????? ????????
        }

        uint256 cost = calculatePrice(_setLevel);
        require(matrices[_matrixId].balance >= cost, "Insufficient set balance to upgrade");
        createMatrix(_userId, cost.mul(5).div(6), _setData);
        usdt.transfer(_owner, cost.sub(cost.mul(5).div(6)));

        matrices[_matrixId].balance = matrices[_matrixId].balance.sub(cost);
        emit Upgrade(_userId, _setType, _setLevel, _matrixId);

    }


    function reinvest(uint256 _userId, uint256[] calldata _setData) external onlyOwner {
        uint8 _setType = uint8(_setData[0]);
        uint8 _setLevel = uint8(_setData[1]);
        uint256 matrixId = users[idToAddress[_userId]].userMatrices[_setType][_setLevel];
        require(matrixId > 0, "Set doesn't exist");
        //require(matrices[matrixId].userCount == maxUsersPerSet[_setType-1], "Set doesn't have enough users to be closed");
        for (uint8 x = 2; x < _setData.length; x++) {
            require(_setData[x] != _userId, "Referral id cannot be same as user id");
            require(idToAddress[_setData[x]] != address(0), "Invalid referal id"); // ?????????????????? ?????????????????????????? ????????????????
            require(users[idToAddress[_setData[x]]].lastActiveLevels[uint8(_setData[0])] >= _setData[1],
                            "Referal has no sets of this level"); // ?????????????????? ?? ???????????????? ?????????????? ???????? ?????????????? ????????
        }
        uint256 cost = calculatePrice(_setLevel);
        require(matrices[matrixId].balance >= cost, "Insufficient set balance to make reinvest" );
        uint256 amount = cost.mul(5).div(6);
        if (_setData[0] == 1) {
            makePayment(_setData[2], _setType, _setLevel, amount);
        } else if (_setData[0] == 2) {
            uint256 ref1Payment = amount.mul(AS7Percentage[0]).div(100);
            makePayment(_setData[2], _setType, _setLevel, ref1Payment);
            uint256 ref2Payment = amount.sub(ref1Payment);
            makePayment(_setData[3], _setType, _setLevel, ref2Payment);
        } else if (_setData[0] == 3) {
            uint256 ref1Payment = amount.mul(AS15Percentage[0]).div(100);
            makePayment(_setData[2], _setType, _setLevel, ref1Payment);
            uint256 ref2Payment = amount.mul(AS15Percentage[1]).div(100);
            makePayment(_setData[3], _setType, _setLevel, ref2Payment);
            uint256 ref3Payment = amount.sub(ref1Payment).sub(ref2Payment);
            makePayment(_setData[4], _setType, _setLevel, ref3Payment);
        } else if (_setData[0] == 2) {
            uint256 ref1Payment = amount.mul(AS31Percentage[0]).div(100);
            makePayment(_setData[2], _setType, _setLevel, ref1Payment);
            uint256 ref2Payment = amount.mul(AS31Percentage[1]).div(100);
            makePayment(_setData[3], _setType, _setLevel, ref2Payment);
            uint256 ref3Payment = amount.mul(AS31Percentage[2]).div(100);
            makePayment(_setData[4], _setType, _setLevel, ref3Payment);
            uint256 ref4Payment = amount.sub(ref1Payment).sub(ref2Payment).sub(ref3Payment);
            makePayment(_setData[5], _setType, _setLevel, ref4Payment);
        }
        matrices[matrixId].userCount = 0;
        matrices[matrixId].received = 0;
        if (matrices[matrixId].balance.sub(cost) > 0) {
            usdt.transfer(idToAddress[_userId], matrices[matrixId].balance.sub(cost));
        }
        matrices[matrixId].balance = 0;
        usdt.transfer(_owner, cost.sub(amount));
        emit Reinvest(_userId, _setType, _setLevel, matrixId);
    }


    function addUser(address payable _wallet) external onlyOwner {
        if (users[_wallet].id == 0) {
            lastUserId+=1;
            idToAddress[lastUserId] = _wallet;

            User memory user = User({
                                        id: lastUserId
                                    });
            users[_wallet] = user;

            emit Register(_wallet, lastUserId);
        } else {
            emit UserExists(users[_wallet].id);
        }

    }


    function addSet(uint256 _userId, uint8 _setType, uint8 _setLevel) external onlyOwner {
        require(_userId >= lastUserId, "User with this id is not registered");
        if (getUserMartrixId(_userId, _setType, _setLevel) == 0) {
            lastMatrixId += 1;

            Matrix memory matrix = Matrix({
                                        setType: _setType,
                                        balance: 0,
                                        userCount: 0,
                                        received:0
                                    });
            matrices[lastMatrixId] = matrix;
            users[idToAddress[_userId]].lastActiveLevels[_setType] = _setLevel;
            users[idToAddress[_userId]].userMatrices[_setType][_setLevel] = lastMatrixId;

            emit NewSet(_userId, _setType, _setLevel, lastMatrixId);
        } else {
            emit SetExists(getUserMartrixId(_userId, _setType, _setLevel));
        }

    }

}