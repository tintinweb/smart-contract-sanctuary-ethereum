// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IFeatureProjectInfo.sol";
import "./FeatureProject.sol";
import "./IFeatureProject.sol";

contract FeatureFactory {
  using SafeMath for uint;

  uint public lastProjId;

  bool public paused;

  // only initialize permission
  address public owner;
  address public feeTo;
  address public info;

  // permission to allow proj feeRate to zero.
  // It's good? Yes!
  // Buy this just can act when judger give up him fee.
  // If factory feeController think there is benefit, feeController will allow it.
  // address public feeController;

  // Blockchain is The Dark Forest, always remember it, keep your save.
  // Everyone is evil. **Maybe this account mentioned below is evil too.**
  // Code is law, we dont want to change any rule's design by code.

  // Now show everyone the guys here.
  // We will try to invite important people to join this as multi-signature account.

  // permission to reject proj judgment permission durning judgmentPending when judgment is not fair.
  // If the leftSide or rightSide think it's not fair, Pleast contract judgeController or us ASAP with persuasive reason, we will reject this judgment.
  // After 7 days, proj judger can make judgment again,
  // Before we do this, Community should start a proposal at https://snapshot.org/
  // So every one should follow the rules:
  // - You won fair and square
  // - A word spoken is past recalling
  // And every one should know:
  // - How much you pay him to make those calls
  // address public judgeController;

  // address[] public projects;
  mapping(uint => address) public projects;

  // event ownerChange(address old, address newone);
  // event judgeControllerChange(address old, address newone);

  // event feeToChange(address old, address newone);
  // event feeControllerChange(address old, address newone);

  constructor() {
    owner = msg.sender;
    feeTo = msg.sender;
    // feeController = msg.sender;
    // judgeController = msg.sender;
  }

  function initialize(address _info) external {
    // require(msg.sender == owner, 'F:owner');
    require(msg.sender == owner);

    info = _info;
  }

  function getProject(uint _projId) external view returns (address) {
    return projects[_projId];
  }

  // factory own base func
  function pause(bool _paused) public {
    // require(msg.sender == owner, 'F:owner');
    require(msg.sender == owner);
    paused = _paused;
  }

  function changeOwner(address _owner) public {
    // require(msg.sender == owner, 'F:owner');
    require(msg.sender == owner);

    // emit ownerChange(owner, _owner);
    owner = _owner;
  }

  function changeFeeTo(address _feeTo) public {
    // require(msg.sender == feeTo, 'F:feeTo');
    require(msg.sender == feeTo);

    // emit feeToChange(feeTo, _feeTo);
    feeTo = _feeTo;
  }

  // function changeJudgeController(address _judgeController) public {
  //   require(msg.sender == judgeController, 'F:controller');

  //   // emit judgeControllerChange(judgeController, _judgeController);
  //   judgeController = _judgeController;
  // }

  // function changeFeeController(address _feeController) public {
  //   require(msg.sender == feeController || msg.sender == owner, 'F:controller');

  //   // emit feeControllerChange(feeController, _feeController);
  //   feeController = _feeController;
  // }

  // All send back self token fee will into mint again.
  function withdrawFee(address _token) public {
    TransferHelper.safeTransfer(_token, feeTo, IERC20(_token).balanceOf(address(this)));
  }

  // If some one is donate eth here, we thanks you to donate to us.
  // If you send eth here by mistake, we thanks you to donate to us, So be careful when make any transcation.
  // Same as other token, because we can withdraw it.
  function withdrawEthFee() public {
    TransferHelper.safeTransferETH(feeTo, address(this).balance);
  }

  receive() external payable {
  }
  // inner base func end

  // other function with project.

  // if their some game is started, if you think is hard to hold the security deposit, you can move it into here
  // if you use eth, you can change it into WETH to move into here.
  // This way it's design for Cobie(https://twitter.com/cobie)
  // as he join as judge between Sensei Algod, Do Kwon and GCR for LUNA's price
  // read https://twitter.com/AlgodTrading/status/1503103705939423234, https://twitter.com/cobie/status/1503271489726185472, https://etherscan.io/address/0x4Cbe68d825d21cB4978F56815613eeD06Cf30152#tokentxns for more detail.
  // Will him join our contract, let's waiting for good news.
  function createProj(
    uint _lockTime,
    uint _feeRate,

    AbstractFeatureProjectInfo.Info calldata _projInfo,
    AbstractFeatureProjectInfo.Judger calldata _judgerInfo
  ) public returns (uint _projId, address _project) {
    // require(_lockTime == 0 || _lockTime > block.timestamp, 'F:lockTime_gt');
    require(_lockTime == 0 || _lockTime > block.timestamp);

    // require(paused == false, 'F:paused');
    require(paused == false);

    // begin from 1
    _projId = lastProjId.add(1);

    bytes memory bytecode = type(FeatureProject).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(_projId));
    assembly {
      _project := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    lastProjId = _projId;
    projects[_projId] = _project;

    IFeatureProject(_project).initialize(_lockTime, _feeRate, msg.sender);
    IFeatureProjectInfo(info).addProject(
      _projId,
      _project,
      msg.sender,
      _lockTime,
      _feeRate,
      block.number,
      _projInfo,
      _judgerInfo
    );
  }

  // why any method's lock by factory but it looks not need.
  // there is the reason:
  // - take money by factory, not need to approve many time.
  // - any super control need factory, code is law, no one want to lose his money.
  // - factory need to know if the proj isAnnounced, and stop it's mint process.

  function ensureFeeRateZero(address _project) public {
    // require(msg.sender == feeController, 'F:feeController');
    // require(msg.sender == owner, 'F:feeController');
    require(msg.sender == owner);
    IFeatureProject(_project).ensureFeeRateZero();
  }

  function rejectJudgerment(address _project) public {
    // require(msg.sender == judgeController, 'F:judgeController');
    // require(msg.sender == owner, 'F:judgeController');
    require(msg.sender == owner);
    IFeatureProject(_project).rejectJudgerment();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library TransferHelper {
  function safeApprove(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool _success, bytes memory _data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(_success && (_data.length == 0 || abi.decode(_data, (bool))), 'FT: A_F');
  }

  function safeTransfer(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool _success, bytes memory _data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(_success && (_data.length == 0 || abi.decode(_data, (bool))), 'FT: T_F');
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool _success, bytes memory _data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(_success && (_data.length == 0 || abi.decode(_data, (bool))), 'FT: T_F_F');
  }

  function safeTransferETH(address to, uint value) internal {
    (bool _success,) = to.call{value:value}(new bytes(0));
    require(_success, 'FT: E_T_F');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./AbstractFeatureProjectInfo.sol";

interface IFeatureProjectInfo {
  function initialize(address _factory) external;

  function addProject(
    uint _projId,
    address _project,
    address _judger,
    uint _lockTime,
    uint _feeRate,
    uint _createBlockNumber,

    AbstractFeatureProjectInfo.Info calldata _projInfo,
    AbstractFeatureProjectInfo.Judger calldata _judgerInfo
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IFeatureProject {
  // for factory
  function initialize(uint _lockTime, uint _feeRate, address _judger) external;

  function ensureFeeRateZero() external;
  function rejectJudgerment() external;

  // for router
  function addPair(address _sender, address _token, uint _amount, bool _IsLeftSide, string calldata memo, string calldata memoUri) external;
  function joinPair(uint _appendId, address _sender, address _token, uint _amount, bool _IsLeftSide, string calldata memo, string calldata memoUri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./TransferHelper.sol";

contract FeatureProject {
  using SafeMath for uint;

  bool public isLeftSideWin;
  bool public isAnnounced;
  uint public announcedTime;

  // amount * feeRate / 10000 is the fee to judger;
  // amount * feeRate / 10000 is the fee to factory;
  // feeRate lowest is 30;
  // like that: if amount is $1m, if you win, feeRate = 30, judger can get $1000 fee, and factory get $1000 fee, you get $1m and other ($1m - $1000 - $1000) .
  // Lowest then juicebox now 500/10000 a lot.
  // Equal swap 30/10000.
  // cant change to other but 0;
  uint public feeRate;
  // need to set rate to zero, when it's ensure by factory owner. it can't reverse.
  bool public judgeFeeRateZeroPending;

  // factory, contains main auth.
  address public factory;
  // make judgement user.
  address public judger;

  // if is 0. it donn lock.
  // if is not 0, need lockTime >= block.timestamp to make judgement.
  // set when create.
  uint public lockTime;

  // judgment pending
  // when judgmentStartTime is set, it means judgment should start.
  // and will not allow to add or join pair.
  uint public judgmentStartTime;
  bool public judgmentPending;

  // amount of token.
  // reverse will not update when is announced.
  // is no useful after announced.
  mapping(address => uint) public reserve;

  address[] public leftSide;
  address[] public rightSide;

  uint constant statusDefault = 0;
  uint constant statusAbort = 1;
  uint constant statusWithdrawed = 2;
  // status default is 0, 1 is abort, 2 is withdrawed.
  uint[] public status;

  uint[] public amount;
  address[] public token;
  string[] public memoRightSide;
  string[] public memoUriRightSide;
  string[] public memoLeftSide;
  string[] public memoUriLeftSide;

  modifier lockNotAnnounced() {
    // require(isAnnounced == false, 'F:Announced');
    require(isAnnounced == false);
    _;
  }

  constructor() {
    factory = msg.sender;
  }

  // only can initialize one time
  // lock by factory, because it will call just after created.
  function initialize(uint _lockTime, uint _feeRate, address _judger) external {
    // require(msg.sender == factory, 'F:Factory');
    require(msg.sender == factory);

    // only can initialize one time check,
    // when judger is set, it means Initializeed.
    // require(judger == address(0), 'F:init');
    require(judger == address(0));

    // make sure args valid
    // require(_lockTime == 0 || _lockTime > block.timestamp, 'F:lockTime');
    require(_lockTime == 0 || _lockTime > block.timestamp);
    // require(_feeRate >= 30 && _feeRate <= 2000, 'F:FeeRate');
    require(_feeRate >= 30 && _feeRate <= 2000);
    // require(_judger != address(0), 'F:Judger');

    judger = _judger;
    feeRate = _feeRate;
    lockTime = _lockTime;
  }

  // judger can change feeRate to zero
  function unsetFeeRate() external {
    // require(judger == msg.sender, 'F:Judger');
    require(judger == msg.sender);
    // require(judgmentStartTime == 0, 'F:makeJudgment');
    require(judgmentStartTime == 0);
    // require(feeRate >= 0, 'F:is0');
    require(feeRate > 0);
    judgeFeeRateZeroPending = true;
  }

  // follow some side by token, not just talk.
  // Talk is cheap, show me the token.
  // yes, you can send token by set another profiteer.
  // because Cobie hse two pair competitor.
  // if you want to set to black hole, use 0x0000...dead .
  function addPair(address _profiteTo, address _token, uint _amount, bool _IsLeftSide, string calldata memo, string calldata memoUri) external {
    // ensure not try to annonce.
    // dont let user make mistakes.
    // require(judgmentStartTime == 0, 'F:startd');
    require(judgmentStartTime == 0);

    // require(address(_token) == _token, 'F:token');
    // require(_profiteTo != address(0), 'F:profiteTo');
    // require(_amount > 0, 'F:Amount');
    require(_amount > 0);

    uint _balance = IERC20(_token).balanceOf(address(this));
    // require(_balance >= _amount.add(reserve[_token]), 'F:K');
    require(_balance >= _amount.add(reserve[_token]));

    // need to init length;
    status.push(statusDefault);

    if (_IsLeftSide) {
      leftSide.push(_profiteTo);
      rightSide.push(address(0));

      memoRightSide.push('');
      memoUriRightSide.push('');
      memoLeftSide.push(memo);
      memoUriLeftSide.push(memoUri);
    }
    else {
      leftSide.push(address(0));
      rightSide.push(_profiteTo);
      memoRightSide.push(memo);
      memoUriRightSide.push(memoUri);
      memoLeftSide.push('');
      memoUriLeftSide.push('');
    }

    amount.push(_amount);
    token.push(_token);

    reserve[_token] = _balance;
  }

  // join pairs.
  // same means of addPair but joinPair need some addPair before.
  function joinPair(uint _appendId, address _profiteTo, address _token, uint _amount, bool _IsLeftSide, string calldata memo, string calldata memoUri) external lockNotAnnounced {
    // ensure not try to annonce.
    // dont let user make mistakes.
    // if try to announce, please your abort.
    // require(judgmentStartTime == 0, 'F:startd');
    require(judgmentStartTime == 0);

    uint _balance = IERC20(_token).balanceOf(address(this));
    // require(_balance >= _amount.add(reserve[_token]), 'F:K');
    require(_balance >= _amount.add(reserve[_token]));

    // require(token[_appendId] == _token, 'F:token');
    require(token[_appendId] == _token);
    // require(_profiteTo != address(0), 'F:profiteTo');
    // require(amount[_appendId] == _amount, 'F:Amount');
    require(amount[_appendId] == _amount);

    if (_IsLeftSide) {
      // require(leftSide[_appendId] == address(0), 'F:leftSide1');
      require(leftSide[_appendId] == address(0));
      // require(rightSide[_appendId] != address(0), 'F:rightSide1');
      require(rightSide[_appendId] != address(0));
      leftSide[_appendId] = _profiteTo;

      memoLeftSide[_appendId] = memo;
      memoUriLeftSide[_appendId] = memoUri;
    }
    else {
      // require(leftSide[_appendId] != address(0), 'F:leftSide2');
      require(leftSide[_appendId] != address(0));
      // require(rightSide[_appendId] == address(0), 'F:rightSide2');
      require(rightSide[_appendId] == address(0));
      rightSide[_appendId] = _profiteTo;

      memoRightSide[_appendId] = memo;
      memoUriRightSide[_appendId] = memoUri;
    }

    reserve[_token] = _balance;
  }

  function abort(uint _appendId) external {
    // require(status[_appendId] == statusDefault, 'F:statusDefault');
    require(status[_appendId] == statusDefault);

    address _leftSide = leftSide[_appendId];
    address _rightSide = rightSide[_appendId];
    address abortAddress = _leftSide != address(0) ? _leftSide : _rightSide;

    // require(_leftSide == address(0) || _rightSide == address(0), 'F:In');
    require(_leftSide == address(0) || _rightSide == address(0));
    // require(abortAddress == msg.sender, 'F:Owned');
    require(abortAddress == msg.sender);

    uint _amount = amount[_appendId];

    address _token = token[_appendId];

    TransferHelper.safeTransfer(_token, abortAddress, _amount);

    status[_appendId] = statusAbort;

    // when Announced, not need to change reserve
    if (!isAnnounced) {
      uint _balance = IERC20(_token).balanceOf(address(this));
      reserve[_token] = _balance;
    }
  }

  // if token has transfer fee, don't let it join by youself.
  // or no one can take it back.
  // i don't want to add a back door to transfer any token illegal
  function transferToWiner(address _token, address _winner, uint _winAmount) private {
    uint _fee = _winAmount.mul(feeRate).div(10000);
    uint _amount;
    if (_fee > 0) {
      TransferHelper.safeTransfer(_token, factory, _fee);
      TransferHelper.safeTransfer(_token, judger, _fee);
      _amount = _winAmount.mul(2).sub(_fee).sub(_fee);
    }
    else {
      _amount = _winAmount.mul(2);
    }

    TransferHelper.safeTransfer(_token, _winner, _amount);
  }

  function makeJudgment(bool _isLeftSideWin) external lockNotAnnounced {
    // require(judgmentPending == false, 'F:judgmentPending');
    require(judgmentPending == false);
    // require(msg.sender == judger, 'F:Judger');
    require(msg.sender == judger);
    // require(lockTime <= block.timestamp, 'F:lockTime');
    require(lockTime <= block.timestamp);

    // judgment can set later 1 days.
    // require((judgmentStartTime + 1 days) <= block.timestamp, 'F:Lock');
    require((judgmentStartTime + 1 days) <= block.timestamp);
    // require((judgmentStartTime + 10 minutes) <= block.timestamp);
    // require((judgmentStartTime + 10 seconds) <= block.timestamp);

    isLeftSideWin = _isLeftSideWin;
    // lock 1 days to ensure.
    // if something happen and need to reject, pleact contect us to rejuct it.
    judgmentStartTime = block.timestamp;
    judgmentPending = true;
  }

  // factory controller can change feeRate to zero when judge suggest to set feeRate to zero.
  function ensureFeeRateZero() external {
    // require(msg.sender == factory, 'F:Factory');
    require(msg.sender == factory);
    // require(judgmentStartTime == 0, 'F:makeJudgment');
    require(judgmentStartTime == 0);
    // require(feeRate >= 0, 'F:is0');
    require(feeRate >= 0);
    // require(judgeFeeRateZeroPending == true, 'F:Pending');
    require(judgeFeeRateZeroPending == true);
    feeRate = 0;
    judgeFeeRateZeroPending = false;
  }

  // factory controller can revert this if it's evil,
  // but factory controller will not do this
  function rejectJudgerment() external {
    // require(msg.sender == factory, 'F:Factory');
    require(msg.sender == factory);
    // require(judgmentPending == true, 'F:judgmentPending');
    require(judgmentPending == true);
    judgmentPending = false;
  }

  // any one can call this after time lock end;
  // ensure after 1 day since judger is make judgment
  function ensureJudgment() external lockNotAnnounced {
    // require(judgmentPending == true, 'F:judgmentPending');
    require(judgmentPending == true);
    // require(block.timestamp >= (judgmentStartTime + 1 days), 'F:Pending');
    require(block.timestamp >= (judgmentStartTime + 1 days));
    // require(block.timestamp >= (judgmentStartTime + 5 minutes));
    // require(block.timestamp >= (judgmentStartTime + 5 seconds));


    judgmentPending = false;
    isAnnounced = true;
    announcedTime = block.timestamp;
  }

  // you can call withdraw direct.
  // when Announced, can withdraw, not need to change reserve
  function withdraw(uint _appendId) external {
    // require(isAnnounced == true, 'F:isAnnounced');
    require(isAnnounced == true);

    // require(status[_appendId] == statusDefault, 'F:status');
    require(status[_appendId] == statusDefault);

    address _leftSide = leftSide[_appendId];
    address _rightSide = rightSide[_appendId];
    // require(_leftSide != address(0) || _rightSide != address(0), 'F:In');
    require(_leftSide != address(0) || _rightSide != address(0));

    address _winner;
    if (isLeftSideWin) {
      _winner = _leftSide;
    }
    else {
      _winner = _rightSide;
    }

    // if some one want to send gas to do call withdraw to other, very greate.
    // require winner to withdraw, by tx.origin, prepare for mint method in router.
    // require(msg.sender == _winner || tx.origin == _winner, 'F:winner');
    require(tx.origin == _winner);
    transferToWiner(token[_appendId], _winner, amount[_appendId]);
    status[_appendId] = statusWithdrawed;
  }

  // when this project is 365 days (always 1 year) since isAnnounced,
  // every one can take the token if someone not withdraw
  // we dont want the proj to archived in one way.
  function withdrawToken(address _token) public {
    // require(isAnnounced, 'F:isAnnounced');
    require(isAnnounced);
    // require(announcedTime + 365 days < block.timestamp, 'F:365');
    require(announcedTime + 365 days < block.timestamp);
    // require(announcedTime + 10 minutes < block.timestamp);
    // require(announcedTime + 10 seconds < block.timestamp);

    TransferHelper.safeTransfer(_token, msg.sender, IERC20(_token).balanceOf(address(this)));
  }

  // save size....
  // use by web.
  function getAllAddressData(uint _name) external view returns (address[] memory _all) {
    if (_name == 0) {
      _all = rightSide;
    }
    else if (_name == 1) {
      _all = leftSide;
    }
    else if (_name == 2) {
      _all = token;
    }
  }
  function getAddressDataByIndex(uint _name, uint _index) external view returns (address _data) {
    if (_name == 0) {
      _data = rightSide[_index];
    }
    else if (_name == 1) {
      _data = leftSide[_index];
    }
    else if (_name == 2) {
      _data = token[_index];
    }
  }
  function getAllUintData(uint _name) external view returns (uint[] memory _all) {
    if (_name == 3) {
      _all = amount;
    }
    else if (_name == 4) {
      _all = status;
    }
  }
  function getUintDataByIndex(uint _name, uint _index) external view returns (uint _data) {
    if (_name == 3) {
      _data = amount[_index];
    }
    else if (_name == 4) {
      _data = status[_index];
    }
  }

  function getAllStringData(uint _name) external view returns (string[] memory _all) {
    if (_name == 5) {
      _all = memoLeftSide;
    }
    else if (_name == 6) {
      _all = memoUriLeftSide;
    }
    else if (_name == 7) {
      _all = memoRightSide;
    }
    else if (_name == 8) {
      _all = memoUriRightSide;
    }
  }
  function geStringDataByIndex(uint _name, uint _index) external view returns (string memory _data) {
    if (_name == 5) {
      _data = memoLeftSide[_index];
    }
    else if (_name == 6) {
      _data = memoUriLeftSide[_index];
    }
    else if (_name == 7) {
      _data = memoRightSide[_index];
    }
    else if (_name == 8) {
      _data = memoUriRightSide[_index];
    }
  }
  // save size end
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract AbstractFeatureProjectInfo {
  struct Judger {
    string name;
    string description;
    string twitter;
  }

  struct Info {
    string name;
    string logoUri;
    string description;
    string moreInfo;
  }

  struct Projects {
    uint projId;
    address project;
    address judger;

    uint lockTime;

    uint feeRate;
    uint createBlockNumber;

    Info projInfo;
    Judger judgerInfo;
  }

  event ProjectCreated(Projects);

  Projects[] public projects;
  address factory;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}