// SPDX-License-Identifier: MIT
// requires compiler ver of 0.8.1 or higher to recognize imports
pragma solidity =0.8.1;
pragma experimental ABIEncoderV2;

// the most recent ^0.8.0 compatible SafeMath library is implmented to preserve existing logic reliant upon SafeMath syntax.
// erc20 + erc20 snapshot imports to utilize the shapshot functionality to pull balances at any time. Ownable for modifier function call control.
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IPYE.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IPYESwapFactory.sol";
import "./interfaces/IPYESwapPair.sol";
import "./interfaces/IPYESwapRouter.sol";
import "./interfaces/IMoonshotMechanism.sol";
import "./interfaces/IStakingContract.sol";
import "./MoonshotMechanism.sol";

contract MoonFORCE is IPYE, Context, ERC20, ERC20Snapshot, Ownable {

    // allows easy determination of actual msg.sender in meta-transactions
    using Address for address;
    // declare SafeMath useage so compiler recognizes SafeMath syntax
    using SafeMath for uint256;

//--------------------------------------BEGIN FEE INFO---------|

     // Fees
    struct Fees {
        uint256 reflectionFee;
        uint256 marketingFee;
        uint256 moonshotFee;
        uint256 buybackFee;
        uint256 liquifyFee;
        address marketingAddress;
        address liquifyAddress;
    }

    // Transaction fee values
    struct FeeValues {
        uint256 transferAmount;
        uint256 reflection;
        uint256 marketing;
        uint256 moonshots;
        uint256 buyBack;
        uint256 liquify;
    }

    // instantiating new Fees structs (see struct Fees above)
    Fees public _defaultFees;
    Fees public _defaultSellFees;
    Fees private _previousFees;
    Fees private _emptyFees;
    Fees private _sellFees;
    Fees private _outsideBuyFees;
    Fees private _outsideSellFees;

//--------------------------------------BEGIN MAPPINGS---------|

    // user mappings for token balances and spending allowances. 
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    // user states governing fee exclusion, blacklist status, Reward exempt (meaning no reflection entitlement)
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isBlacklisted;

    // Pair Details
    mapping (uint256 => address) private pairs;
    mapping (uint256 => address) private tokens;
    uint256 private pairsLength;
    mapping (address => bool) public _isPairAddress;
    // Outside Swap Pairs
    mapping (address => bool) private _includeSwapFee;
    // Staking Contracts
    mapping (address => bool) isStakingContract;

//--------------------------------------BEGIN TOKEN PARAMS---------|

    // token details.
    // tTotal is the total token supply (10 bil with 9 decimals)
    string constant _name = "MoonForce";
    string constant _symbol = "FORCE";
    uint8 constant _decimals = 9;
    uint256 private constant _tTotal = 10 * 10**9 * 10**9;


//--------------------------------------BEGIN TOKEN HOLDER INFO---------|

    struct Staked {
        uint256 amount;
    }

    address[] holders;
    mapping (address => uint256) holderIndexes;
    mapping (address => Staked) public staked;

    uint256 public totalStaked;

//--------------------------------------BEGIN ROUTER, WETH, BURN ADDRESS INFO---------|

    IPYESwapRouter public pyeSwapRouter;
    address public pyeSwapPair;
    address public WETH;
    address public constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmount = 5 * 10**8 * 10**9;

//--------------------------------------BEGIN BUYBACK VARIABLES---------|

    // auto set buyback to false. additional buyback params. blockPeriod acts as a time delay in the shouldAutoBuyback(). Last uint represents last block for buyback occurance.
    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;
    uint256 minimumBuyBackThreshold = _tTotal / 1000000; // 0.0001%

//--------------------------------------BEGIN MOONSHOT MECH. AND STAKING CONT. INSTANCES---------|

    // instantiate a moonshot from the Moonshot Mechanism contract, which handles moonshot generation and disbursal value logic.
    MoonshotMechanism moonshot;
    address public moonshotAddress;

    IStakingContract public StakingContract;
    address public stakingContract;

    uint256 distributorGas = 500000;

//--------------------------------------BEGIN SWAP INFO---------|

    // swap state variables
    bool inSwap;

    // function modifiers handling swap status
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier onlyExchange() {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == msg.sender) isPair = true;
        }
        require(
            msg.sender == address(pyeSwapRouter)
            || isPair
            , "PYE: NOT_ALLOWED"
        );
        _;
    }

