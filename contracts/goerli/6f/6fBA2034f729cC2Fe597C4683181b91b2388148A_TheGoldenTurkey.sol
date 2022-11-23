/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ItokenContract {
    function balanceOf(address account) external view returns (uint256);
}

struct dog {
    uint id;
    bool exists;
    uint timeCreated;
    address owner;
    uint nextAvailableAttackDeadline;
    string name;
}

struct turkey {
    uint id;
    bool exists;
    uint timeCreated;
    address owner;
    uint shieldActivationEnd;
    string name;
}

struct shield {
    uint id;
    bool exists;
    uint timeCreated;
    address owner;
    bool used;
}

struct steak {
    uint id;
    bool exists;
    uint timeCreated;
    address owner;
    bool used;
}

struct attack {
    uint id;
    bool exists;
    uint timeCreated;
    address attacker;
    uint dogAttacker;
    address target;
    uint turkeyTarget;
}

struct buyer {
    uint id; 
    bool exists;
    address user;
    uint deadlineForNextReclaim;
}

contract TheGoldenTurkey is ERC20, Ownable {
    using SafeMath for uint256;
    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    ItokenContract turkeyContract;

    string constant _name = "The Golden Turkey";
    string constant _symbol = "TURKEY";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100_000_000_000 * (10 ** _decimals);
    uint256 public _maxWalletAmount = (_totalSupply * 100) / 100;

    uint public nextDog = 1;
    uint public nextTurkey = 1;
    uint public nextShield = 1;
    uint public nextSteak = 1;
    uint public nextAttack = 1;
    uint public nextBuyer = 1;

    uint minimumBalanceForOneTurkey = 100000000000000000;
    uint minimumBalanceForOneDog = 200000000000000000;
    uint minimumBalanceForOneSteak = 300000000000000000;
    uint minimumBalanceForOneShield = 300000000000000000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    mapping (uint256 => dog) public Dogs;
    mapping (uint256 => turkey) public Turkeys;
    mapping (uint256 => shield) public Shields;
    mapping (uint256 => steak) public Steaks;
    mapping (uint256 => attack) public Attacks;
    mapping (address => buyer) public Buyers;

    //mapping (address => attack[]) public AttacksByAddress;
    //mapping (address => attack[]) public AttackedByAddress;

    uint256 liquidityFee = 0; 
    uint256 goldenTurkeyFees = 5;
    uint256 totalFee = liquidityFee + goldenTurkeyFees;
    uint256 feeDenominator = 100;

    address public goldenTurkeyFeeReceiver = 0xAacea4Fb9615e80A6CcE2968CF0D290953e47394;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 5; // 0.5%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[0xAacea4Fb9615e80A6CcE2968CF0D290953e47394] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[0xAacea4Fb9615e80A6CcE2968CF0D290953e47394] = true;
        isTxLimitExempt[DEAD] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);

        turkeyContract = ItokenContract(address(this));
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack()){ swapBack(); } 

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(goldenTurkeyFees).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(goldenTurkeyFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                0xAacea4Fb9615e80A6CcE2968CF0D290953e47394,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function clearStuckBalance() external {
        payable(goldenTurkeyFeeReceiver).transfer(address(this).balance);
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent ) / 1000;
    }

    function setFee(uint256 _liquidityFee, uint256 _goldenTurkeyFee) external onlyOwner {
         liquidityFee = _liquidityFee; 
         goldenTurkeyFees = _goldenTurkeyFee;
         totalFee = liquidityFee + goldenTurkeyFees;
    }    
    
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);

    /////////////////////////////////////// Golden Turkey Functions //////////////////////////////////

    function getResources() external {

        address recipient = msg.sender;

        // Turkeys 
        //uint amountOfTurkeysUserShouldHave = getAmountOfTurkeysUserShouldHave(recipient);
        //uint amountOfTurkeysUserHas = getNumberOfPlayerTurkeys(recipient);
        //uint amountOfTurkeysUserHasLost = getNumberOfTimesPlayerHasBeenAttacked(recipient);

        uint amountOfTurkeysToGet = getAmountOfTurkeysUserShouldHave(recipient) - getNumberOfPlayerTurkeys(recipient) - getNumberOfTimesPlayerHasBeenAttacked(recipient);

        // Dogs
        //uint amountOfDogsUserShouldHave = getAmountOfDogsUserShouldHave(recipient);
        //uint amountOfDogsUserHas = getNumberOfPlayerDogs(recipient);

        uint amountOfDogsToGet = getAmountOfDogsUserShouldHave(recipient) - getNumberOfPlayerDogs(recipient);

        // Steaks
        //uint amountOfSteaksUserShouldHave = getAmountOfSteaksUserShouldHave(recipient);
        //uint amountOfSteaksUserHas = getNumberOfSteaksUserHas(recipient);

        uint amountOfSteakToGet = getAmountOfSteaksUserShouldHave(recipient) - getNumberOfSteaksUserHas(recipient);

        // Shields
        //uint amountOfShieldsUserShouldHave = getAmountOfShieldsUserShouldHave(recipient);
        //uint amountOfShieldsUserHas = getNumberOfShieldsUserHas(recipient);

        uint amountOfShieldsToGet = getAmountOfShieldsUserShouldHave(recipient) - getNumberOfShieldsUserHas(recipient);

        // Get Turkeys
        for (uint i = 0; i < amountOfTurkeysToGet + 1; i++) {
            turkey storage newTurkey = Turkeys[nextTurkey];
            newTurkey.id = nextTurkey;
            newTurkey.exists = true;
            newTurkey.timeCreated = block.timestamp;
            newTurkey.owner = recipient;
            newTurkey.name = "Turkey";

            nextTurkey++;
        }

        // Get Dogs
        for (uint i = 0; i < amountOfDogsToGet + 1; i++) {
            dog storage newDog = Dogs[nextDog];
            newDog.id = nextDog;
            newDog.exists = true;
            newDog.timeCreated = block.timestamp;
            newDog.owner = recipient;
            newDog.name = "Shiba Inu";

            nextDog++;
        }

        // Get Steaks
        for (uint i = 0; i < amountOfSteakToGet + 1; i++) {
            steak storage newSteak = Steaks[nextSteak];
            newSteak.id = nextSteak;
            newSteak.exists = true;
            newSteak.timeCreated = block.timestamp;
            newSteak.owner = recipient;

            nextSteak++;
        }

        // Get Shields
        for (uint i = 0; i < amountOfShieldsToGet + 1; i++) {
            shield storage newShield = Shields[nextShield];
            newShield.id = nextShield;
            newShield.exists = true;
            newShield.timeCreated = block.timestamp;
            newShield.owner = recipient;

            nextShield++;
        }

        buyer storage holder = Buyers[recipient];
        holder.deadlineForNextReclaim = holder.deadlineForNextReclaim + (2 * 1 hours);
    }

    function activateShieldForTurkey (uint turkeyId, uint shieldId) external {
        turkey storage shieldedTurkey = Turkeys[turkeyId];
        shield storage shielderShield = Shields[shieldId];
        require (shielderShield.used == false, "Shield already used sir.");
        require (block.timestamp > shieldedTurkey.shieldActivationEnd, "Turkey already protected");

        shieldedTurkey.shieldActivationEnd = block.timestamp + (3 * 1 hours);
        shielderShield.used = true;
    }

    function giveSteakToDog (uint dogId, uint steakId) external {
        dog storage goodBoy = Dogs[dogId];
        steak storage goodSteak = Steaks[steakId];
        require (goodSteak.used == false, "Steak already eaten");

        goodBoy.nextAvailableAttackDeadline = block.timestamp;
        goodSteak.used = true;
    }

    function attackTurkey (uint turkeyId, uint dogId) external {
        turkey storage attackedTurkey = Turkeys[turkeyId];
        dog storage attackerDog = Dogs[dogId];
        require (block.timestamp > attackedTurkey.shieldActivationEnd, "Turkey has a shield protecting him");
        require (block.timestamp > attackerDog.nextAvailableAttackDeadline, "Dog just attacked, he is tired");

        attack storage newAttack = Attacks[nextAttack];
        newAttack.id = nextAttack;
        newAttack.exists = true;
        newAttack.timeCreated = block.timestamp;
        newAttack.attacker = msg.sender;
        newAttack.dogAttacker = dogId;
        newAttack.target = attackedTurkey.owner;
        newAttack.turkeyTarget = turkeyId;

        nextAttack++;

        attackedTurkey.owner = msg.sender;
    }

    function changeTurkeyName (uint turkeyId, string memory newName) external {
        turkey storage userTurkey = Turkeys[turkeyId];
        require (msg.sender == userTurkey.owner, "You're not the owner of the turkey");

        userTurkey.name = newName;
    }

     function changeDogName (uint dogId, string memory newName) external {
        dog storage userDog = Dogs[dogId];
        require (msg.sender == userDog.owner, "You're not the owner of the turkey");

        userDog.name = newName;
    }

    function changeMinimumBalanceForOneTurkey(uint newBalance) external onlyOwner {
        minimumBalanceForOneTurkey = newBalance;
    }

    function changeMinimumBalanceForOneDog(uint newBalance) external onlyOwner {
        minimumBalanceForOneDog = newBalance;
    }

    function changeMinimumBalanceForOneSteak(uint newBalance) external onlyOwner {
        minimumBalanceForOneSteak = newBalance;
    }

    function changeMinimumBalanceForOneShield(uint newBalance) external onlyOwner {
        minimumBalanceForOneShield = newBalance;
    }

    function getAmountOfTurkeysUserShouldHave(address player) public view returns (uint) {
        uint amountOfTokens = turkeyContract.balanceOf(player);
        uint amountOfTurkeysUserShouldHave = amountOfTokens / minimumBalanceForOneTurkey;

        return amountOfTurkeysUserShouldHave;
    }

    function getAmountOfDogsUserShouldHave(address player) public view returns (uint) {
        uint amountOfTokens = turkeyContract.balanceOf(player);
        uint amountOfDogsUserShouldHave = amountOfTokens / minimumBalanceForOneDog;

        return amountOfDogsUserShouldHave;
    }

    function getAmountOfSteaksUserShouldHave(address player) public view returns (uint) {
        uint amountOfTokens = turkeyContract.balanceOf(player);
        uint amountOfSteaksUserShouldHave = amountOfTokens / minimumBalanceForOneSteak;

        return amountOfSteaksUserShouldHave;
    }

    function getUserSteaks(address player) public view returns (steak[] memory filteredSteaks) {
        steak[] memory steaksTemp = new steak[](nextSteak - 1);
        uint count;
        for (uint i = 0; i < (nextShield - 1); i++) {
            if (Steaks[i].owner == player && Steaks[i].used == false) {
                steaksTemp[count] = Steaks[i];
                count++;
            }
        }

        filteredSteaks = new steak[](count);
        for (uint i = 0; i < count; i++) {
            filteredSteaks[i] = steaksTemp[i];
        }

        return filteredSteaks;
    }

    function getNumberOfSteaksUserHas(address player) public view returns (uint) {
        steak[] memory steaks = getUserSteaks(player);
        return steaks.length;
    }

    function getAmountOfShieldsUserShouldHave(address player) public view returns (uint) {
        uint amountOfTokens = turkeyContract.balanceOf(player);
        uint amountOfShieldsUserShouldHave = amountOfTokens / minimumBalanceForOneShield;

        return amountOfShieldsUserShouldHave;
    }

    function getUserShields(address player) public view returns (shield[] memory filteredShields) {
        shield[] memory shieldsTemp = new shield[](nextShield - 1);
        uint count;
        for (uint i = 0; i < (nextShield- 1); i++) {
            if (Shields[i].owner == player && Shields[i].used == false) {
                shieldsTemp[count] = Shields[i];
                count++;
            }
        }

        filteredShields = new shield[](count);
        for (uint i = 0; i < count; i++) {
            filteredShields[i] = shieldsTemp[i];
        }

        return filteredShields;
    }

    function getNumberOfShieldsUserHas(address player) public view returns (uint) {
        shield[] memory shields = getUserShields(player);
        return shields.length;
    }

    function getTimesPlayerHasBeenAttacked(address player) public view returns (attack[] memory filteredAttacks) {
        attack[] memory attacksTemp = new attack[](nextAttack - 1);
        uint count;
        for (uint i = 0; i < (nextAttack - 1); i++) {
            if (Attacks[i].target == player) {
                attacksTemp[count] = Attacks[i];
                count++;
            }
        }

        filteredAttacks = new attack[](count);
        for (uint i = 0; i < count; i++) {
            filteredAttacks[i] = attacksTemp[i];
        }

        return filteredAttacks;
    }

    function getNumberOfTimesPlayerHasBeenAttacked(address player) public view returns (uint) {
        attack[] memory attacks = getTimesPlayerHasBeenAttacked(player);
        return attacks.length;
    }

    function getTimesPlayerHasAttacked(address player) public view returns (attack[] memory filteredAttacks) {
        attack[] memory attacksTemp = new attack[](nextAttack - 1);
        uint count;
        for (uint i = 0; i < (nextAttack - 1); i++) {
            if (Attacks[i].attacker == player) {
                attacksTemp[count] = Attacks[i];
                count++;
            }
        }

        filteredAttacks = new attack[](count);
        for (uint i = 0; i < count; i++) {
            filteredAttacks[i] = attacksTemp[i];
        }

        return filteredAttacks;
    }

    function getNumberOfTimesPlayerHasAttacked(address player) public view returns (uint) {
        attack[] memory attacks = getTimesPlayerHasAttacked(player);
        return attacks.length;
    }

    function getPlayerTurkeys(address player) public view returns (turkey[] memory filteredTurkeys) {
        turkey[] memory turkeysTemp = new turkey[](nextTurkey - 1);
        uint count;
        for (uint i = 0; i < (nextTurkey -1); i++) {
            if (Turkeys[i].owner == player) {
                turkeysTemp[count] = Turkeys[i];
                count++;
            }
        }

        filteredTurkeys = new turkey[](count);
        for (uint i = 0; i < count; i++) {
            filteredTurkeys[i] = turkeysTemp[i];
        }

        return filteredTurkeys;
    }

    function getNumberOfPlayerTurkeys(address player) public view returns (uint) {
        turkey[] memory turkeys = getPlayerTurkeys(player);
        return turkeys.length;
    }

    function getPlayerDogs(address player) public view returns (dog[] memory filteredDogs) {
        dog[] memory dogsTemp = new dog[](nextDog - 1);
        uint count;
        for (uint i = 0; i < (nextDog -1); i++) {
            if (Dogs[i].owner == player) {
                dogsTemp[count] = Dogs[i];
                count++;
            }
        }

        filteredDogs = new dog[](count);
        for (uint i = 0; i < count; i++) {
            filteredDogs[i] = dogsTemp[i];
        }

        return filteredDogs;
    }

    function getNumberOfPlayerDogs(address player) public view returns (uint) {
        dog[] memory dogs = getPlayerDogs(player);
        return dogs.length;
    }

}