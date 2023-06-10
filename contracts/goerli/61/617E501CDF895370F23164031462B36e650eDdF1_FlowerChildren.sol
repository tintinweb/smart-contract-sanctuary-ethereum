/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: No
pragma solidity = 0.8.19;                                                                                                                                                  
/*                                                
   .^YJJJ7JY7JY?7J?JJJJJYJJ??YJJYJ7???JJJ?JJ???7Y!!Y~~7~7~~7!?7~?!!?~~7!7!~7~~JJ~~JJ~~7YY?~!7~77~!!!J~~7!?~~7!77~7!!7~~777!!7!JJ!!7777!?!?!!~!!!~!!!J^!?777777777777!!77777!777?7777!!!!!7!7!!!!!!!^.   
   .~GYYP5YJ7?G?!PYYYY55Y55J!YP55Y55YYY555Y5YY5J5?7B^.?5P^:Y757.5~:P^:J?P?.?^^GY7.7B~:55BG:^?.JP.!JJP^!~^B~.Y?PY.?~:PJ.7GG:^Y7B#?!:~P^^G.!P7.!5?.!??#~555P5555PP55Y5PY5GPGJ77PP5PP5P5PP55GG5J55P5YG!.   
   .~GP??Y55J~7~7?7!JPPPJ?YJ?~7!~^~~^~^~~~~^^^~^^^:^^^~~^^^~^~^^^^~~^~~^~~^~~^^~~~~~~~~^~~~~!~~~~~!!!~7!!!!!!!!~!!!!77~~7!!!7!77!7!~7!~!!77~~~7~~!!~7^!~77!~~!777!~!!7777YJY^5J5PP5J?JYY!J5?7JPY~?G!.   
   .~G5?7!?~~?JY?YYY77JG??~J5!!.    ..^^:.:. .:^:.:^:..:^^::.  .:^:.:. .:^:^^::.    .:^:.:^...:^:...^^..:^...:^^::...:^^:::. .   .:^^::...:^:....:^:..::..:^^::.      :7^!5Y7YJ7GY~?JYYJ7J5YY?~J!PG7.   
   .~YJYJ~~J57Y57Y5Y7Y?7J^?^Y~?:......~GY77~!.^BY~7#??^!GY77G?..:GY^5Y~^:~^GJ~~!^.. .^GJ!7!J7.:GP7~.7YG?:??7~5G!7!!~^^PP?7!~:   .~YG7J~^!:^B?J:  :PP!!~7Y:^BY^GY^:   ..!?J5PP!~~J?5?755J!J55??Y?7P5!.   
   .!PP5!~Y5J?!^.:~5JJ5J7Y?^^!?.......^!!?GJ!^~BJ~7#7Y.^GJ?!GJJ!^G5^5?!^ .^GJ?:......~BJ!GJ^ .^BP7!:7~!YG?J^ YB7~5P!?:7!7P5~~ ....YB7J!^^.~#?7!:..JG7?~!Y.^B5^Y5~! .  ..7JYJJ~~Y!JG5??~...75!PP77GP7.   
   .!GP7~7P?JJ!   ~5J?7JJY?7?J~........:^^!7J:.^~7^^~7. .::~!7!..:~~^^^~...^~7^ ......^~~^^?!..:~!~:7^! ::?:^::^^!7?! :^^!7J~      :^^!7?..^~~~!7 .:^~!?~ .^~^~!?!  ... .!7J??YY?!JY5P!  .?GYJ7!J5G7.   
   .!GJ^!7GP?Y?.  ~57Y~~7JY?7^:................ ........  ....  ..... ..... ....  .     .  ^?^~..~^?J~~:.^~~J.   .      ...  ..      .....  .......  ... .  ..... .... .~:^!JY5J7!7Y?Y7. .?Y?Y~7JYP!.   
   .!GY.7!?Y?Y7.  ~57J7!7YJ?7^^^~!:.....   .~~^~.~^^^^.~^.^^^~^.:^^~^~^~.    ...::::::::::::?Y7Y~Y~J5!??!Y?5^::::::::::::.      ......... .     ....      .       .    .~???7?JYYJ~P?57. .?5?5~5PYP!.   
   .!P5.7~!PJ57...!5755J!YJ~?Y!^!?5! ..^^^~.~^^.~~~~^~.:!^!~^~:^^~~:~~~^^^^~.  .7JYY?JP555PJ~?~!Y:.?5:.??^J7?55555JJ5Y57.      .. . .. .........   ..  ......... .. ...  .^~?YYYGJ!P7Y7. .J575~JY5P!.   
   .755:7?7PJ5?...!57??J7Y~!!5J....:........................................   .^^:^JYP5?~^:..YYYY7YYYYJ5Y~ :~~?PPJY7^~~.     :~~: ::~..^!.!^:.~::.:~^.:~:.!^.^::. ^~^... .^!JJ5P!P57Y!. .757PJ~PY5~.   
   .7BG~~GPY5J!:::~Y5JJ757.:75!....      .. ..    ..                           ~~:::J57^^^^~~~~~7JJ???JJ~~!!~^~~!?5J~:^!7     :~!: :^~..:!.:^!.^~^.~^. .~ .^~::^?. ^^.... .^^~??!JJJYY7!!!7YY??!?5P!.   
   .7GPY^?GP!J55J55?7YJY?....:....  ..   ...      .    ...                       ~~?J~!J5YJ?!~:...... ....^!?Y5Y5J?Y7!^..     ...   .. ... .... ...... .. ...   ..... ... ~!^^:^!YYYJJ55?5YJYJ??7GG!.   
   .!5JPJ~?YY55Y!YYY7JY~. ... .. ..  ....   .:~~7!7^~.. .              .    ... :!Y5YPP?J7.        ...:.     .^5?5GGPPJ. . ....        ........................ .. ..  ....... .:~!77J5Y!5Y?7~Y55Y5!.   
   .!P55Y?7!?JYJ7YP5J~.   ..  .. ......  .~7J7J?7J7Y7J?!:.     .       ..   ....~??!5?:..      .^?YGGGBG57^.   ...!PJ?5~..  .....      ^~^^~~~~~~^~~~^!^^~!::~~:~:.         ......^~J5PY!Y55??P5YG5~    
   .!G5YYPJ5?!~~~~J~..^:...  ^^7:...... .JJ77?!~~~~77?!7?!.  ..             ...^5!J5~.       .7PBBPGB#BGBBBP!.     .JPYY7.  ...   .   . ...................::......     :^~.......:?YYJ??JJ7?G5Y^7G^    
   .!GJGBYJ7G??7^^5! .^:..  .7!!:..... .Y??G?^.!!.~~.~5P7?7...       .      . ^Y?PJ.          ?7~: ^J75BBBBB#!       ~GY5?. ..    .    .^.. :^^~7JYJ77?J7:.:7~..:!^     ~~7: . ....!J?J7!P?!^7GJ.?P^    
   .!G57J7?:G!?77?7. .    ...~^^:....  !Y7?J^. JP.?Y. ~JJ!Y:... .        .. .:5JG?            :^. :^:::JGBBB#J        :GPY7      .    .~^. .7YJ77?55??5YJ?!^!^...:^    .7~~:   .....:^:^!!JJ7^G~^5P^    
   .!PY^?7J7GYJJ!. ..........   ...... !55JY:. JP.!P: ~Y5YY: .....     ..   .J?GY             :?^ !7!J!.7#P5G^         ~#YJ^ . ..     :!^.^J?JJ?!JYY5J!???YY?^......      ...  ......:~~^!7PJ~??PPP^    
   .!5Y~J??5P7~J~ ......  .......... ..:YYPY7:.7?.~!.~7P557... ..   .  .    ^Y7B^               :~^    ~BB77!          .5G^J          ^!^:J77YP^^~^J?!~:5J??P~.:.  ..  . .     .....~^:~!J55YJ5G5Y5~    
   .!GPY?JYY!JG~:......  ...  .     ....:YP?7?!~~~~!777?57.. ...    .  .... 77YG.              .^~^.  .GBB!:.           7B:Y.         ^!^~?!?PP~!!~?JJ7^PP7J57.^.  ....  .... ......7J?7!5P5JPP?Y5P~    
   .!BGP5Y55Y?J~:....     .   .  . .  ....~7JJ??P7J?J7J!^.          .   . . 7!5P.              .....^~?B##?             !#:Y.      .  ^7^^JYJPP!!7^:!YJ!557J57 ..   ... .........  ..^!7??5PY5Y55PP~    
   .7P5YYYJB!:Y^:...          ..      ..   .:^7~J~?~!::             ..      !7JG.              .!5PGB#B5~Y5.            ?B:Y.         :!^.7??YP?~7^^^?JY5?7J5^.. ....... ........ .. .:!7YYP5J~~7J5~    
   .7P557JJ!^JB~:... ..    ::....:...:..::...  .:..:::.::..... .:..         :Y7B^              ^7.~YG?:  ?GB7.         .PP^J          .~^..!J5PYYY7~!J555Y??7: ..^^. .  .. ...    ... .^^P?55Y?7?J5~    
   .7BP?!J7?PBB~:......   .7~! .!:~.:7:^~~.~^~ :^~.:~^.!^:.!~: .7^.          J?GP.         ..^.5G.~!.   7BBB#GY!:.     7#JJ:           .^...^7?YP55JJ?55?!:^!: .:!^.. .  .. .!^.:. .. .^~PG5555JJ5P~    
   .7GJGPPGGYJ5~^.....    .!^^ .~^:.:~..^~..^!.~~:  ~..:^^.:~: .^..         .7PJGY.    .:!J5GG55B7 .  .JBBBBBBBBBGJ!: ~BP5J.            ..... .:^~~~~^::...:::..::.         ........  .~!P55PPPGPYP~    
   .7G5Y5PYJ??J!!~^:.  .   ..   ..  .. ...   . ....   ..... ........ .  ....~7?5J55:.:!YPPPG555Y5.  :.YBPP55PPPPPPGG^7BJPP7^.....  .     ..  .           ...                .  .    .::?^!JYGGGP5YP~    
   .7P5J75J????77?JY?^.     .:.          ...  ...:^!!:  ....    ...   ^7~:.:!57?G7JPY7JGGGGG5Y?7J7~.!J555YY5PGGGG5!JPPY5J?J!:..^7?.      ..       .!7~::...               ....    .~!^7???7!~J??Y5P^    
   .7PY!PY!?J!:.JJ7~JY~.   .~!7..   .::    .^^..  ........  ..:. .   .57..::!JPPPYJ!?5?7YGGGB^:Y?!JYJ5PG55GBBGGP!!Y57YGPYPJ7^:. :B?:::::. ....... ... ....::     .       .~!?.  .:J57!??77JJ7YY7555^    
   .7B!5G!Y5J~ .5JYJ~YJ^   ^J~^.  .^777~^ :7Y~^~~~!J?~77^..~!7!!:.....:7?55Y5YJ?JPYY7!?JJ5Y5?  ^5PP5P5#55PGYYY5YJJ7?JGYYJJYYJ55J?~^J??J7: ..^::^~7?. :^...~7~:~!7:.:...  ^?~^.  :55~?Y?. ^5YJ!7Y!PP^    
   .!BJ57?Y5J! .YJYJ!?Y7.  ...... ....... .:^ ............:^~~::.....:~?YPPYJYJJ?YPY?!~P?7JYY?~7J^75JY??5??J5YJ~P7JY5YJ7JJ5JYPPP?!~^::::.:^77~::^~~..... .^~?::^^:::...  ::::. .!P~?YJJ: ~P?YY~Y75P:    
   .!PYY!7YYJ!  Y?JJ~JY7.          .^.......?^.:..:..:.:.^???!:::::^!7!~!7?JJJ5YJ??7?!!JY!~!!755PYY555YY?J!^~~^~Y?75???JJ55YY?7!^~!!~:::::77?77.^..........!!.....     .       .7Y^JYYY: ~PJYY!Y7JP^    
   .!P5J7!?JJ!~~?5J!777^............:::::^::^57^:::::^:^:^~!?P5555Y55Y555YY5P55P55555Y5JJY7?Y555555YYYYJYY?7~~!~J5Y5Y5PPPP5Y5P555555555PPPY~~^:::::::^:::!Y7:::::^..............~J~!YYJ. ^5YYJ!J!P5:    
   .!G5Y?~!7JJYJJJ7!~!7!777!!!7!!!!!7!!!!77!77YPP5YJ??7??YYY5?5?~. 7P..:5^:.:77#7..7?!7G5Y~..P7..7:..P7..7J..^BG57..^GGYJ?:.:PG?..~5..!GY?77JPYJ????JJYYP5?!!~!~!~!!!!!!!!!!~!!!!!~!!?JJJJY5?77~J55^    
   .!GJGGJ!~~!!!!!~!?J5YJ5J77?5YJY??55P5JY5Y5Y7??5PPJ5YJJ5PPJ?BY~:.7P.:!5!5!..!B7..?J7!GPJ~..P7.:5~..P7.:JJ..!P~~?..!P~~7YJ..:55..~Y..!GY?JP5Y5?PPYPPGPJ77J5JYJ?YPP5JJYJ55?!7JPY557~~~777777!~7PPJP^    
   .!Y?JJYY?!~^^~!7YJ7??77!7?!77??77Y!?Y7?J??77J7???77?!7Y???YY?7JYYYY5YJY55YY5555555YY5J?YYYYYY5Y??JYYYYJJYYYYYYY5Y5YYYY55Y5YYYYYY5YJJ5Y77?J?Y!7?!JJJ77Y??JJYJ?PJJPJJYYJJ7YJ?JJ5YY5?~~^^7!!7YPP5Y5^    

    TWITTER: https://twitter.com/ShortKingsClub
    TELEGRAM: https://t.me/ShortKingsClubChannel
    WEBSITE: https://www.shortkings.club/

    Undeniably, this is a time for transformation.
    A time when stature is measured not in feet and inches
    but in dedication, innovation, and impact. 
    For too long, the world has looked down upon us,
    mistaking physical height for the measure of worth.
    But the dawn of the Crypto Shortking era is upon us,
    casting a formidable shadow over traditional paradigms and preconceptions.

    As we navigate this brave new world of cryptocurrencies,
    the rest of the world is starting to look down not with condescension,
    but rather, with a mounting sense of awe and even envy.
    For the Crypto Shortking stands not beneath them,
    but above, on the virtual heights of the crypto sphere,
    casting an imposing silhouette against the horizon of the future.

    So let the world look down,
    for what they will see is not a figure of pity
    but an object of aspiration - the Crypto Shortking,
    redefining success in a digital world,
    towering over the landscape of cryptocurrencies and the hearts of the digitally inspired.
    The time for the Crypto Shortking is now, and the world must tilt its gaze upward to see us.
*/