//--------------------------------------BEGIN CONSTRUCTOR AND RECEIVE FUNCITON---------|    

    constructor() ERC20("MoonForce", "FORCE") {
        _balances[_msgSender()] = _tTotal;

        pyeSwapRouter = IPYESwapRouter(0x4F71E29C3D5934A15308005B19Ca263061E99616);
        WETH = pyeSwapRouter.WETH();
        pyeSwapPair = IPYESwapFactory(pyeSwapRouter.factory())
        .createPair(address(this), WETH, true);

        moonshot = new MoonshotMechanism();
        moonshotAddress = address(moonshot);

        tokens[pairsLength] = WETH;
        pairs[pairsLength] = pyeSwapPair;
        pairsLength += 1;
        _isPairAddress[pyeSwapPair] = true;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[pyeSwapPair] = true;
        _isExcludedFromFee[moonshotAddress] = true;
        _isExcludedFromFee[stakingContract] = true;

        isTxLimitExempt[_msgSender()] = true;
        isTxLimitExempt[pyeSwapPair] = true;
        isTxLimitExempt[address(pyeSwapRouter)] = true;
        isTxLimitExempt[moonshotAddress] = true;
        isTxLimitExempt[stakingContract] = true;

        _defaultFees = Fees(
            800,
            300,
            200,
            100,
            0,
            0xdfc2aeD317d8ef2bC90183FD0e365BFE190bFCBD,
            0x8539a0c8D96610527140E97A9ae458F6A5bb1F86
        );

        _defaultSellFees = Fees(
            800,
            300,
            200,
            100,
            0,
            0xdfc2aeD317d8ef2bC90183FD0e365BFE190bFCBD,
            0x8539a0c8D96610527140E97A9ae458F6A5bb1F86
        );

        _sellFees = Fees(
            0,
            0,
            0,
            0,
            0,
            0xdfc2aeD317d8ef2bC90183FD0e365BFE190bFCBD,
            0x8539a0c8D96610527140E97A9ae458F6A5bb1F86
        );

        _outsideBuyFees = Fees(
            800,
            300,
            200,
            100,
            0,
            0xdfc2aeD317d8ef2bC90183FD0e365BFE190bFCBD,
            0x8539a0c8D96610527140E97A9ae458F6A5bb1F86
        );

        _outsideSellFees = Fees(
            800,
            300,
            200,
            100,
            0,
            0xdfc2aeD317d8ef2bC90183FD0e365BFE190bFCBD,
            0x8539a0c8D96610527140E97A9ae458F6A5bb1F86
        );

        IPYESwapPair(pyeSwapPair).updateTotalFee(1400);
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    //to receive ETH from pyeRouter when swapping
    receive() external payable {}

//--------------------------------------BEGIN SNAPSHOT FUNCTIONS---------|

    // this function generates a snapshot of the total token supply as well as the balances of all the holders. This is accomplished
    // by the mapping in the ERC20 snapshot contract which links an address to an individual snapshot balance which can be called arbitrarily any time. Calling
    // snapshot() also generates a snapshot ID (a uint) which can be used in the balanceOfAt() fxn in combination with any holder address to get a holders balance at
    // the time the entered shapshotID was generated (i.e. historic balance functionality) 
    function snapshot() public onlyOwner {
        _snapshot();
    }

    // simple getter function which returns the number (or ID) of the most recent snapshot taken. Useful to call if attempting to use totalSupplyAt() or balanceOfAt() and you 
    // need to know what the last snapshot ID is to pass it as an argument.
    function getCurrentSnapshot() public view onlyOwner returns (uint256) {
        return _getCurrentSnapshotId();
    }

    // the original totalSupplyAt() function in ERC20-snapshot only uses totalSupply (in our case, _tTotal) to determine the total supply at a given snapshot. As a result,
    // it won't reflect the token balances of the burn wallet, ..
    function totalSupplyAt(uint256 snapshotId) public view onlyOwner override returns (uint256) {
        return super.totalSupplyAt(snapshotId).sub(balanceOfAt(_burnAddress, snapshotId));
    }

    // The following functions are overrides required by Solidity. "super" provides access directly to the beforeTokenTransfer fxn in ERC20 snapshot. Update balance 
    // and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

//--------------------------------------BEGIN BLACKLIST FUNCTIONS---------|

    // enter an address to blacklist it. This blocks transfers TO that address. Balcklisted members can still sell.
    function blacklistAddress(address addressToBlacklist) public onlyOwner {
        require(!isBlacklisted[addressToBlacklist] , "Address is already blacklisted!");
        isBlacklisted[addressToBlacklist] = true;
    }

    // enter a currently blacklisted address to un-blacklist it.
    function removeFromBlacklist(address addressToRemove) public onlyOwner {
        require(isBlacklisted[addressToRemove] , "Address has not been blacklisted! Enter an address that is on the blacklist.");
        isBlacklisted[addressToRemove] = false;
    }

//--------------------------------------BEGIN TOKEN GETTER FUNCTIONS---------|

    // decimal return fxn is explicitly stated to override the std. ERC-20 decimals() fxn which is programmed to return uint 18, but
    // MoonForce has 9 decimals.
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    // totalSupply return fxn is explicitly stated to override the std. ERC-20 totalSupply() fxn which is programmed to return a uint "totalSupply", but
    // MoonForce uses "_tTotal" variable to define total token supply, 
    function totalSupply() public pure override(ERC20, IPYE) returns (uint256) {
        return _tTotal;
    }

    // balanceOf function is identical to ERC-20 balanceOf fxn.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // returns the owned amount of tokens, including tokens that are staked in main pool. Balance qualifies for tier privileges.
    function getOwnedBalance(address account) public view returns (uint256){
        return staked[account].amount.add(_balances[account]);
    }

    // returns the circulating token supply minus the balance in the burn address (0x00..dEAD) and the balance in address(0) (0x00...00)
    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(_burnAddress)).sub(balanceOf(address(0)));
    }

