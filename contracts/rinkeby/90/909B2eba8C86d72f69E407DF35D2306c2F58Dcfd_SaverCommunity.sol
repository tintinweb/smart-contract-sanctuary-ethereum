/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
// 0x617F2E2fD72FD9D5503197092aC168c91465E7f2

contract ERC20 is Context, IERC20, IERC20Metadata {
    // ERC20 Standard
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    // Tiempos (este lo puedes modificar para hacer testeos mas rapidos)
    uint256 public timeSaverReward = 30 days; // 30 days;
    uint256 public timeStableCoinReward = 30 minutes; // 1 days;

    // Saver
    uint256 public maxSupply = 369000000 * 10**18;
    uint256 public initialSupply = 3690000 * 10**18;

    // Saver Reward
    uint256 public saverAmountToClaim = 369 * 10**18;
    mapping(address => bool) public isListedToClaimSaver;
    mapping(address => uint256) public timestampToClaimSaver;
    mapping(address => uint256) public donationBalanceToClaimSaver;
    mapping(address => uint256) public cyclesOf;
    mapping(address => uint256) public successfulCyclesOf;

    // Stable Coin
    ERC20 BUSD = ERC20(0x9c11fa02E82c0Cab3f75f6A27A74a27EbA8D2384); //ERC20(0x2E50a44F2C744E2BcDe025028622d6349115D7Bf); // BUSD (BSC_TESTNET)
    ERC20 DAI = ERC20(0xad633abC01444d7ef21d67a6BCDdd5362f602AE4); //ERC20(0x3Fd5E2A42a4148295fc41D1250ba0D7CFf8dB36c); // DAI (BSC_TESTNET)

    // Stable Coin Reward
    uint256 public minAmountToQualify = 3 * 10**18;
    uint256 public rewardID = 1;
    uint256 public rewardIDonClaim;
    uint256 public totalStableCoinDistribute;

    mapping(uint256 => uint256) public rewardAmount; // rewardAmount[rewardID] => Amount Raised
    mapping(uint256 => uint256) public rewardAmountClaimed; // rewardAmount[rewardID] => Amount Claimed

    mapping(uint256 => uint256) public timeOpenClaimReward; // timeOpenClaimReward[rewardID] => timestamp

    mapping(address => mapping(uint256 => bool)) public holderClaimed; // holderClaimed[wallet][rewardID] => bool
   
    mapping(address => uint256) public stableCoinEarned;

    mapping(address => bool) public isQualified; // isQualified[wallet] => bool

    mapping(address => uint256) public claimFrom;

    // Donations
    uint256 public totalDonationBalance;
    uint256 public qualifiedDonationBalance;
    uint256 public totalDonations; // Agregarlo en la funcion de donacion
    mapping(address => uint256) public donationBalance;
    mapping(address => uint256) public allDonatesOf;

    // Holders
    uint256 public totalHolders;

    constructor(string memory name_, string memory symbol_) 
    {
        _name = name_;
        _symbol = symbol_;
        timeOpenClaimReward[rewardID] = block.timestamp + timeStableCoinReward;
    }

    // Saver Funcs
    function donateStableCoin(uint256 _amount) public 
    {
        require(BUSD.transferFrom(msg.sender, address(this), _amount), "You have to approve the transaction first");

        updateTimestampRewards();

        updateQualifiedDonationBalanceAfterDonate(msg.sender, _amount);

        checkSaverReward(msg.sender, _amount);
        
        rewardAmount[rewardID] += _amount;
        allDonatesOf[msg.sender] += _amount;
        claimFrom[msg.sender] = rewardID;
        totalDonations++;

    }

    function claim() public 
    {
        require(!holderClaimed[msg.sender][rewardIDonClaim], "You already claim your reward.");

        updateDonationBalance(msg.sender);

        require(rewardIDonClaim >= claimFrom[msg.sender], "You have to wait to the next reward to claim.");

        require(canReclaim(msg.sender), "You are not qualified to claim the reward");

        uint256 stableCoinToClaim = viewClaimStableCoin(msg.sender);

        require(stableCoinToClaim > 0, "You don't have any Stable Coin to claim.");
        require(BUSD.transfer(msg.sender, stableCoinToClaim), "Cannot pay StableCoin");

        updateDonationBalanceAfterClaim(msg.sender, stableCoinToClaim);

        rewardAmountClaimed[rewardIDonClaim] += stableCoinToClaim;
        holderClaimed[msg.sender][rewardIDonClaim] = true;
        totalStableCoinDistribute += stableCoinToClaim;
        stableCoinEarned[msg.sender] += stableCoinToClaim;

        updateTimestampRewards();
    }

    function claimSaver() public 
    {
        require(_totalSupply < maxSupply, "The total supply of SAVER is already minted.");
        updateDonationBalance(msg.sender);
        require(canReclaimSaver(msg.sender), "You are not qualified to claim SAVER.");
        require(timestampToClaimSaver[msg.sender] < block.timestamp, "You have to wait 90 days to claim your SAVER.");

        _mint(msg.sender, saverAmountToClaim);

        isListedToClaimSaver[msg.sender] = false;

        updateTimestampRewards();
    }

    // Funcs view Saver Token
    function viewClaimStableCoin(address wallet) public view returns(uint256) 
    {
        return( ( rewardAmount[rewardIDonClaim] * donationBalance[wallet] ) / qualifiedDonationBalance );
    }

    // Funciones que verifican por cada ERC20 si esta calificado

    function qualifiedForBDD(address wallet) public view returns(bool)
    {
        uint256 bddAmount = donationBalance[wallet];
        return (bddAmount >= minAmountToQualify);
    }

    function qualifiedForSAVER(address wallet) public view returns(bool)
    {
        uint256 saverAmount = _balances[wallet];
        uint256 bddAmount = donationBalance[wallet];

        return (saverAmount >= bddAmount);
    }

    function qualifiedForBUSD(address wallet) public view returns(bool)
    {
        uint256 busdAmount = BUSD.balanceOf(wallet);
        uint256 bddAmount = donationBalance[wallet];

        return (busdAmount >= bddAmount);
    }

    function qualifiedForDAI(address wallet) public view returns(bool)
    {
        uint256 daiAmount = DAI.balanceOf(wallet);
        uint256 bddAmount = donationBalance[wallet];

        return (daiAmount >= bddAmount);
    }

    // Esta funcion siempre te dira si un usuario puede o no reclamar el bote
    function canReclaim(address wallet) public view returns(bool) 
    {
        return (
            qualifiedForBDD(wallet) && qualifiedForBUSD(wallet) && qualifiedForDAI(wallet) 
            && qualifiedForSAVER(wallet)
        );
    }

    /// Funcion que indica si podemos o no reclamar el premio saver
    function canReclaimSaver(address wallet) public view returns(bool) 
    {
        uint256 bddAmount = donationBalanceToClaimSaver[wallet];

        return (
            bddAmount >= saverAmountToClaim && canReclaim(wallet) && isListedToClaimSaver[wallet]
        );
    }

    // Funciones para obtener los balances de todos los ERC20

    function getBalanceOfBUSD(address wallet) public view returns(uint256) 
    {
        return BUSD.balanceOf(wallet);
    }

    function getBalanceOfDAI(address wallet) public view returns(uint256)
    {
        return DAI.balanceOf(wallet);
    }

    function minOfMyTokens(address wallet) public view returns(uint256)
    {
        uint256 saverAmount = _balances[wallet];
        uint256 busdAmount = BUSD.balanceOf(wallet); 
        uint256 daiAmount = DAI.balanceOf(wallet);

        uint256 min = saverAmount;

        if (busdAmount < min) min = busdAmount;
        if (daiAmount < min) min = daiAmount;

        return min;
    }

    function updateDonationBalance(address wallet) public 
    {

        uint256 min = minOfMyTokens(wallet);

        if (donationBalance[wallet] > min) 
        {
            changeDonationBalance(wallet, min);
        }

    }

    function updateTimestampRewards() public 
    {

        if (block.timestamp > timeOpenClaimReward[rewardID]) 
        {
            // If someone forgot to claim, this reward will appear on the next reward
            rewardAmount[rewardID] += ( rewardAmount[rewardIDonClaim] - rewardAmountClaimed[rewardIDonClaim] );

            rewardIDonClaim = rewardID;
            rewardID++;
            
            // Update times to claim
            timeOpenClaimReward[rewardID] = block.timestamp + timeStableCoinReward;
        }
    }

    function updateALL() public
    {
        updateTimestampRewards();
        updateDonationBalance(msg.sender);
    }

// Private funcs

    function changeDonationBalance(address wallet, uint256 amount) private
    {
        uint256 difference = donationBalance[wallet] - amount; // (200 - 100) = 100
        donationBalance[wallet] = amount; // 100
        totalDonationBalance -= difference;
    }

    function updateQualifiedDonationBalanceAfterDonate(address wallet, uint256 amount) private 
    {
        if (canReclaim(wallet) && isQualified[wallet])
        {
            qualifiedDonationBalance -= donationBalance[wallet];
        }

        donationBalance[wallet] += amount;
        totalDonationBalance += amount;

        if (canReclaim(wallet)) 
        {
            qualifiedDonationBalance += donationBalance[wallet];
            isQualified[wallet] = true;
        }
    }

    function checkSaverReward(address wallet, uint256 amount) private 
    {
        if (isListedToClaimSaver[wallet]) 
        {
            donationBalanceToClaimSaver[wallet] += amount;
            return;
        }
            
        cyclesOf[wallet]++;
        timestampToClaimSaver[wallet] = block.timestamp + timeSaverReward;
        isListedToClaimSaver[wallet] = true;   
        donationBalanceToClaimSaver[wallet] = amount;
        
    }

    function updateDonationBalanceAfterClaim(address wallet, uint256 amount) private 
    {
        qualifiedDonationBalance -= donationBalance[wallet];

        donationBalance[wallet] -= (amount / 3);
        totalDonationBalance -= (amount / 3);

        if (canReclaim(wallet))
        {
            qualifiedDonationBalance += donationBalance[wallet];
        }
        else
        {
            isQualified[wallet] = false;
        }
    }

    function updateQualifiedDonationBalancesAfterTransfer(address wallet) private
    {
        if (!canReclaim(wallet) && isQualified[wallet])
        {
            qualifiedDonationBalance -= donationBalance[wallet];
            isQualified[wallet] = false;
        }

        updateDonationBalance(wallet);

        if (canReclaim(wallet) && !isQualified[wallet])
        {
            qualifiedDonationBalance += donationBalance[wallet];
            isQualified[wallet] = true;
        }
    }

    function updateQualifiedDonationBalancesBeforeClaim(address wallet) private 
    {
        if (canReclaim(wallet) && !isQualified[wallet]) 
        {
            qualifiedDonationBalance += donationBalance[wallet];
            isQualified[wallet] = true;
        }

        if (!canReclaim(wallet) && isQualified[wallet])
        {
            qualifiedDonationBalance -= donationBalance[wallet];
            isQualified[wallet] = false;
        }
    }

    // Funcs Private view

    // Funcs IERC20

    function name() public view virtual override returns (string memory) 
    {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) 
    {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) 
    {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) 
    {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) 
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) 
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) 
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) 
    {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) 
    {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) 
    {
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
    ) internal virtual 
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        if (_balances[to] == 0) {
            totalHolders += 1;
        }

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        updateQualifiedDonationBalancesAfterTransfer(from);
        updateQualifiedDonationBalancesAfterTransfer(to);

        updateTimestampRewards();

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual 
    {
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
    ) internal virtual 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual 
    {
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

contract SaverCommunity is ERC20 {
    constructor() ERC20("Saver Community BSC", "SAVER1") {
        _mint(msg.sender, initialSupply);
        totalHolders++;
    }
}