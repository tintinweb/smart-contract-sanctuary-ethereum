//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "ERC20.sol";
import "ISwapRouter.sol";

interface IERC20Master {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract


interface WETH9 {
  function balanceOf(address _address) external returns(uint256);

  function deposit() external payable;
}

interface ERC20short {
  function mint(address _address, uint _amount) external;

  function burn(address _address, uint _amount) external;

  function balanceOf(address _account) external view returns (uint256);
}

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);

  function swapExactTokensForTokens(

    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}



contract OptimizerDAO is ERC20 {
  // May be able to delete membersTokenCount as tally is taken care of in ERC contract
  uint public treasuryEth;
  uint public startingEth;
  uint public lastSnapshotEth;

  address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  ISwapRouter router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  mapping(string => address) private tokenAddresses;
  mapping(string => address) private shortTokenAddresses;

  // Address's included in mappings. 1st set is the longs & 2nd is shorts
  /**
  address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  address private constant BAT = 0xDA5B056Cfb861282B4b59d29c9B395bcC238D29B;
  address private constant WBTC = 0x577D296678535e4903D59A4C929B718e1D575e0A;
  address private constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
  address private constant USDT = 0x2fb298bdbef468638ad6653ff8376575ea41e768;

  sWETH = 0x982cd41387dd65e659279C4EFCF05c25c4B586D6
  sBAT = 0xf760954e01e53c3f7F08733ca1dC62B14b4BF50e
  sWBTC = 0xA18533Ba93407a54BB1bcaDB7e9f3D34e46039F9
  sUNI = 0x95552cA5cc9f329E5376659eaD39F880307B7A13
  sUSDT = 0x1c0b9527210B427ad9bdfF41bb3a3b78C9ceE7d9

  */

  //
  mapping(string => uint) public assetWeightings;

  // Proposal struct of token, expected performance and confidence level.
  struct Proposal {
    uint startTime;
    uint endTime;
    uint startEth;
    uint endEth;
    string[] tokens;
    uint[] qtyOfTokensAcq;
    uint[] tokensWeightings;
    // Maps Token (i.e 'btc') to array
    mapping(string => uint[]) numOfUserTokens;
    // Maps Token string to array of total token amount
    mapping(string => uint[]) userViews;
    mapping(string => uint[]) userConfidenceLevel;
    mapping(string => string[]) userViewsType;
    mapping(string => string[]) userViewsRelativeToken;
  }

  // Array of Proposals
  Proposal[] public proposals;


  constructor() ERC20("Optimizer DAO Token", "ODP") {
    // On DAO creation, a vote/proposal is created which automatically creates a new one every x amount of time

    string[5] memory _tokens = ["WETH", "BAT", "WBTC", "UNI", "USDT"];
    address[5] memory _addresses = [0xc778417E063141139Fce010982780140Aa0cD5Ab, 0xDA5B056Cfb861282B4b59d29c9B395bcC238D29B, 0x577D296678535e4903D59A4C929B718e1D575e0A, 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0x2fB298BDbeF468638AD6653FF8376575ea41e768];

    string[5] memory _shortTokens = ["sWETH", "sBAT", "sWBTC", "sUNI", "sUSDT"];
    address[5] memory _shortAddresses = [0x982cd41387dd65e659279C4EFCF05c25c4B586D6, 0xf760954e01e53c3f7F08733ca1dC62B14b4BF50e, 0xA18533Ba93407a54BB1bcaDB7e9f3D34e46039F9, 0x95552cA5cc9f329E5376659eaD39F880307B7A13, 0x1c0b9527210B427ad9bdfF41bb3a3b78C9ceE7d9];


    for (uint i = 0; i < _tokens.length; i++) {
      tokenAddresses[_tokens[i]] = _addresses[i];
      shortTokenAddresses[_shortTokens[i]] = _shortAddresses[i];
    }
  }



  function joinDAO() public payable {
    // What is the minimum buy in for the DAO?
    require(msg.value >= 41217007 gwei, "Minimum buy in is 0.1 ether");

    if (treasuryEth == 0) {

      // If there is nothing in the treasury, provide liquidity to treasury
      // LP tokens are initially provided on a 1:1 basis
      treasuryEth = msg.value;
      startingEth = treasuryEth;

      // change to _mint
      _mint(msg.sender, treasuryEth);

    } else {
      // DAO members token count is diluted as more members join / add Eth
      treasuryEth += msg.value;
      startingEth = treasuryEth;
      uint ethReserve =  treasuryEth - msg.value;
      uint proportionOfTokens = (msg.value * totalSupply()) / ethReserve;
      // change to _mint
      _mint(msg.sender, proportionOfTokens);
    }
  }


  function leaveDAO() public {
    uint tokenBalance = balanceOf(msg.sender);
    require(tokenBalance > 0);

    // User gets back the relative % of the
    uint ethToWithdraw = (tokenBalance / totalSupply()) * treasuryEth;
    _burn(msg.sender, tokenBalance);
    payable(msg.sender).transfer(ethToWithdraw);
    treasuryEth -= ethToWithdraw;
  }


  function submitVote(string[] memory _token, uint[] memory _perfOfToken, uint[] memory _confidenceLevels, string[] memory _userViewsType, string[] memory _userViewsRelativeToken) public payable onlyMember {
    // User inputs token they'd like to vote on, the expected performance of token over time period and their confidence level
    // Loop through each token in list and provide a +1 on list
    // If token is in proposal, include in Struct and output average for Performance & confidence levels
    require((_token.length == _perfOfToken.length) && (_perfOfToken.length == _confidenceLevels.length), "Arrays must be the same size");

    uint numberOfVoterTokens = balanceOf(msg.sender);
    for (uint i = 0; i < _token.length; i++) {
      // get each value out of array
      proposals[proposals.length - 1].tokens.push(_token[i]);
      proposals[proposals.length - 1].userViews[_token[i]].push(_perfOfToken[i]);

      proposals[proposals.length - 1].numOfUserTokens[_token[i]].push(numberOfVoterTokens);
      proposals[proposals.length - 1].userConfidenceLevel[_token[i]].push(_confidenceLevels[i]);
      proposals[proposals.length - 1].userViewsType[_token[i]].push(_userViewsType[i]);
      proposals[proposals.length - 1].userViewsRelativeToken[_token[i]].push(_userViewsRelativeToken[i]);

    }
  }

  function getProposalVotes(string memory _token) public view returns (uint[] memory, uint[] memory, uint[] memory, string[] memory, string[] memory){
      Proposal storage proposal = proposals[proposals.length - 1];
      uint length = proposal.numOfUserTokens[_token].length;
      uint[]  memory _numOfUserTokens = new uint[](length);
      uint[]  memory _userViews = new uint[](length);
      uint[]  memory _userConfidenceLevel = new uint[](length);
      string[] memory _userViewsType = new string[](length);
      string[] memory _userViewsRelativeToken = new string[](length);

      for (uint i = 0; i < length; i++) {
          _numOfUserTokens[i] = proposal.numOfUserTokens[_token][i];
          _userViews[i] = proposal.userViews[_token][i];
          _userConfidenceLevel[i] = proposal.userConfidenceLevel[_token][i];
          _userViewsType[i] = proposal.userViewsType[_token][i];
          _userViewsRelativeToken[i] = proposal.userViewsRelativeToken[_token][i];
      }

      return (_numOfUserTokens, _userViews, _userConfidenceLevel, _userViewsType, _userViewsRelativeToken);

  }

  // Event to emit for Python script to pick up data for model?


  /**
  function findTokenWeight() public  {
    uint sumOfLPForToken;

    uint numeratorToken;
    uint numeratorConfidence;

    for (uint i = 0; i < proposals[proposals.length - 1].tokens.length; i++) {
      string memory _token = proposals[proposals.length - 1].tokens[i];
      sumOfLPForToken += proposals[proposals.length - 1].numOfUserTokens[_token][i];
      numeratorToken += proposals[proposals.length - 1].numOfUserTokens[_token][i] * proposals[proposals.length - 1].userWeightings[_token][i];
      numeratorConfidence += proposals[proposals.length - 1].numOfUserTokens[_token][i] * proposals[proposals.length - 1].userConfidenceLevel[_token][i];

      uint weightedAveragePerformance = numeratorToken / sumOfLPForToken;
      uint weightedAverageConfidence = numeratorConfidence / sumOfLPForToken;

      // This will return a number with 18 decimals, need to divide by 18
      proposals[proposals.length - 1].proposalFinalPerformance[_token] = weightedAveragePerformance;
      proposals[proposals.length - 1].proposalFinalConfidence[_token] = weightedAverageConfidence;
    }


    // Update Token weightings mapping
    // initialize tradesOnUniswap function

  }
  */

  function initiateTradesOnUniswap(string[] memory _assets, uint[] memory _percentage) public payable {
    bytes32 wethRepresentation = keccak256(abi.encodePacked("WETH"));

    if (proposals.length >= 1) {
      // 1. Sell off existing holdings
      Proposal storage newProposal = proposals.push();

      for (uint i = 0; i < _assets.length; i++) {
        if (tokenAddresses[_assets[i]] != address(0)) {
          if (ERC20(tokenAddresses[_assets[i]]).balanceOf(address(this)) > 0 && (keccak256(abi.encodePacked(_assets[i])) != wethRepresentation)) {
            _swap(tokenAddresses[_assets[i]], WETH, ERC20(tokenAddresses[_assets[i]]).balanceOf(address(this)), 0, address(this));
          }

        }
        else if (shortTokenAddresses[_assets[i]] != address(0) && ERC20short(shortTokenAddresses[_assets[i]]).balanceOf(address(this)) > 0) {
          ERC20short(shortTokenAddresses[_assets[i]]).burn(address(this), ERC20short(shortTokenAddresses[_assets[i]]).balanceOf(address(this)));
        }
      }
      // 2. Take a snapshot of the proceedings in WETH
      proposals[proposals.length - 2].endEth = WETH9(WETH).balanceOf(address(this));
      proposals[proposals.length - 2].endTime = block.timestamp;
      proposals[proposals.length - 1].startEth = WETH9(WETH).balanceOf(address(this));
      proposals[proposals.length - 1].startTime = block.timestamp;

      lastSnapshotEth = WETH9(WETH).balanceOf(address(this));

      // 3. Convert any Eth in treasury to WETH
      WETH9(WETH).deposit{value: address(this).balance}();

      // 4. Reallocate all WETH based on new weightings
      for (uint i = 0; i < _assets.length; i++) {
        assetWeightings[_assets[i]] = _percentage[i];
        proposals[proposals.length - 1].tokensWeightings.push(_percentage[i]);
        if (tokenAddresses[_assets[i]] == WETH) {
            proposals[proposals.length - 1].tokens.push("WETH");
            proposals[proposals.length - 1].qtyOfTokensAcq.push(WETH9(WETH).balanceOf(address(this)));

          }
        if (_percentage[i] != 0 && (keccak256(abi.encodePacked(_assets[i])) != wethRepresentation)) {
          if (tokenAddresses[_assets[i]] != address(0) && _percentage[i] != 0) {
            uint allocation = (lastSnapshotEth * _percentage[i]) / 100;
            _swap(WETH, tokenAddresses[_assets[i]], allocation, 0, address(this));
            proposals[proposals.length - 1].tokens.push(_assets[i]);
            proposals[proposals.length - 1].qtyOfTokensAcq.push(ERC20(tokenAddresses[_assets[i]]).balanceOf(address(this)));
          }
          if (shortTokenAddresses[_assets[i]] != address(0)) {
            uint allocation = (lastSnapshotEth * _percentage[i]) / 100;
            ERC20short(shortTokenAddresses[_assets[i]]).mint(address(this), allocation);
            proposals[proposals.length - 1].tokens.push(_assets[i]);
            proposals[proposals.length - 1].qtyOfTokensAcq.push(ERC20short(shortTokenAddresses[_assets[i]]).balanceOf(address(this)));
          }
        }
      }

    }
    if (proposals.length == 0) {
      // 1. If first Proposal, convert all Eth to WETH
      Proposal storage newProposal = proposals.push();

      WETH9(WETH).deposit{value: address(this).balance}();

      uint wethBalance = WETH9(WETH).balanceOf(address(this));

      // Snapshot captured of WETH at beggining of proposal w/ timestamp
      proposals[proposals.length - 1].startTime = block.timestamp;
      proposals[proposals.length - 1].startEth = wethBalance;

      /**
      (bool success, ) = WETH9(WETH).call{value: address(this).balance}(abi.encodeWithSignature("deposit()"));
      require(success, "The transaction failed");
      console.log("this is an error");
      (bool go, bytes memory output) = tokenAddresses["WETH"].call(abi.encodeWithSignature("balanceOf(address)", address(this)));
      require(go);
      console.log(go);
      uint balance = abi.decode(output, (uint256));
      console.log("hello");
      console.log(balance);
      */
      // 2. Take asset weightings and purchase assets


      for (uint i = 0; i < _assets.length; i++) {
        assetWeightings[_assets[i]] = _percentage[i];
        proposals[proposals.length - 1].tokensWeightings.push(_percentage[i]);
        if (tokenAddresses[_assets[i]] == WETH) {
            proposals[proposals.length - 1].tokens.push("WETH");
            proposals[proposals.length - 1].qtyOfTokensAcq.push(WETH9(WETH).balanceOf(address(this)));

          }
        if (_percentage[i] != 0 && (keccak256(abi.encodePacked(_assets[i])) != wethRepresentation)) {
          if (tokenAddresses[_assets[i]] != address(0)) {
            uint allocation = (wethBalance * _percentage[i]) / 100;
            _swap(WETH, tokenAddresses[_assets[i]], allocation, 0, address(this));
            proposals[proposals.length - 1].tokens.push(_assets[i]);
            proposals[proposals.length - 1].qtyOfTokensAcq.push(ERC20(tokenAddresses[_assets[i]]).balanceOf(address(this)));
          }
          else if (shortTokenAddresses[_assets[i]] != address(0)) {
            uint allocation = (wethBalance * _percentage[i]) / 100;
            ERC20short(shortTokenAddresses[_assets[i]]).mint(address(this), allocation);
            proposals[proposals.length - 1].tokens.push(_assets[i]);
            proposals[proposals.length - 1].qtyOfTokensAcq.push(ERC20short(shortTokenAddresses[_assets[i]]).balanceOf(address(this)));
          }

        }

      }

    }

  }

  //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to

  function _swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) public {

    //first we need to transfer the amount in tokens from the msg.sender to this contract
    //this contract will have the amount of in tokens
    //IERC20Master(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

    //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
    ERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

    //path is an array of addresses.
    //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
    //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    address[] memory path;
    if (_tokenIn == WETH || _tokenOut == WETH) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
      //router.exactInput(ISwapRouter.ExactInputParams(path, address(this), block.timestamp, _amountIn, 0));
      //IUniswapV2Router(UNISWAP_V2_ROUTER).ExactInputParams(path, address(this), block.timestamp, _amountIn, 0);
      IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }

    function getHoldingsDataOfProposal(uint _index) public view returns(string[10] memory, uint[10] memory, uint[10] memory, uint[2] memory) {
      string[10] memory _tokens = ["WETH", "BAT", "WBTC", "UNI", "USDT", "sWETH", "sBAT", "sWBTC", "sUNI", "sUSDT"];
      uint[10] memory actualHoldings;
      uint[10] memory fundAssetWeightings;
      uint[2] memory startingAndEndingTimes;

      startingAndEndingTimes[0] = proposals[_index].startTime;
      startingAndEndingTimes[1] = proposals[_index].endTime;

      fundAssetWeightings[0] = proposals[_index].tokensWeightings[0];
      actualHoldings[0] = proposals[_index].qtyOfTokensAcq[0];

      for (uint i = 1; i < _tokens.length; i++) {
        fundAssetWeightings[i] = proposals[_index].tokensWeightings[i];
        if (tokenAddresses[_tokens[i]] != address(0) && tokenAddresses[_tokens[i]] != WETH && proposals[_index].tokensWeightings[i] != 0) {
          actualHoldings[i] = proposals[_index].qtyOfTokensAcq[i];
        }
        else if (shortTokenAddresses[_tokens[i]] != address(0) && proposals[_index].tokensWeightings[i] != 0) {
          actualHoldings[i] = proposals[_index].qtyOfTokensAcq[i];
        }
      }
      return (_tokens, actualHoldings,fundAssetWeightings, startingAndEndingTimes);
    }

  function lengthOfProposals() public view returns(uint256) {
    return proposals.length;
  }


  modifier onlyMember {
      require(balanceOf(msg.sender) > 0);
      _;
   }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}