//--------------------------------------BEGIN TOKEN PAIR FUNCTIONS---------|

    // returns the index of paired tokens
    function _getTokenIndex(address _token) internal view returns (uint256) {
        uint256 index = pairsLength + 1;
        for(uint256 i = 0; i < pairsLength; i++) {
            if(tokens[i] == _token) index = i;
        }

        return index;
    }

    // check if a pair of tokens are paired
    function _checkPairRegistered(address _pair) internal view returns (bool) {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == _pair) isPair = true;
        }

        return isPair;
    }

    function addPair(address _pair, address _token) public {
        address factory = pyeSwapRouter.factory();
        require(
            msg.sender == factory
            || msg.sender == address(pyeSwapRouter)
            || msg.sender == address(this)
        , "PYE: NOT_ALLOWED"
        );

        if(!_checkPairRegistered(_pair)) {
            _isExcludedFromFee[_pair] = true;
            _isPairAddress[_pair] = true;
            isTxLimitExempt[_pair] = true;

            pairs[pairsLength] = _pair;
            tokens[pairsLength] = _token;

            pairsLength += 1;

            IPYESwapPair(_pair).updateTotalFee(getTotalFee());
        }
    }

    function addOutsideSwapPair(address account) public onlyOwner {
        _includeSwapFee[account] = true;
    }

    function removeOutsideSwapPair(address account) public onlyOwner {
        _includeSwapFee[account] = false;
    }

    // set an address as a staking contract
    function setIsStakingContract(address account, bool set) external onlyOwner {
        isStakingContract[account] = set;
    }

