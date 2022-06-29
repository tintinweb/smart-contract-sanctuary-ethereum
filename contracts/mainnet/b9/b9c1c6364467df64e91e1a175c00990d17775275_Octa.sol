/**
 *Submitted for verification at Etherscan.io on 2022-06-28
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract HedronToken {
    function approve(address spender, uint256 amount) external returns (bool) {}
    function transfer(address recipient, uint256 amount) external returns (bool) {}
    function mintNative(uint256 stakeIndex, uint40 stakeId) external returns (uint256) {}
    function claimNative(uint256 stakeIndex, uint40 stakeId) external returns (uint256) {}
    function currentDay() external view returns (uint256) {}
}

contract HEXToken {
    function currentDay() external view returns (uint256){}
    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external {}
    function approve(address spender, uint256 amount) external returns (bool) {}
    function transfer(address recipient, uint256 amount) public returns (bool) {}
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) public {}
    function stakeCount(address stakerAddr) external view returns (uint256) {}
}

contract Octa is ERC20, ERC20Burnable, ReentrancyGuard {
    modifier onlyCustodian() {
        require(msg.sender == CUSTODIAN);
      _;
    }

    uint256 MINTING_PHASE_START;
    uint256 MINTING_PHASE_END;
    uint256 STAKE_START_DAY;
    uint256 STAKE_END_DAY;
    uint256 STAKE_LENGTH;
    uint256 HEX_REDEMPTION_RATE;
    uint256 HEDRON_REDEMPTION_RATE;
    bool HAS_STAKE_STARTED;
    bool HAS_STAKE_ENDED;
    bool HAS_HEDRON_MINTED;
    address END_STAKER;
    uint256 public TOTAL_ENTRIES;

    constructor(uint256 mint_duration, uint256 stake_duration) ERC20("Octa", "OCTA") ReentrancyGuard() {
        uint256 start_day=hex_token.currentDay();
        MINTING_PHASE_START = start_day;
        MINTING_PHASE_END = start_day+mint_duration;
        STAKE_LENGTH=stake_duration;
        HAS_STAKE_STARTED=false;
        HAS_STAKE_ENDED = false;
        HAS_HEDRON_MINTED=false;
        HEX_REDEMPTION_RATE=1000000000000;
        HEDRON_REDEMPTION_RATE=0;
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
	  }

    address OCTA_ADDRESS = address(this);
    address constant OCTA_STAKE_ADDRESS = 0x04D6c50d54015450ce2d7Fe4b1010Df3cE69930F;
    address constant HEX_ADDRESS = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    address constant HEDRON_ADDRESS= 0x3819f64f282bf135d62168C1e513280dAF905e06;
    address constant CUSTODIAN = 0xf989A6939f5fC6d85118E912aB28a699EBdEa9Ce;

    IERC20 hex_contract = IERC20(HEX_ADDRESS);
    IERC20 hedron_contract=IERC20(HEDRON_ADDRESS);
    HEXToken hex_token = HEXToken(HEX_ADDRESS);
    HedronToken hedron_token = HedronToken(HEDRON_ADDRESS);

    function getMintingPhaseStartDay() external view returns (uint256) {return MINTING_PHASE_START;}
    function getMintingPhaseEndDay() external view returns (uint256) {return MINTING_PHASE_END;}
    function getStakeStartDay() external view returns (uint256) {return STAKE_START_DAY;}
    function getStakeEndDay() external view returns (uint256) {return STAKE_END_DAY;}
    function getHEXRedemptionRate() external view returns (uint256) {return HEX_REDEMPTION_RATE;}
    function getHedronRedemptionRate() external view returns (uint256) {return HEDRON_REDEMPTION_RATE;}

    function getHexDay() external view returns (uint256){
        uint256 day = hex_token.currentDay();
        return day;
    }

    function getHedronDay() external view returns (uint day) {return hedron_token.currentDay();}
    function getEndStaker() external view returns (address end_staker_address) {return END_STAKER;}

    function mint(uint256 amount) private {
        _mint(msg.sender, amount);
    }

    function pledgeHEX(uint256 amount) nonReentrant external {
        require(hex_token.currentDay()<=MINTING_PHASE_END, "Minting Phase is Done");
        require(hex_contract.allowance(msg.sender, OCTA_ADDRESS)>=amount, "Please approve contract address as allowed spender in the hex contract.");
        address from = msg.sender;
        hex_contract.transferFrom(from, OCTA_ADDRESS, amount);
        mint(amount/10000);
        TOTAL_ENTRIES++;
    }

    function redeemHEX(uint256 amount_OCTA) nonReentrant external {
        require(HAS_STAKE_STARTED==false || HAS_STAKE_ENDED==true , "Redemption can only happen before stake starts or after stake ends.");
        uint256 yourOCTA = balanceOf(msg.sender);
        require(yourOCTA>=amount_OCTA, "You do not have that much OCTA.");
        uint256 raw_redeemable_amount;

        if (HAS_STAKE_STARTED==false) {
            raw_redeemable_amount = amount_OCTA*HEX_REDEMPTION_RATE;
        } else if (HAS_STAKE_ENDED==true) {
            uint256 hex_balance = hex_contract.balanceOf(address(this));
            uint256 total_redeemable_octa = IERC20(address(this)).totalSupply() - IERC20(address(this)).balanceOf(OCTA_STAKE_ADDRESS);
            HEX_REDEMPTION_RATE  = calculate_redemption_rate(hex_balance, total_redeemable_octa);
            raw_redeemable_amount = amount_OCTA*HEX_REDEMPTION_RATE;
        }

        uint256 redeemable_amount = raw_redeemable_amount/100000000;
        hex_token.transfer(msg.sender, redeemable_amount);

        if (HAS_HEDRON_MINTED==true) {
            uint256 total_hedron= hedron_contract.balanceOf(address(this));
            uint256 total_redeemable_octa = IERC20(address(this)).totalSupply() - IERC20(address(this)).balanceOf(OCTA_STAKE_ADDRESS);
            HEDRON_REDEMPTION_RATE = calculate_redemption_rate(total_hedron, total_redeemable_octa);
            uint256 raw_redeemable_hedron = amount_OCTA*HEDRON_REDEMPTION_RATE;
            uint256 redeemable_hedron = raw_redeemable_hedron/100000000;
            hedron_token.transfer(msg.sender, redeemable_hedron);
        }

        burn(amount_OCTA);
    }

    function stakeHEX() nonReentrant external {
        require(HAS_STAKE_STARTED==false, "Stake has already been started.");
        uint256 current_day = hex_token.currentDay();
        require(current_day>MINTING_PHASE_END, "Minting Phase is still ongoing - see MINTING_PHASE_END day.");
        uint256 amount = hex_contract.balanceOf(address(this));
        _stakeHEX(amount);
        _mint(OCTA_STAKE_ADDRESS, IERC20(address(this)).totalSupply());
        HAS_STAKE_STARTED=true;
        STAKE_START_DAY=current_day;
        STAKE_END_DAY=current_day+STAKE_LENGTH;
    }

    function _stakeHEX(uint256 amount) private  {
        hex_token.stakeStart(amount,STAKE_LENGTH);
    }

    function _endStakeHEX(uint256 stakeIndex,uint40 stakeIdParam ) private  {
        hex_token.stakeEnd(stakeIndex, stakeIdParam);
    }

    function endStakeHEX(uint256 stakeIndex,uint40 stakeIdParam) nonReentrant external {
        require(hex_token.currentDay()>STAKE_END_DAY, "Stake is not complete yet.");
        require(HAS_STAKE_STARTED==true && HAS_STAKE_ENDED==false, "Stake has already been started.");
        _endStakeHEX(stakeIndex, stakeIdParam);
        HAS_STAKE_ENDED=true;
        END_STAKER=msg.sender;
    }

    function calculate_redemption_rate(uint treasury_balance, uint octa_supply) private pure returns (uint redemption_rate) {
        uint256 scalar = 10**8;
        uint256 scaled = (treasury_balance * scalar) / octa_supply;
        return scaled;
    }

    function mintHedron(uint256 stakeIndex,uint40 stakeId) external  {
        _mintHedron(stakeIndex, stakeId);
    }

    function _mintHedron(uint256 stakeIndex,uint40 stakeId) private  {
        hedron_token.mintNative(stakeIndex, stakeId);
    }

    function allowHedron(bool state) onlyCustodian external {
        HAS_HEDRON_MINTED = state;
    }
}