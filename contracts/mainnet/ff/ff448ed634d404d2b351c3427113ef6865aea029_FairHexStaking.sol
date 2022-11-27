/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

//SPDX-License-Identifier: UNLICENSED
/*

FairHEX is a reflection token built on top of HEX

Claim your free FairHEX token

Website : https://fairhex.eth.limo

*/

pragma solidity ^0.8.17;

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

contract UniSwapV2LiteRouter {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts) {}
}

contract FairHexStaking is ReentrancyGuard {
    modifier onlyCustodian() {
        require(msg.sender == custodian);
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
        uint256 fairHexAmount,
        uint256 timestamp
    );

    uint256 public totalStakeBalance = 0;
    bool public finalizeAddress = false;
    bool public normalStaking = false;
    address public custodian = address(0x12414A2144b6048010c1b0fe67f25072E06DC0B1);

    address private fairHexAddress = address(0x0);
    address private hexAddress = address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);
    address private hedronAddress = address(0x3819f64f282bf135d62168C1e513280dAF905e06);
    address private routerAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    TOKEN1 fairHexToken = TOKEN1(fairHexAddress);
    TOKEN2 hexToken = TOKEN2(hexAddress);
    TOKEN3 hedronToken=  TOKEN3(hedronAddress);
    UniSwapV2LiteRouter private router = UniSwapV2LiteRouter(routerAddress);

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
      bool mintState;
    }

    uint256 public totalMinted = 0;
    uint256 public currentBonusMultiplier = 40;
    uint256 public minimumHex = 100000000000;
    mapping(address => mapping(uint256 => StakeStore)) public stakeLists;
    mapping(address => bool) public hexStaking;
    mapping(address => bool) public allowHedron;

    constructor() ReentrancyGuard() {
        hexToken.approve(routerAddress, type(uint256).max);
    }

    function checkAndTransferHEX(uint256 _amount) private {
        require(hexToken.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function updateTotalStakeBalanceAndBonusMultiplier(bool start, uint256 _amount) private {
        if (start == true) {
          totalStakeBalance += _amount;
        } else {
          totalStakeBalance -= _amount;
        }

        if (totalStakeBalance >= 20000000000000000 ) {
          currentBonusMultiplier = 20;
        } else {
          currentBonusMultiplier = 40 - (totalStakeBalance / 1000000000000000);
        }
    }

    function stakeStart(uint256 _amount, uint256 _days) nonReentrant external {
        require(_amount >= minimumHex && _amount <= 4722366482869645213695);
        require(hexToken.stakeCount(address(this)) < type(uint256).max);

        checkAndTransferHEX(_amount);

        bool _mintState;

        if (totalMinted < 5000000e18) {
          require(_days == 7 || _days == 15 || _days == 30);
          uint256 _mintAmount;

          if (_days == 7) {
            _mintAmount = _amount * 1e10 / 514;
          } else if (_days == 15) {
            _mintAmount = _amount * 1e10 / 240;
          } else if (_days == 30) {
            _mintAmount = _amount * 1e10 / 120;
          }
          
          _mintState = true;

          if ((totalMinted + _mintAmount) <= 5000000e18) {
            totalMinted += _mintAmount;
          } else {
            _mintAmount = 5000000e18 - totalMinted;
            totalMinted = 5000000e18;
          }

          fairHexToken.transfer(msg.sender, _mintAmount);
        }

        hexToken.stakeStart(_amount, _days);
        updateTotalStakeBalanceAndBonusMultiplier(true, _amount);

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

        stakeLists[msg.sender][_uniqueID] = StakeStore(_stakeID, _amount, _stakeShares, _lockedDay, _stakedDays, uint16(0), true, false, currentBonusMultiplier, _mintState);

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

    function _stakeEnd(address _stakerAddress, uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID, uint256 _amountOutMin) private {
        uint16 _unlockedDay = _stakeSecurityCheck(_stakerAddress, _stakeIndex, _stakeIdParam, _uniqueID);
        uint16 _currentDay = uint16(hexToken.currentDay());

        if (_unlockedDay == 0) {
          stakeLists[_stakerAddress][_uniqueID].unlockedDay = _currentDay;
        } else {
          stakeLists[_stakerAddress][_uniqueID].unlockedDay = _unlockedDay;
        }

        uint256 _balance = hexToken.balanceOf(address(this));

        if (allowHedron[_stakerAddress] == true && _currentDay >= stakeLists[_stakerAddress][_uniqueID].lockedDay) {
            hedronToken.mintNative(_stakeIndex, _stakeIdParam);
            hedronToken.transfer(_stakerAddress, hedronToken.balanceOf(address(this)));
        }

        hexToken.stakeEnd(_stakeIndex, _stakeIdParam);
        stakeLists[_stakerAddress][_uniqueID].ended = true;

        uint256 _amount = hexToken.balanceOf(address(this)) - _balance;
        uint256 _stakedAmount = stakeLists[_stakerAddress][_uniqueID].hexAmount;
        uint256 _bonusDividend;

        if (stakeLists[_stakerAddress][_uniqueID].mintState && _currentDay < (stakeLists[_stakerAddress][_uniqueID].lockedDay + stakeLists[_stakerAddress][_uniqueID].stakedDays)) {
          require(false, "minters cannot end pending or early stakes");
        } else if (_currentDay < stakeLists[_stakerAddress][_uniqueID].lockedDay) {
          uint256 _pendingStakefee = _amount / 100;
          swapAndReceive(address(this), _pendingStakefee, _amountOutMin);
          _amount -=  _pendingStakefee;
          hexToken.transfer(_stakerAddress, _amount);
        } else if (_amount <= _stakedAmount || hexStaking[_stakerAddress] == true) {
          hexToken.transfer(_stakerAddress, _amount);
        } else if (_amount > _stakedAmount) {
          uint256 _bonusAmount;
          uint256 _difference = _amount - _stakedAmount;
          hexToken.transfer(_stakerAddress, _stakedAmount);
          _bonusDividend = swapAndReceive(_stakerAddress, _difference, _amountOutMin);
          _bonusAmount = _bonusDividend * stakeLists[_stakerAddress][_uniqueID].bonusMultiplier / 100;

          if (_bonusAmount > 0) {
            if (fairHexToken.balanceOf(address(this)) >= _bonusAmount) {
              fairHexToken.transfer(_stakerAddress, _bonusAmount);
            } else {
              fairHexToken.transfer(_stakerAddress, fairHexToken.balanceOf(address(this)));
            }
          }
        }

        updateTotalStakeBalanceAndBonusMultiplier(false, _stakedAmount);

        emit onStakeEnd(_stakerAddress, _uniqueID, _amount, _bonusDividend, block.timestamp);
    }

    function stakeEnd(uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID, uint256 _amountOutMin) nonReentrant external {
        _stakeEnd(msg.sender, _stakeIndex, _stakeIdParam, _uniqueID, _amountOutMin);
    }

    function swapAndReceive(address _receiver, uint256 _hex, uint256 _amountOutMin) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = hexAddress;
        path[1] = fairHexAddress;
        uint[] memory _amounts = router.swapExactTokensForTokens(_hex, _amountOutMin, path, address(this), block.timestamp);

        if (_amounts[1] > 0) {
          fairHexToken.transfer(_receiver, _amounts[1]);
        }

        return _amounts[1];
    }

    function revertToHexStaking() onlyCustodian external {
        normalStaking = true;
    }

    function toggleHexStaking() external {
        require (normalStaking == true);

        if (hexStaking[msg.sender] == false) {
          hexStaking[msg.sender] = true;
        } else {
          hexStaking[msg.sender] = false;
        }
    }

    function toggleHedron() external {
        if (allowHedron[msg.sender] == false) {
          allowHedron[msg.sender] = true;
        } else {
          allowHedron[msg.sender] = false;
        }
    }

    function reApproveContractForUniswap() external {
        hexToken.approve(routerAddress, type(uint256).max);
    }

    function setTokenAddress(address _proposedAddress) onlyCustodian external {
        require(finalizeAddress == false);
        fairHexAddress = _proposedAddress;
        fairHexToken = TOKEN1(fairHexAddress);
    }

    function finalizeTokenAddress() onlyCustodian external {
        finalizeAddress = true;
    }
}

/*

THE CONTRACT, SUPPORTING WEBSITES, AND ALL OTHER INTERFACES (THE SOFTWARE) IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

BY INTERACTING WITH THE SOFTWARE YOU ARE ASSERTING THAT YOU BEAR ALL THE RISKS ASSOCIATED WITH DOING SO. AN INFINITE NUMBER OF UNPREDICTABLE THINGS MAY GO WRONG WHICH COULD POTENTIALLY RESULT IN CRITICAL FAILURE AND FINANCIAL LOSS. BY INTERACTING WITH THE SOFTWARE YOU ARE ASSERTING THAT YOU AGREE THERE IS NO RECOURSE AVAILABLE AND YOU WILL NOT SEEK IT.

INTERACTING WITH THE SOFTWARE SHALL NOT BE CONSIDERED AN INVESTMENT OR A COMMON ENTERPRISE. INSTEAD, INTERACTING WITH THE SOFTWARE IS EQUIVALENT TO CARPOOLING WITH FRIENDS TO SAVE ON GAS AND EXPERIENCE THE BENEFITS OF THE H.O.V. LANE.

YOU SHALL HAVE NO EXPECTATION OF PROFIT OR ANY TYPE OF GAIN FROM THE WORK OF OTHER PEOPLE.

*/