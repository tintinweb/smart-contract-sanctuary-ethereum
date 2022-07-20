/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

//SPDX-License-Identifier: UNLICENSED
/*

THE CONTRACT, SUPPORTING WEBSITES, AND ALL OTHER INTERFACES (THE SOFTWARE) IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

BY INTERACTING WITH THE SOFTWARE YOU ARE ASSERTING THAT YOU BEAR ALL THE RISKS ASSOCIATED WITH DOING SO. AN INFINITE NUMBER OF UNPREDICTABLE THINGS MAY GO WRONG WHICH COULD POTENTIALLY RESULT IN CRITICAL FAILURE AND FINANCIAL LOSS. BY INTERACTING WITH THE SOFTWARE YOU ARE ASSERTING THAT YOU AGREE THERE IS NO RECOURSE AVAILABLE AND YOU WILL NOT SEEK IT.

INTERACTING WITH THE SOFTWARE SHALL NOT BE CONSIDERED AN INVESTMENT OR A COMMON ENTERPRISE. INSTEAD, INTERACTING WITH THE SOFTWARE IS EQUIVALENT TO CARPOOLING WITH FRIENDS TO SAVE ON GAS AND EXPERIENCE THE BENEFITS OF THE H.O.V. LANE.

YOU SHALL HAVE NO EXPECTATION OF PROFIT OR ANY TYPE OF GAIN FROM THE WORK OF OTHER PEOPLE.

*/

pragma solidity ^0.8.2;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract OctaAA {
    function swapAndReceive(address, uint256) public returns (uint256) {}
}

contract TOKEN1 {
    function balanceOf(address account) external view returns (uint256) {}
    function transfer(address recipient, uint256 amount) external returns (bool) {}
}

contract TOKEN2 {
    function balanceOf(address account) external view returns (uint256) {}
    function transfer(address recipient, uint256 amount) external returns (bool) {}
    function approve(address spender, uint256 amount) external returns (bool) {}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {}
    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external {}
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external {}
    function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam) external {}
    function stakeCount(address stakerAddr) external view returns (uint256) {}
    function stakeLists(address owner, uint256 stakeIndex) external view returns (uint40, uint72, uint72, uint16, uint16, uint16, bool) {}
    function currentDay() external view returns (uint256) {}
}

contract TOKEN3 {
    function balanceOf(address account) external view returns (uint256) {}
    function transfer(address recipient, uint256 amount) external returns (bool) {}
    function mintNative(uint256 stakeIndex, uint40 stakeId) external returns (uint256) {}
}