//--------------------------------------BEGIN RESCUE FUNCTIONS---------|

    // Rescue eth that is sent here by mistake
    function rescueETH(uint256 amount, address to) external onlyOwner {
        payable(to).transfer(amount);
      }

    // Rescue tokens that are sent here by mistake
    function rescueToken(IERC20 token, uint256 amount, address to) external onlyOwner {
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

//--------------------------------------BEGIN APPROVAL & ALLOWANCE FUNCTIONS---------|

     // allowance fxn is identical to ERC-20 allowance fxn. As per tommy's request, function is still explicity declared.
    function allowance(address owner, address spender) public view override(ERC20, IPYE) returns (uint256) {
        return _allowances[owner][spender];
    }
    
    // approve fxn overrides std. ERC-20 approve() fxn which declares address owner = _msgSender(), whereas MoonForce approve() fxn does not.
    function approve(address spender, uint256 amount) public override(ERC20, IPYE) returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // added override tag, see same explanation for approve() function above.
    function increaseAllowance(address spender, uint256 addedValue) public override virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    // added override tag, see same explanation for approve() function above.
    function decreaseAllowance(address spender, uint256 subtractedValue) public override virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    // added override tag for error message clarity (BEP vs ERC), changed visibility from private to internal to avoid compiler errors.
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

//--------------------------------------BEGIN FEE FUNCTIONS---------|

    // get sum of all fees
    function getTotalFee() internal view returns (uint256) {
        return _defaultFees.reflectionFee
            .add(_defaultFees.marketingFee)
            .add(_defaultFees.moonshotFee)
            .add(_defaultFees.buybackFee)
            .add(_defaultFees.liquifyFee);
    }

    // takes fees
    function _takeFees(FeeValues memory values) private {
        _takeFee(values.reflection.add(values.moonshots), moonshotAddress);
        _takeFee(values.marketing, _defaultFees.marketingAddress);
        _takeFee(values.buyBack, _burnAddress);
        if(values.liquify > 0) {
             _takeFee(values.liquify, _defaultFees.liquifyAddress);
        }
    }

    // collects fees
    function _takeFee(uint256 tAmount, address recipient) private {
        if(recipient == address(0)) return;
        if(tAmount == 0) return;

        _balances[recipient] = _balances[recipient].add(tAmount);
    }

    // calculates the fee
    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        if(_fee == 0) return 0;
        return _amount.mul(_fee).div(
            10**4
        );
    }

    // restores all fees
    function restoreAllFee() private {
        _defaultFees = _previousFees;
    }

    // removes all fees
    function removeAllFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _emptyFees;
    }

    function setSellFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _sellFees;
    }

    function setOutsideBuyFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _outsideBuyFees;
    }

    function setOutsideSellFee() private {
        _previousFees = _defaultFees;
        _defaultFees = _outsideSellFees;
    }

    // shows whether or not an account is excluded from fees
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    // allows Owner to make an address exempt from fees
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    // allows Owner to make an address incur fees
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // allows Owner to change max TX percent
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }

    // set an address to be tx limit exempt
    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    // safety check for set tx limit
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    // returns the specified values
    function _getValues(uint256 tAmount) private view returns (FeeValues memory) {
        FeeValues memory values = FeeValues(
            0,
            calculateFee(tAmount, _defaultFees.reflectionFee),
            calculateFee(tAmount, _defaultFees.marketingFee),
            calculateFee(tAmount, _defaultFees.moonshotFee),
            calculateFee(tAmount, _defaultFees.buybackFee),
            calculateFee(tAmount, _defaultFees.liquifyFee)
        );

        values.transferAmount = tAmount.sub(values.reflection).sub(values.marketing).sub(values.moonshots).sub(values.buyBack).sub(values.liquify);
        return values;
    }

    
    function depositLPFee(uint256 amount, address token) public onlyExchange {
        uint256 tokenIndex = _getTokenIndex(token);
        if(tokenIndex < pairsLength) {
            uint256 allowanceT = IERC20(token).allowance(msg.sender, address(this));
            if(allowanceT >= amount) {
                IERC20(token).transferFrom(msg.sender, address(this), amount);

                if(token != WETH) {
                    uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
                    swapToWETH(amount, token);
                    uint256 fAmount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
                    
                    // All fees to be declared here in order to be calculated and sent
                    uint256 totalFee = getTotalFee();
                    uint256 marketingFeeAmount = fAmount.mul(_defaultFees.marketingFee).div(totalFee);
                    uint256 reflectionFeeAmount = fAmount.mul(_defaultFees.reflectionFee).div(totalFee);
                    uint256 moonshotFeeAmount = fAmount.mul(_defaultFees.moonshotFee).div(totalFee);
                    uint256 liquifyFeeAmount = fAmount.mul(_defaultFees.liquifyFee).div(totalFee);

                    IERC20(WETH).transfer(_defaultFees.marketingAddress, marketingFeeAmount);
                    if(stakingContract != address(0)) {
                        IERC20(WETH).transfer(stakingContract, reflectionFeeAmount);
                        try StakingContract.depositWETHToStakingContract(reflectionFeeAmount) {} catch {}
                    } else {
                        IERC20(WETH).transfer(_defaultFees.liquifyAddress, reflectionFeeAmount);
                    }
                    IERC20(WETH).transfer(moonshotAddress, moonshotFeeAmount);
                    if(liquifyFeeAmount > 0) {IERC20(token).transfer(_defaultFees.liquifyAddress, liquifyFeeAmount);}
                } else {
                    // All fees to be declared here in order to be calculated and sent
                    uint256 totalFee = getTotalFee();
                    uint256 marketingFeeAmount = amount.mul(_defaultFees.marketingFee).div(totalFee);
                    uint256 reflectionFeeAmount = amount.mul(_defaultFees.reflectionFee).div(totalFee);
                    uint256 moonshotFeeAmount = amount.mul(_defaultFees.moonshotFee).div(totalFee);
                    uint256 liquifyFeeAmount = amount.mul(_defaultFees.liquifyFee).div(totalFee);

                    IERC20(token).transfer(_defaultFees.marketingAddress, marketingFeeAmount);
                    if(stakingContract != address(0)) {
                        IERC20(token).transfer(stakingContract, reflectionFeeAmount);
                        try StakingContract.depositWETHToStakingContract(reflectionFeeAmount) {} catch {}
                    } else {
                        IERC20(token).transfer(_defaultFees.liquifyAddress, reflectionFeeAmount);
                    }
                    IERC20(token).transfer(moonshotAddress, moonshotFeeAmount);
                    if(liquifyFeeAmount > 0) {IERC20(token).transfer(_defaultFees.liquifyAddress, liquifyFeeAmount);}
                }
            }
        }
    }

    function swapToWETH(uint256 amount, address token) internal {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;

        IERC20(token).approve(address(pyeSwapRouter), amount);
        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _updatePairsFee() internal {
        for (uint j = 0; j < pairsLength; j++) {
            IPYESwapPair(pairs[j]).updateTotalFee(getTotalFee());
        }
    }

    // set the reflection fee
    function setReflectionPercent(uint256 _reflectionFee) external onlyOwner {
        _defaultFees.reflectionFee = _reflectionFee;
        _defaultSellFees.reflectionFee = _reflectionFee;
        _outsideBuyFees.reflectionFee = _reflectionFee;
        _outsideSellFees.reflectionFee = _reflectionFee;
        _updatePairsFee();
    }

    // set liquify fee
    function setLiquifyPercent(uint256 _liquifyFee) external onlyOwner {
        _defaultFees.liquifyFee = _liquifyFee;
        _defaultSellFees.liquifyFee = _liquifyFee;
        _outsideBuyFees.liquifyFee = _liquifyFee;
        _outsideSellFees.liquifyFee = _liquifyFee;
        _updatePairsFee();
    }

    // set moonshot fee
    function setMoonshotPercent(uint256 _moonshotFee) external onlyOwner {
        _defaultFees.moonshotFee = _moonshotFee;
        _defaultSellFees.moonshotFee = _moonshotFee;
        _outsideBuyFees.moonshotFee = _moonshotFee;
        _outsideSellFees.moonshotFee = _moonshotFee;
        _updatePairsFee();
    }

    // set marketing fee
    function setMarketingPercent(uint256 _marketingFee) external onlyOwner {
        _defaultFees.marketingFee = _marketingFee;
        _defaultSellFees.marketingFee = _marketingFee;
        _outsideBuyFees.marketingFee = _marketingFee;
        _outsideSellFees.marketingFee = _marketingFee;
        _updatePairsFee();
    }

    // set buyback fee
    function setBuyBackPercent(uint256 _burnFee) external onlyOwner {
        _defaultFees.buybackFee = _burnFee;
        _defaultSellFees.buybackFee = _burnFee;
        _outsideBuyFees.buybackFee = _burnFee;
        _outsideSellFees.buybackFee = _burnFee;
        _updatePairsFee();
    }

//--------------------------------------BEGIN SET ADDRESS FUNCTIONS---------|

    // manually set marketing address
    function setMarketingAddress(address _marketing) external onlyOwner {
        require(_marketing != address(0), "PYE: Address Zero is not allowed");
        _defaultFees.marketingAddress = _marketing;
        _defaultSellFees.marketingAddress = _marketing;
        _sellFees.marketingAddress = _marketing;
        _outsideBuyFees.marketingAddress = _marketing;
        _outsideSellFees.marketingAddress = _marketing;
    }

    // manually set liquify address
    function setLiquifyAddress(address _liquify) external onlyOwner {
        require(_liquify != address(0), "PYE: Address Zero is not allowed");
        _defaultFees.liquifyAddress = _liquify;
        _defaultSellFees.liquifyAddress = _liquify;
        _sellFees.liquifyAddress = _liquify;
        _outsideBuyFees.liquifyAddress = _liquify;
        _outsideSellFees.liquifyAddress = _liquify;
    }

    // manually set moonshot mechanism address
    function updateMoonshotAddress(address payable newAddress) public onlyOwner {
        require(newAddress != address(moonshot), "The moonshot already has that address");

        MoonshotMechanism newMoonshot = MoonshotMechanism(newAddress);
        moonshot = newMoonshot;

        isTxLimitExempt[newAddress] = true;
        _isExcludedFromFee[newAddress] = true;

        moonshotAddress = newAddress;
    }

    function setNewStakingContract(address _newStakingContract) external onlyOwner {
        stakingContract = (_newStakingContract);
        StakingContract = IStakingContract(_newStakingContract);

        isTxLimitExempt[_newStakingContract] = true;
        _isExcludedFromFee[_newStakingContract] = true;
        isStakingContract[_newStakingContract] = true;
    }

//--------------------------------------BEGIN SHARE FUNCTIONS---------|

    function setStaked(address holder, uint256 amount) internal  {
        if(amount > 0 && staked[holder].amount == 0){
            addHolder(holder);
        }else if(amount == 0 && staked[holder].amount > 0){
            removeHolder(holder);
        }

        totalStaked = totalStaked.sub(staked[holder].amount).add(amount);
        staked[holder].amount = amount;
    }

    function addHolder(address holder) internal {
        holderIndexes[holder] = holders.length;
        holders.push(holder);
    }

    function removeHolder(address holder) internal {
        holders[holderIndexes[holder]] = holders[holders.length-1];
        holderIndexes[holders[holders.length-1]] = holderIndexes[holder];
        holders.pop();
    }

//--------------------------------------BEGIN BUYBACK FUNCTIONS---------|

    // runs check to see if autobuyback should trigger
    function shouldAutoBuyback(uint256 amount) internal view returns (bool) {
        return msg.sender != pyeSwapPair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && IERC20(address(WETH)).balanceOf(address(this)) >= autoBuybackAmount
        && amount >= minimumBuyBackThreshold;
    }

    // triggers auto buyback
    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, _burnAddress);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    // logic to purchase moonforce tokens
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        IERC20(WETH).approve(address(pyeSwapRouter), amount);
        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    // manually adjust the buyback settings to suit your needs
    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external onlyOwner {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    // manually adjust minimumBuyBackThreshold Denominator. Threshold will be tTotal divided by Denominator. default 1000000 or .0001%
    function setBuyBackThreshold(uint8 thresholdDenominator) external onlyOwner {
        minimumBuyBackThreshold = _tTotal / thresholdDenominator;
    }

//--------------------------------------BEGIN ROUTER FUNCTIONS---------|

    function updateRouterAndPair(address _router, address _pair) public onlyOwner {
        _isExcludedFromFee[address(pyeSwapRouter)] = false;
        _isExcludedFromFee[pyeSwapPair] = false;
        pyeSwapRouter = IPYESwapRouter(_router);
        pyeSwapPair = _pair;
        WETH = pyeSwapRouter.WETH();

        _isExcludedFromFee[address(pyeSwapRouter)] = true;
        _isExcludedFromFee[pyeSwapPair] = true;

        _isPairAddress[pyeSwapPair] = true;
        

        isTxLimitExempt[pyeSwapPair] = true;
        isTxLimitExempt[address(pyeSwapRouter)] = true;

        pairs[0] = pyeSwapPair;
        tokens[0] = WETH;

        IPYESwapPair(pyeSwapPair).updateTotalFee(getTotalFee());
    }

//--------------------------------------BEGIN TRANSFER FUNCTIONS---------|

    // transfer fxn is explicitly stated to override the std. ERC-20 transfer fxn which uses "to" param, but
    // MoonForce uses "recipient" param.
    function transfer(address recipient, uint256 amount) public override(ERC20, IPYE) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // transferFrom explicitly stated and overrides ERC-20 std becasue of variable name differences.
    function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20, IPYE) returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

   function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlacklisted[to]);
        _beforeTokenTransfer(from, to, amount);
        
        checkTxLimit(from, amount);

        if(shouldAutoBuyback(amount)){ triggerAutoBuyback(); }
        if(_isPairAddress[to] && moonshot.shouldLaunchMoon(to, from)){ try moonshot.launchMoonshot() {} catch {} }

        //indicates if fee should be deducted from transfer
        uint8 takeFee = 0;
        if(_isPairAddress[to] && from != address(pyeSwapRouter) && !isExcludedFromFee(from)) {
            takeFee = 1;
        } else if(_includeSwapFee[from] && !isExcludedFromFee(to)) {
            takeFee = 2;
        } else if(_includeSwapFee[to] && !isExcludedFromFee(from)) {
            takeFee = 3;
        }

        //transfer amount, it will take tax
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, uint8 takeFee) private {
        if(takeFee == 0) {
            removeAllFee();
        } else if(takeFee == 1) {
            setSellFee();
        } else if(takeFee == 2) {
            setOutsideBuyFee();
        } else if(takeFee == 3) {
            setOutsideSellFee();
        }

        FeeValues memory _values = _getValues(amount);
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(_values.transferAmount);
        _takeFees(_values);

        if(isStakingContract[recipient]) { 
            uint256 newAmountAdd = staked[sender].amount.add(amount);
            setStaked(sender, newAmountAdd);
        }

        if(isStakingContract[sender]) {
            uint256 newAmountSub = staked[recipient].amount.sub(amount);
            setStaked(recipient, newAmountSub);
        }

        emit Transfer(sender, recipient, _values.transferAmount);

        if(takeFee == 0 || takeFee == 1) {
            restoreAllFee();
        } else if(takeFee == 2 || takeFee == 3) {
            restoreAllFee();
            emit Transfer(sender, moonshotAddress, _values.reflection.add(_values.moonshots));
            emit Transfer(sender, _defaultFees.marketingAddress, _values.marketing);
            emit Transfer(sender, _burnAddress, _values.buyBack);
            if(_values.liquify > 0) {
                emit Transfer(sender, _defaultFees.liquifyAddress, _values.liquify);
            }
        }   
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IPYESwapRouter.sol";
import "./interfaces/IMoonshotMechanism.sol";
import "./interfaces/IStakingContract.sol";

contract MoonshotMechanism is IMoonshotMechanism {
    using SafeMath for uint256;

    address public _token;
    IStakingContract public StakingContract;
    address public stakingContract;

    struct Moonshot {
        string Name;
        uint Value;
    }

    bool public initialized = true;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    Moonshot[] internal Moonshots;
    address admin;
    uint public disbursalThreshold;
    uint public lastMoonShot;
    bool public autoMoonshotEnabled;

    bool private inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }
    IPYESwapRouter public pyeSwapRouter;
    address public WETH;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor() {
        pyeSwapRouter = IPYESwapRouter(0x4F71E29C3D5934A15308005B19Ca263061E99616);
        WETH = pyeSwapRouter.WETH();
        _token = msg.sender;

        admin = 0x5f46913071f854A99FeB5B3cF54851E539CA6D44;
        Moonshots.push(Moonshot("Waxing", 1000));
        Moonshots.push(Moonshot("Waning", 2500));
        Moonshots.push(Moonshot("Half Moon", 3750));
        Moonshots.push(Moonshot("Full Moon", 5000));
        Moonshots.push(Moonshot("Blue Moon", 10000));
        autoMoonshotEnabled = false;
        disbursalThreshold = 1*10**6;
    }

    modifier onlyAdmin {
        require(msg.sender == admin , "You are not the admin");
        _;
    }

    modifier onlyAdminOrToken {
        require(msg.sender == admin || msg.sender == _token);
        _;
    }
    //-------------------------- BEGIN EDITING FUNCTIONS ----------------------------------

    // Allows admin to create a new moonshot with a corresponding value; pushes new moonshot to end of array and increases array length by 1.
    function createMoonshot(string memory _newName, uint _newValue) public onlyAdmin {
        Moonshots.push(Moonshot(_newName, _newValue));
    }
    // Remove last element from array; this will decrease the array length by 1.
    function popMoonshot() public onlyAdmin {
        Moonshots.pop();
    }
    // User enters the value of the moonshot to delete, not the index. EX: enter 2000 to delete the Blue Moon struct, the array length is then decreased by 1.
        // moves the struct you want to delete to the end of the array, deletes it, and then pops the array to avoid empty arrays being selected by pickMoonshot.
    function deleteMoonshot(uint _value) public onlyAdmin {
        uint moonshotLength = Moonshots.length;
        for(uint i = 0; i < moonshotLength; i++) {
            if (_value == Moonshots[i].Value) {
                if (1 < Moonshots.length && i < moonshotLength-1) {
                    Moonshots[i] = Moonshots[moonshotLength-1]; }
                    delete Moonshots[moonshotLength-1];
                    Moonshots.pop();
                    break;
            }
        }
    }
    function updateAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function updateRouterAndPair(address _router) public onlyAdmin {	
        pyeSwapRouter = IPYESwapRouter(_router);	
    }

    function getGoal() external view override returns(uint256){
        return disbursalThreshold;
    }

    function getMoonshotBalance() external view override returns(uint256){
        return IERC20(address(WETH)).balanceOf(address(this));
    }

    //-------------------------- BEGIN GETTER FUNCTIONS ----------------------------------
    // Enter an index to return the name and value of the moonshot @ that index in the Moonshots array.
    function getMoonshotNameAndValue(uint _index) public view returns (string memory, uint) {
        return (Moonshots[_index].Name, Moonshots[_index].Value);
    }
    // Returns the value of the contract in ETH.
    function getContractValue() public view onlyAdmin returns (uint) {
        return address(this).balance;
    }
    // Getter fxn to see the disbursal threshold value.
    function getDisbursalValue() public view onlyAdmin returns (uint) {
        return disbursalThreshold;
    }
    //-------------------------- BEGIN MOONSHOT SELECTION FUNCTIONS ----------------------------------
    // Generates a "random" number.
    function random() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty + block.timestamp)));
    }

    // Allows admin to manually select a new disbursal threshold.
    function overrideDisbursalThreshold(uint newDisbursalThreshold) public onlyAdmin returns (uint) {
        disbursalThreshold = newDisbursalThreshold;
        return disbursalThreshold;
    }

    function pickMoonshot() internal {
        require(Moonshots.length > 1, "The Moonshot array has only one moonshot, please create a new Moonshot!");
        Moonshot storage winningStruct = Moonshots[random() % Moonshots.length];
        uint disbursalValue = winningStruct.Value;
        lastMoonShot = disbursalThreshold;
        
        // @todo update decimals for mainnet
        disbursalThreshold = disbursalValue * 10**13;
    }
  
    function shouldLaunchMoon(address from, address to) external view override returns (bool) {
        return (IERC20(address(WETH)).balanceOf(address(this)) >= disbursalThreshold 
            && disbursalThreshold != 0 
            && from != address(this) 
            && to != address(this) 
            && autoMoonshotEnabled); 
    }

    // calling pickMoonshot() required becasue upon contract deployment disbursalThreshold is initialized to 0
    function launchMoonshot() external onlyAdminOrToken override {
        if (IERC20(address(WETH)).balanceOf(address(this)) >= disbursalThreshold && disbursalThreshold != 0) { 
            buyReflectTokens(disbursalThreshold, address(this)); 
        } 
    }

    function buyReflectTokens(uint256 amount, address to) internal {
        
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;

        IERC20(WETH).approve(address(pyeSwapRouter), amount);

        pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp + 10 minutes
        );

        sendMFToStakingContractAfterBuyReflectTokens(stakingContract, IERC20(_token).balanceOf(address(this)));
        pickMoonshot();
    }

    function sendMFToStakingContractAfterBuyReflectTokens(address _stakingContract, uint256 _amountMF) internal {
        require(_stakingContract != address(0), "The staking contract address has not been set yet.");
        require(_amountMF > 0 , "You cannot send 0 tokens!");
        IERC20(_token).transfer(_stakingContract, _amountMF);
        StakingContract.depositMFToStakingContract(_amountMF);
    }

    function setStakingContractAddress(address _newStakingContractAddress) public onlyAdmin {
        stakingContract = _newStakingContractAddress; 
        StakingContract = IStakingContract(_newStakingContractAddress);

        IERC20(_token).approve(address(_newStakingContractAddress), 1 * 10**6 * 10**18);
    }

    function swapToWETH(address token) public onlyAdmin {
        uint256 amount = IERC20(address(token)).balanceOf(address(this));
        address[] memory path = new address[](2);
            path[0] = token;
            path[1] = WETH;

            IERC20(token).approve(address(pyeSwapRouter), amount);

            pyeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp + 10 minutes
            );
    }

    function enableAutoMoonshot(bool _enabled) external onlyAdmin {
        autoMoonshotEnabled = _enabled;
    }

    function approveStakingContract(uint256 amount) external onlyAdmin {
        IERC20(_token).approve(address(stakingContract), amount);
    }

    // Rescue eth that is sent here by mistake
    function rescueETH(uint256 amount, address to) external onlyAdmin{
        payable(to).transfer(amount);
      }

    // Rescue tokens that are sent here by mistake
    function rescueToken(IERC20 token, uint256 amount, address to) external onlyAdmin {
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IStakingContract {
    function depositWETHToStakingContract(uint256 _amount) external;
    function depositMFToStakingContract(uint256 _amountMF) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IMoonshotMechanism {
    function getGoal() external view returns(uint);
    function getMoonshotBalance() external view returns(uint);
    function launchMoonshot() external;
    function shouldLaunchMoon(address from, address to) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IPYESwapRouter01.sol';

interface IPYESwapRouter is IPYESwapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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
    function pairFeeAddress(address pair) external view returns (address);
    function adminFee() external view returns (uint256);
    function feeAddressGet() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IPYESwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function baseToken() external view returns (address);
    function getTotalFee() external view returns (uint);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function updateTotalFee(uint totalFee) external returns (bool);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast, address _baseToken);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, uint amount0Fee, uint amount1Fee, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setBaseToken(address _baseToken) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IPYESwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function pairExist(address pair) external view returns (bool);

    function createPair(address tokenA, address tokenB, bool supportsTokenFee) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function routerInitialize(address) external;
    function routerAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IWETH {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.1;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IPYE {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    //function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);



    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    //event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    //event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Arrays.sol";
import "../../../utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

pragma solidity >=0.6.2;

interface IPYESwapRouter01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}