//--- Context ---//
abstract contract Context {
    constructor() {
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

//--- Ownable ---//
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}


//--- Interface for ERC20 ---//
interface IERC20 {
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

//--- Contract v2 ---//
contract FlowerChildren is Context, Ownable, IERC20 {

    function totalSupply() external pure override returns (uint256) { if (_totalSupply == 0) { revert(); } return _totalSupply; }
    function decimals() external pure override returns (uint8) { if (_totalSupply == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }


    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noFee;
    mapping (address => bool) private liquidityAdd;
    mapping (address => bool) private isLpPair;
    mapping (address => bool) private isPresaleAddress;
    mapping (address => uint256) private balance;


    uint256 constant public _totalSupply = 1_000_000_000 * 10**23;
    uint256 constant public swapThreshold = _totalSupply / 20_000;
    uint256 constant public buyfee = 0;
    uint256 constant public sellfee = 0;
    uint256 constant public transferfee = 0;
    uint256 constant public fee_denominator = 1_000;
    bool private canSwapFees = true;
    address payable private marketingAddress = payable(0x0000000000000000000000000000000000000000);


    IRouter02 public swapRouter;
    string constant private _name = "Flower CHildren";
    string constant private _symbol = "FCHID";
    uint8 constant private _decimals = 18;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant public Marketing1 = 0xa3435568772b225EA448990F4e2De3f9e4284DbE;//We're thrilled to announce a pivotal decision in line with the audacity and resilience of our Crypto Shortkings. We're allocating 5% of our token supply, divided evenly into two wallets, for dynamic marketing initiatives and giveaways.
    address constant public Marketing2 = 0xF2F78F7e301f40fF06088761771390DF6f4c1041;//This isn't a mere numeric shuffle; it's our strategic plan for a prominent future in the cryptocurrency sphere. Expect vibrant campaigns and appealing giveaways to enhance our visibility, mirroring the Shortking's ability to turn constraints into strengths. Keep an eye on our Twitter for updates!
    address constant public Marketing3 = 0xbD8F70C009a4706fBaba1E6032EbDa845665cCD7;//Further, we're assigning another 5% of our token supply for Central Exchange (Cex) listings, split between two wallets. This move amplifies our digital presence and simplifies the investment process, making our tokens as accessible as the Shortking's confidence.
    address constant public Marketing4 = 0x796373f157070eEB3Bd1f77A65E2E9442274c3fe;//Living the Shortking spirit, we echo Michael Burry, "Don't bunt. Aim out of the ballpark. Aim for the company of immortals." Guided by this ethos, we stride confidently into the crypto universe. Here's to us, the Crypto Shortkings, may our journey inspire as much as our philosophy.

    address public lpPair;
    bool public isTradingEnabled = true;
    bool private inSwap;

        modifier inSwapFlag {
        inSwap = true;
        _;
        inSwap = false;
    }


    event _enableTrading();
    event _setPresaleAddress(address account, bool enabled);
    event _toggleCanSwapFees(bool enabled);
    event _changePair(address newLpPair);
    event _changeThreshold(uint256 newThreshold);
    event _changeWallets(address marketing);


    constructor () {
    _noFee[msg.sender] = true;

    if (block.chainid == 56) {
        swapRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    } else if (block.chainid == 97) {
        swapRouter = IRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3) {
        swapRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    } else if (block.chainid == 43114) {
        swapRouter = IRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    } else if (block.chainid == 250) {
        swapRouter = IRouter02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    } else if (block.chainid == 5) {
        swapRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    } else {
        revert("Chain not valid");
    }

    liquidityAdd[msg.sender] = true;

    // Define the addresses to split the supply to
    address[4] memory addresses = [Marketing1, Marketing2, Marketing3, Marketing4]; // Replace these with the actual addresses

    // Calculate the amount to send to each address
    uint256 splitAmount = _totalSupply / 40; // 10% of the total supply

    // Send 90% of the total supply to the deployer
    uint256 deployerAmount = _totalSupply * 9 / 10; // 90% of the total supply
    balance[msg.sender] = deployerAmount;
    emit Transfer(address(0), msg.sender, deployerAmount);

    // Distribute the remaining 10% evenly between the 4 addresses
    for (uint256 i = 0; i < addresses.length; i++) {
        balance[addresses[i]] = splitAmount;
        emit Transfer(address(0), addresses[i], splitAmount);
    }

    lpPair = IFactoryV2(swapRouter.factory()).createPair(swapRouter.WETH(), address(this));
    isLpPair[lpPair] = true;
    _approve(msg.sender, address(swapRouter), type(uint256).max);
    _approve(address(this), address(swapRouter), type(uint256).max);
}

    receive() external payable {}

        function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

        function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

        function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
    }

        function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }
    function isNoFeeWallet(address account) external view returns(bool) {
        return _noFee[account];
    }

    function setNoFeeWallet(address account, bool enabled) public onlyOwner {
        _noFee[account] = enabled;
    }

    function isLimitedAddress(address ins, address out) internal view returns (bool) {

        bool isLimited = ins != owner()
            && out != owner() && msg.sender != owner()
            && !liquidityAdd[ins]  && !liquidityAdd[out] && out != DEAD && out != address(0) && out != address(this);
            return isLimited;
    }

    function is_buy(address ins, address out) internal view returns (bool) {
        bool _is_buy = !isLpPair[out] && isLpPair[ins];
        return _is_buy;
    }

    function is_sell(address ins, address out) internal view returns (bool) { 
        bool _is_sell = isLpPair[out] && !isLpPair[ins];
        return _is_sell;
    }

    function is_transfer(address ins, address out) internal view returns (bool) { 
        bool _is_transfer = !isLpPair[out] && !isLpPair[ins];
        return _is_transfer;
    }

    function canSwap(address ins, address out) internal view returns (bool) {
        bool canswap = canSwapFees && !isPresaleAddress[ins] && !isPresaleAddress[out];

        return canswap;
    }

    function changeLpPair(address newPair) external onlyOwner {
        isLpPair[newPair] = true;
        emit _changePair(newPair);
    }

    function toggleCanSwapFees(bool yesno) external onlyOwner {
        require(canSwapFees != yesno,"Bool is the same");
        canSwapFees = yesno;
        emit _toggleCanSwapFees(yesno);
    }

    function _transfer(address from, address to, uint256 amount) internal returns  (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (isLimitedAddress(from,to)) {
            require(isTradingEnabled,"Trading is not enabled");
        }


        if(is_sell(from, to) &&  !inSwap && canSwap(from, to)) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= swapThreshold) { internalSwap(contractTokenBalance); }
        }

        if (_noFee[from] || _noFee[to]){
            takeFee = false;
        }
        balance[from] -= amount; uint256 amountAfterFee = (takeFee) ? takeTaxes(from, is_buy(from, to), is_sell(from, to), amount) : amount;
        balance[to] += amountAfterFee; emit Transfer(from, to, amountAfterFee);

        return true;

    }

    function changeWallets(address marketing) external onlyOwner {
        marketingAddress = payable(marketing);
        emit _changeWallets(marketing);
    }


    function takeTaxes(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isbuy)  fee = buyfee;  else if (issell)  fee = sellfee;  else  fee = transferfee; 
        if (fee == 0)  return amount; 
        uint256 feeAmount = amount * fee / fee_denominator;
        if (feeAmount > 0) {

            balance[address(this)] += feeAmount;
            emit Transfer(from, address(this), feeAmount);
            
        }
        return amount - feeAmount;
    }

    function internalSwap(uint256 contractTokenBalance) internal inSwapFlag {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        if (_allowances[address(this)][address(swapRouter)] != type(uint256).max) {
            _allowances[address(this)][address(swapRouter)] = type(uint256).max;
        }

        try swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }
        bool success;

        if(address(this).balance > 0) {(success,) = marketingAddress.call{value: address(this).balance, gas: 35000}("");}

    }

        function setPresaleAddress(address presale, bool yesno) external onlyOwner {
            require(isPresaleAddress[presale] != yesno,"Same bool");
            isPresaleAddress[presale] = yesno;
            _noFee[presale] = yesno;
            liquidityAdd[presale] = yesno;
            emit _setPresaleAddress(presale, yesno);
        }

        function enableTrading() external onlyOwner {
            require(!isTradingEnabled, "Trading already enabled");
            isTradingEnabled = true;
            emit _enableTrading();
        }
}
/*
      ___                       ___           ___           ___     
     /\__\          ___        /\__\         /\  \         /\  \    
    /:/  /         /\  \      /::|  |       /::\  \        \:\  \   
   /:/__/          \:\  \    /:|:|  |      /:/\:\  \        \:\  \  
  /::\__\____      /::\__\  /:/|:|  |__   /:/  \:\  \        \:\  \ 
 /:/\:::::\__\  __/:/\/__/ /:/ |:| /\__\ /:/__/_\:\__\ _______\:\__\ 
 \/_|:|~~|     /\/:/  /    \/__|:|/:/  / \:\  /\ \/__/ \::::::::/__/
    |:|  |     \::/__/         |:/:/  /   \:\ \:\__\    \:\~~\    
    |:|  |      \:\__\         |::/  /     \:\/:/  /     \:\  \     
    |:|  |       \/__/         /:/  /       \::/  /       \:\__\    
     \|__|                     \/__/         \/__/         \/__/
                            .:~?Y5PGGGGP5Y?~:.                
                    .~YG#&&@@@@@@@@@@@@@&#GJ~.            
                .7G&@@@@@@@@@@@@@@@@@@@@@@@@&G7.         
            ^Y#@@@@@@@@@@@@&&[email protected]@@@@@@@@@#Y^       
            :Y&@@@@@@@@@@@@P7^:::::::[email protected]@@@@@@@@&Y:     
            [email protected]@@@@@@@@&&&J^::~?^::::::::[email protected]@@@@@@@@B7    
        .J&@@@@@@@@&&@@@PY##@@GYP7^::::::[email protected]@@@@@@@@&J.  
        .J&@@@@@@@@&@@@@@@@@@@&@@@@G::::::[email protected]&@@@@@@@@&J. 
        7#@@@@@@@@&@@@@@@&[email protected]&?J57Y&&^:~^^#@@&@@@@@@@@#7 
        :[email protected]@@@@@@@&@@@@@@@@@@@@@@@@@@5:[email protected]@@@&@@@@@@@@5:
        [email protected]@@@@@@&@@@@@@@@@@&[email protected]@@@@P::Y&&@@@@@&@@@@@@@@B7
        J#@@@@@@@&@@@@@@@@@@&&&&@@@@~::!&@@@@@@@&@@@@@@@#J
        J#@@@@@@@&@@@@@@@@@@@@@@&5PJ:::^@@@@@@@@&@@@@@@@#J
        [email protected]@@@@@@&@@@@@@@@@@#?^^::::7B&[email protected]@@@@@@&@@@@@@@B7
        :[email protected]@@@@@@@&@@@@@@@@@[email protected]&B!^5&@@&!^[email protected]@@@&@@@@@@@@5:
        7#@@@@@@@&&@@@@@@@G:&@G#@@@@@7::::!5#&@@@@@@@@#7 
        .J&@@@@@@@@&#PJ!7P5^[email protected]@@@@@&7::::::::^7G&@@@@&J. 
        .J&@@@@&57^::::^:[email protected]@@@@#~:::::::::::::~&@&J.  
            [email protected]@@~::::::::YP:#@@@BB^:::::::::::::!#@B7    
            :Y#&5~::::::[email protected]&[email protected]@&5^::::::::::::~P&#Y:     
            ^Y#&B?^::^@@&@GG~^:::::::::::~J#&#Y^       
                :7G&&[email protected]@@&7^::::::::^~?5#&&G7:         
                    .!YB&&@@GB#YYYY5PG#&&&BY!.            
                        .:~?YPGBBBBGPY?!:.                    
*/