contract OctaStaking is ReentrancyGuard {
    modifier onlyCustodian1() {
        require(msg.sender == custodian1);
      _;
    }

    modifier onlyCustodian2() {
        require(msg.sender == custodian2);
      _;
    }

    modifier isStakeActivated {
        require(stakeActivated == true);
        _;
    }

    event onStakeStart(
        address indexed customerAddress,
        uint256 uniqueID,
        uint256 timestamp
    );

    event onStakeEnd(
        address indexed customerAddress,
        uint256 uniqueID,
        uint256 returnAmount,
        uint256 octaAmount,
        uint256 timestamp
    );

    struct Stats {
        uint256 staked;
        uint256 activeStakes;
    }

    mapping(address => Stats) public playerStats;

    uint256 public totalStakeBalance = 0;
    uint256 public totalPlayer = 0;
    address public custodian1;
    address public custodian2;
    address public approvedAddress1;
    address public approvedAddress2;

    TOKEN1 octaToken;
    TOKEN2 hexToken;
    TOKEN3 hedronToken;
    OctaAA octaSwap;
    address public octaSwapAddress;
    bool public finalizeOctaAddress = false;
    bool public hasTransferred = false;

    struct StakeStore {
      uint40 stakeID;
      uint256 hexAmount;
      uint72 stakeShares;
      uint16 lockedDay;
      uint16 stakedDays;
      uint16 unlockedDay;
      bool started;
      bool ended;
      uint256 bonusMultiplier;
      bool swapAll;
    }

    uint256 public currentBonusMultiplier = 10;
    uint256 public minimumHex = 100000000000;
    bool public stakeActivated = false;
    bool public hedronAllowed = true;
    mapping(address => mapping(uint256 => StakeStore)) public stakeLists;

    constructor() ReentrancyGuard() {
        custodian1 = address(0xf989A6939f5fC6d85118E912aB28a699EBdEa9Ce);
        custodian2 = address(0xfE8D614431E5fea2329B05839f29B553b1Cb99A2);
        octaToken = TOKEN1(address(0x0));
        hexToken = TOKEN2(address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39));
        hedronToken = TOKEN3(address(0x3819f64f282bf135d62168C1e513280dAF905e06));
        octaSwapAddress = address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);
        octaSwap = OctaAA(octaSwapAddress);
    }

    function transferCustodianTokens() onlyCustodian1 external {
        require(hasTransferred == false);
        uint256 _amount = octaToken.balanceOf(address(this)) / 20;
        octaToken.transfer(address(0xcAAB2DCA6fC1af9D43972095aA148738a854abe2), _amount);
        octaToken.transfer(custodian2, _amount);
        hasTransferred = true;
        stakeActivated = true;
    }

    function checkAndTransferHEX(uint256 _amount) private {
        require(hexToken.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function stakeStart(uint256 _amount, uint256 _days, bool _swapAll) nonReentrant isStakeActivated external {
        require(_amount >= minimumHex && _amount <= 4722366482869645213695);
        require(hexToken.stakeCount(address(this)) < type(uint256).max);

        checkAndTransferHEX(_amount);
        hexToken.stakeStart(_amount, _days);

        uint256 _stakeIndex;
        uint40 _stakeID;
        uint72 _stakeShares;
        uint16 _lockedDay;
        uint16 _stakedDays;

        _stakeIndex = hexToken.stakeCount(address(this));
        _stakeIndex -= 1;

        (_stakeID,,_stakeShares,_lockedDay,_stakedDays,,) = hexToken.stakeLists(address(this), _stakeIndex);

        uint256 _uniqueID =  uint256(keccak256(abi.encodePacked(_stakeID, _stakeShares)));
        require(stakeLists[msg.sender][_uniqueID].started == false);
        stakeLists[msg.sender][_uniqueID].started = true;

        stakeLists[msg.sender][_uniqueID] = StakeStore(_stakeID, _amount, _stakeShares, _lockedDay, _stakedDays, uint16(0), true, false, currentBonusMultiplier, _swapAll);

        totalStakeBalance = totalStakeBalance + _amount;
        playerStats[msg.sender].activeStakes += 1;

        if (playerStats[msg.sender].staked == 0) {
            totalPlayer++;
        }

        playerStats[msg.sender].staked += _amount;

        emit onStakeStart(msg.sender, _uniqueID, block.timestamp);
    }

    function _stakeSecurityCheck(address _stakerAddress, uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID) private view returns (uint16) {
        uint40 _stakeID;
        uint72 _stakedHearts;
        uint72 _stakeShares;
        uint16 _lockedDay;
        uint16 _stakedDays;
        uint16 _unlockedDay;

        (_stakeID,_stakedHearts,_stakeShares,_lockedDay,_stakedDays,_unlockedDay,) = hexToken.stakeLists(address(this), _stakeIndex);
        require(stakeLists[_stakerAddress][_uniqueID].started == true && stakeLists[_stakerAddress][_uniqueID].ended == false);
        require(stakeLists[_stakerAddress][_uniqueID].stakeID == _stakeIdParam && _stakeIdParam == _stakeID);
        require(stakeLists[_stakerAddress][_uniqueID].hexAmount == uint256(_stakedHearts));
        require(stakeLists[_stakerAddress][_uniqueID].stakeShares == _stakeShares);
        require(stakeLists[_stakerAddress][_uniqueID].lockedDay == _lockedDay);
        require(stakeLists[_stakerAddress][_uniqueID].stakedDays == _stakedDays);

        return _unlockedDay;
    }

    function _stakeEnd(address _stakerAddress, uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID) private {
        uint16 _unlockedDay = _stakeSecurityCheck(_stakerAddress, _stakeIndex, _stakeIdParam, _uniqueID);

        if (_unlockedDay == 0) {
          stakeLists[_stakerAddress][_uniqueID].unlockedDay = uint16(hexToken.currentDay());
        } else {
          stakeLists[_stakerAddress][_uniqueID].unlockedDay = _unlockedDay;
        }

        uint256 _balance = hexToken.balanceOf(address(this));

        if (hedronAllowed == true) {
            hedronToken.mintNative(_stakeIndex, _stakeIdParam);
            hedronToken.transfer(_stakerAddress, hedronToken.balanceOf(address(this)));
        }

        hexToken.stakeEnd(_stakeIndex, _stakeIdParam); // revert or 0 or less or equal or more hex returned.
        stakeLists[_stakerAddress][_uniqueID].ended = true;

        uint256 _amount = hexToken.balanceOf(address(this)) - _balance;
        uint256 _stakedAmount = stakeLists[_stakerAddress][_uniqueID].hexAmount;
        uint256 _bonusDividend;

        if (_amount <= _stakedAmount) {
          hexToken.transfer(_stakerAddress, _amount);
        } else if (_amount > _stakedAmount) {
          uint256 _bonusAmount;
          uint256 _difference = _amount - _stakedAmount;

          if (stakeLists[_stakerAddress][_uniqueID].swapAll) {
              _bonusDividend = octaSwap.swapAndReceive(_stakerAddress, _amount);
              _bonusDividend = _difference * _bonusDividend / _amount;
          } else {
              hexToken.transfer(_stakerAddress, _stakedAmount);
              _bonusDividend = octaSwap.swapAndReceive(_stakerAddress, _difference);
          }

          _bonusAmount = _bonusDividend * stakeLists[_stakerAddress][_uniqueID].bonusMultiplier / 100;

          if (_bonusAmount > 0) {
            if (octaToken.balanceOf(address(this)) >= _bonusAmount) {
              octaToken.transfer(_stakerAddress, _bonusAmount);
            } else {
              octaToken.transfer(_stakerAddress, octaToken.balanceOf(address(this)));
            }
          }
        }

        totalStakeBalance = totalStakeBalance - _stakedAmount;
        playerStats[_stakerAddress].activeStakes -= 1;

        emit onStakeEnd(_stakerAddress, _uniqueID, _amount, _bonusDividend, block.timestamp);
    }

    function stakeEnd(uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID) nonReentrant external {
        _stakeEnd(msg.sender, _stakeIndex, _stakeIdParam, _uniqueID);
    }

    function stakeGoodAccounting(address _stakerAddress, uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID) nonReentrant external {
        hexToken.stakeGoodAccounting(address(this), _stakeIndex, _stakeIdParam);
        _stakeEnd(_stakerAddress, _stakeIndex, _stakeIdParam, _uniqueID);
    }

    function setHexStaking(bool _stakeActivated) onlyCustodian1 external {
        stakeActivated = _stakeActivated;
    }

    function allowHedron(bool _state) onlyCustodian1 external {
        hedronAllowed = _state;
    }

    function setMinimumStakingAmount(uint256 _minimumHex) onlyCustodian1 external {
        minimumHex = _minimumHex;
    }

    function setBonusMultiplier(uint256 _newBonusMultiplier) onlyCustodian1 external {
        require(_newBonusMultiplier >= 0 || _newBonusMultiplier <= 100);
        currentBonusMultiplier = _newBonusMultiplier;
    }

    function approveAddress1(address _proposedAddress) onlyCustodian1 external {
        approvedAddress1 = _proposedAddress;
    }

    function approveAddress2(address _proposedAddress) onlyCustodian2 external {
        approvedAddress2 = _proposedAddress;
    }

    function setOctaSwapAddress() onlyCustodian1 external {
        require(approvedAddress1 == approvedAddress2);
        hexToken.approve(octaSwapAddress, 0);
        hexToken.approve(approvedAddress1, type(uint256).max);
        octaSwapAddress = approvedAddress1;
        octaSwap = OctaAA(octaSwapAddress);
    }

    function setOctaAddress(address _proposedAddress) onlyCustodian1 external {
        require(finalizeOctaAddress == false);
        octaToken = TOKEN1(_proposedAddress);
    }

    function finalizeOctaTokenAddress() onlyCustodian1 external {
        finalizeOctaAddress = true;
    }
}