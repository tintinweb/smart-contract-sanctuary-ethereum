/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;


/**
 @title Token
 @dev base ERC20 to act as token underlying CHD and pool tokens
 */
contract Token{

    /*Storage*/
    string  private tokenName;
    string  private tokenSymbol;
    uint256 internal supply;//totalSupply
    mapping(address => uint) balance;
    mapping(address => mapping(address=>uint)) userAllowance;//allowance

    /*Events*/
    event Approval(address indexed _src, address indexed _dst, uint _amt);
    event Transfer(address indexed _src, address indexed _dst, uint _amt);

    /*Functions*/
    /**
     * @dev Constructor to initialize token
     * @param _name of token
     * @param _symbol of token
     */
    constructor(string memory _name, string memory _symbol){
        tokenName = _name;
        tokenSymbol = _symbol;
    }

    /**
     * @dev allows a user to approve a spender of their tokens
     * @param _spender address of party granting approval
     * @param _amount amount of tokens to allow spender access
     */
    function approve(address _spender, uint256 _amount) external returns (bool) {
        userAllowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev function to transfer tokens
     * @param _to destination of tokens
     * @param _amount of tokens
     */
    function transfer(address _to, uint256 _amount) external returns (bool) {
        _move(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev allows a party to transfer tokens from an approved address
     * @param _from address source of tokens 
     * @param _to address destination of tokens
     * @param _amount uint256 amount of tokens
     */
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        require(msg.sender == _from || _amount <= userAllowance[_from][msg.sender], "not approved");
        _move(_from,_to,_amount);
        if (msg.sender != _from) {
            userAllowance[_from][msg.sender] = userAllowance[_from][msg.sender] -  _amount;
            emit Approval(msg.sender, _to, userAllowance[_from][msg.sender]);
        }
        return true;
    }

    //Getters
    /**
     * @dev retrieves standard token allowance
     * @param _src user who owns tokens
     * @param _dst spender (destination) of these tokens
     * @return uint256 allowance
     */
    function allowance(address _src, address _dst) external view returns (uint256) {
        return userAllowance[_src][_dst];
    }

    /**
     * @dev retrieves balance of token holder
     * @param _user address of token holder
     * @return uint256 balance of tokens
     */
    function balanceOf(address _user) external view returns (uint256) {
        return balance[_user];
    }
    
    /**
     * @dev retrieves token number of decimals
     * @return uint8 number of decimals (18 standard)
     */
    function decimals() external pure returns(uint8) {
        return 18;
    }

    /**
     * @dev retrieves name of token
     * @return string token name
     */
    function name() external view returns (string memory) {
        return tokenName;
    }

    /**
     * @dev retrieves symbol of token
     * @return string token sybmol
     */
    function symbol() external view returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @dev retrieves totalSupply of token
     * @return amount of token
     */
    function totalSupply() external view returns (uint256) {
        return supply;
    }

    /**Internal Functions */
    /**
     * @dev burns tokens
     * @param _from address to burn tokens from
     * @param _amount amount of token to burn
     */
    function _burn(address _from, uint256 _amount) internal {
        balance[_from] = balance[_from] - _amount;//will overflow if too big
        supply = supply - _amount;
        emit Transfer(_from, address(0), _amount);
    }

    /**
     * @dev mints tokens
     * @param _to address of recipient
     * @param _amount amount of token to send
     */
    function _mint(address _to,uint256 _amount) internal {
        balance[_to] = balance[_to] + _amount;
        supply = supply + _amount;
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev moves tokens from one address to another
     * @param _src address of sender
     * @param _dst address of recipient
     * @param _amount amount of token to send
     */
    function _move(address _src, address _dst, uint256 _amount) internal {
        balance[_src] = balance[_src] - _amount;//will overflow if too big
        balance[_dst] = balance[_dst] + _amount;
        emit Transfer(_src, _dst, _amount);
    }
}

contract CHD is Token{

    //Storage
    address public charon;//address of the charon contract
    //Events
    event CHDMinted(address _to, uint256 _amount);
    event CHDBurned(address _from, uint256 _amount);

    /**
     * @dev constructor to initialize contract and token
     */
    constructor(address _charon,string memory _name, string memory _symbol) Token(_name,_symbol){
        charon = _charon;
    }

    /**
     * @dev allows the charon contract to burn tokens of users
     * @param _from address to burn tokens of
     * @param _amount amount of tokens to burn
     * @return bool of success
     */
    function burnCHD(address _from, uint256 _amount) external returns(bool){
        require(msg.sender == charon,"caller must be charon");
        _burn(_from, _amount);
        emit CHDBurned(_from,_amount);
        return true;
    }
    
    /**
     * @dev allows the charon contract to mint chd tokens
     * @param _to address to mint tokens to
     * @param _amount amount of tokens to mint
     * @return bool of success
     */
    function mintCHD(address _to, uint256 _amount) external returns(bool){
        require(msg.sender == charon, "caller must be charon");
        _mint(_to,_amount);
        emit CHDMinted(_to,_amount);
        return true;
    }
}

interface IHasher {
  function poseidon(bytes32[2] calldata _inputs) external pure returns (bytes32);
}

/**
 @title MerkleTreeWithHistory
 @dev a merkle tree contract that tracks historical roots
**/  
contract MerkleTreeWithHistory {
  /*Storage*/
  uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

  IHasher public immutable hasher;//implementation of hasher
  uint32 public immutable levels;//levels in the merkle tree

  // make public for debugging, make all private for deployment
  // filledSubtrees and roots could be bytes32[size], but using mappings makes it cheaper because
  // it removes index range check on every interaction
  mapping(uint256 => bytes32) public filledSubtrees;
  mapping(uint256 => bytes32) roots;
  mapping(uint256 => bytes32) zeros;
  uint32 public constant ROOT_HISTORY_SIZE = 100;
  uint32 private currentRootIndex = 0; 
  uint32 nextIndex = 0;

  /*functions*/
  /**
    * @dev constructor for initializing tree
    * @param _levels uint32 merkle tree levels
    * @param _hasher address of poseidon hasher
    */
  constructor(uint32 _levels, address _hasher) {
    require(_levels > 0, "_levels should be greater than zero");
    require(_levels < 32, "_levels should be less than 32");
    levels = _levels;
    hasher = IHasher(_hasher);
    zeros[0] = bytes32(ZERO_VALUE);
    uint32 _i;
    for(_i =1; _i<= 32; _i++){
      zeros[_i] = IHasher(_hasher).poseidon([zeros[_i-1], zeros[_i-1]]);
    }
    for (_i=0; _i< _levels; _i++) {
      filledSubtrees[_i] = zeros[_i];
    }
    roots[0] = zeros[_levels];
  }

  /**
    * @dev hash 2 tree leaves, returns Poseidon(_left, _right)
    * @param _left bytes32 to hash
    * @param _right bytes32 to hash
    * @return bytes32 hash of input
    */
  function hashLeftRight(bytes32 _left, bytes32 _right) public view returns (bytes32) {
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    bytes32[2] memory _input;
    _input[0] = _left;
    _input[1] = _right;
    return hasher.poseidon(_input);
  }

  //getters
  /**
    * @dev gets last root of the merkle tree
    * @return bytes32 root
    */
  function getLastRoot() external view returns (bytes32) {
    return roots[currentRootIndex];
  }

  /**
    * @dev checks if inputted root is known historical root of tree
    * @param _root bytes32 supposed historical root
    * @return bool if root was ever made from merkleTree
    */
  function isKnownRoot(bytes32 _root) public view returns (bool) {
    if (_root == 0) {
      return false;
    }
    uint32 _currentRootIndex = currentRootIndex;
    uint32 _i = _currentRootIndex;
    do {
      if (_root == roots[_i]) {
        return true;
      }
      if (_i == 0) {
        _i = ROOT_HISTORY_SIZE;
      }
      _i--;
    } while (_i != _currentRootIndex);
    return false;
  }

  /**
    * @dev provides zero (empty) elements for a poseidon MerkleTree. Up to 32 levels
    * @param _i uint256 0-32 number of location of zero
    * @return bytes32 zero element of tree at input location
    */
  function getZeros(uint256 _i) external view returns (bytes32) {
    if(_i <= 32){
      return zeros[_i];
    }
    else revert("Index out of bounds");
  }

  /*internal functions*/
  /**
    * @dev allows users to insert pairs of leaves into tree
    * @param _leaf1 bytes32 first leaf to add
    * @param _leaf2 bytes32 second leaf to add
    * @return _nextIndex uint32 index of insertion
    */
  function _insert(bytes32 _leaf1, bytes32 _leaf2) internal returns (uint32 _nextIndex) {
    _nextIndex = nextIndex;
    require(_nextIndex != uint32(2)**levels, "Merkle tree is full. No more leaves can be added");
    uint32 _currentIndex = _nextIndex / 2;
    bytes32 _currentLevelHash = hashLeftRight(_leaf1, _leaf2);
    bytes32 _left;
    bytes32 _right;
    for (uint32 _i = 1; _i < levels; _i++) {
      if (_currentIndex % 2 == 0) {
        _left = _currentLevelHash;
        _right = zeros[_i];
        filledSubtrees[_i] = _currentLevelHash;
      } else {
        _left = filledSubtrees[_i];
        _right = _currentLevelHash;
      }
      _currentLevelHash = hashLeftRight(_left, _right);
      _currentIndex /= 2;
    }
    uint32 _newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
    currentRootIndex = _newRootIndex;
    roots[_newRootIndex] = _currentLevelHash;
    nextIndex = _nextIndex + 2;
  }
}



/**
 @title math
 @dev the math contract contains amm math functions for the charon system
**/
contract Math{
    /*Storage*/
    uint256 public constant BONE              = 10**18;
    uint256 public constant MAX_IN_RATIO      = BONE / 2;
    uint256 public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;

    /*Functions*/
    /**
     * @dev calculates an in amount of a token given how much is expected out of the other token
     * @param _tokenBalanceIn uint256 amount of tokenBalance of the in token's pool
     * @param _tokenBalanceOut uint256 amount of token balance in the out token's pool
     * @param _tokenAmountOut uint256 amount of token you expect out
     * @param _swapFee uint256 fee on top of swap
     * @return _tokenAmountIn is the uint256 amount of token in
     */
    function calcInGivenOut(
        uint256 _tokenBalanceIn,
        uint256 _tokenBalanceOut,
        uint256 _tokenAmountOut,
        uint256 _swapFee
    )
        public pure
        returns (uint256 _tokenAmountIn)
    {
        uint256 _diff = _tokenBalanceOut - _tokenAmountOut;
        uint256 _y = _bdiv(_tokenBalanceOut, _diff);
        uint256 _foo = _y - BONE;
        _tokenAmountIn = BONE - _swapFee;
        _tokenAmountIn = _bdiv(_bmul(_tokenBalanceIn, _foo), _tokenAmountIn);
    }

    /**
     * @dev calculates an out amount for a given token's amount in
     * @param _tokenBalanceIn uint256 amount of tokenBalance of the in token's pool
     * @param _tokenBalanceOut uint256 amount of token balance in the out token's pool
     * @param _tokenAmountIn uint256 amount of token you expect out
     * @param _swapFee uint256 fee on top of swap
     * @return _tokenAmountOut is the uint256 amount of token out
     */
    function calcOutGivenIn(
        uint256 _tokenBalanceIn,
        uint256 _tokenBalanceOut,
        uint256 _tokenAmountIn,
        uint256 _swapFee
    )
        public pure
        returns (uint256 _tokenAmountOut)
    {
        uint256 _adjustedIn = BONE - _swapFee;
        _adjustedIn = _bmul(_tokenAmountIn, _adjustedIn);
        uint256 _y = _bdiv(_tokenBalanceIn, (_tokenBalanceIn + _adjustedIn));
        uint256 _bar = BONE - _y;
        _tokenAmountOut = _bmul(_tokenBalanceOut, _bar);
    }

    /**
     * @dev calculates a amount of pool tokens out when given a single token's in amount
     * @param _tokenBalanceIn uint256 amount of tokenBalance of the in token's pool
     * @param _poolSupply uint256 amount of pool tokens in supply
     * @param _tokenAmountIn amount of tokens you are sending in
     * @return _poolAmountOut is the uint256 amount of pool token out
     */
    function calcPoolOutGivenSingleIn(
        uint256 _tokenBalanceIn,
        uint256 _poolSupply,
        uint256 _tokenAmountIn
    )
        public pure
        returns (uint256 _poolAmountOut)
    {
        uint256 _tokenAmountInAfterFee = _bmul(_tokenAmountIn,BONE);
        uint256 _newTokenBalanceIn = _tokenBalanceIn + _tokenAmountInAfterFee;
        uint256 _tokenInRatio = _bdiv(_newTokenBalanceIn, _tokenBalanceIn);
        uint256 _poolRatio = _bpow(_tokenInRatio, _bdiv(1 ether, 2 ether));
        uint256 _newPoolSupply = _bmul(_poolRatio, _poolSupply);
        _poolAmountOut = _newPoolSupply - _poolSupply;
    }

    /**
     * @dev calculates an in amount of a token you get out when sending in a given amount of pool tokens
     * @param _tokenBalanceOut uint256 amount of token balance in the out token's pool
     * @param _poolSupply uint256 total supply of pool tokens
     * @param _poolAmountIn amount of pool tokens your sending in
     * @param _swapFee uint256 fee on top of swap
     * @return _tokenAmountOut is the uint256 amount of token out
     */
    function calcSingleOutGivenPoolIn(
        uint256 _tokenBalanceOut,
        uint256 _poolSupply,
        uint256 _poolAmountIn,
        uint256 _swapFee
    )
        public pure
        returns (uint256 _tokenAmountOut)
    {
        uint256 _normalizedWeight = _bdiv(1 ether,2 ether);
        uint256 _poolAmountInAfterExitFee = _bmul(_poolAmountIn, (BONE));
        uint256 _newPoolSupply = _poolSupply - _poolAmountInAfterExitFee;
        uint256 _poolRatio = _bdiv(_newPoolSupply, _poolSupply);
        uint256 _tokenOutRatio = _bpow(_poolRatio, _bdiv(BONE, _normalizedWeight));
        uint256 _newTokenBalanceOut = _bmul(_tokenOutRatio, _tokenBalanceOut);
        uint256 _tokenAmountOutBeforeSwapFee = _tokenBalanceOut - _newTokenBalanceOut;
        uint256 _zaz = _bmul((BONE - _normalizedWeight), _swapFee); 
        _tokenAmountOut = _bmul(_tokenAmountOutBeforeSwapFee,(BONE - _zaz));
    }

    /**
     * @dev calculates the spot price given a supply of two tokens
     * @param _tokenBalanceIn uint256 amount of tokenBalance of the in token's pool
     * @param _tokenBalanceOut uint256 amount of token balance in the out token's pool
     * @param _swapFee uint256 fee on top of swap
     * @return uint256 spot price
     */
    function calcSpotPrice(
        uint256 _tokenBalanceIn,
        uint256 _tokenBalanceOut,
        uint256 _swapFee
    )
        public pure
        returns (uint256)
    {
        uint256 _ratio =  _bdiv(_tokenBalanceIn ,_tokenBalanceOut);
        uint256 _scale = _bdiv(BONE , (BONE - _swapFee));//10e18/(10e18-fee)
        return _bmul(_ratio ,_scale);
    }

    //internal functions
    /**
     * @dev division of two numbers but adjusts as if decimals
     * @param _a numerator
     * @param _b denominator
     * @return _c2 uint256 result of division
     */
    function _bdiv(uint256 _a, uint256 _b) internal pure returns (uint256 _c2){
        require(_b != 0, "ERR_DIV_ZERO");
        uint256 _c0 = _a * BONE;
        require(_a == 0 || _c0 / _a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 _c1 = _c0 + (_b / 2);
        require(_c1 >= _c0, "ERR_DIV_INTERNAL"); //  badd require
        _c2 = _c1 / _b;
    }
    
    /**
     * @dev rounds a number down
     * @param _a number
     * @return uint256 result of rounding down
     */
    function _bfloor(uint256 _a) internal pure returns (uint256){
        return _btoi(_a) * BONE;
    }
    
    /**
     * @dev multiplication of two numbers but adjusts as if decimals
     * @param _a first number
     * @param _b second number
     * @return _c2 uint256 result of multiplication
     */
    function _bmul(uint256 _a, uint256 _b) internal pure returns (uint256 _c2){
        uint256 _c0 = _a * _b;
        require(_a == 0 || _c0 / _a == _b, "ERR_MUL_OVERFLOW");
        uint256 _c1 = _c0 + (BONE / 2);
        require(_c1 >= _c0, "ERR_MUL_OVERFLOW");
        _c2 = _c1 / BONE;
    }

    /**
     * @dev limited power function
     * @param _base base to raise
     * @param _exp or power to raise to
     * @return uint256 result of pow
     */
    function _bpow(uint256 _base, uint256 _exp) internal pure returns (uint256){
        require(_base >= 1 wei, "ERR_POW_BASE_TOO_LOW");
        require(_base <= ((2 * BONE) - 1 wei), "ERR_POW_BASE_TOO_HIGH");
        uint256 _whole  = _bfloor(_exp);   
        uint256 _remain = _exp - _whole;
        uint256 _wholePow = _bpowi(_base, _btoi(_whole));
        if (_remain == 0) {
            return _wholePow;
        }
        uint256 _partialResult = _bpowApprox(_base, _remain, BONE / 10**10);
        return _bmul(_wholePow, _partialResult);
    }

    /**
     * @dev approximate (rounds) power of two numbers
     * @param _base of exponent
     * @param _exp exponent to raise to
     * @param _precision precision with which to round to
     * @return _sum is the uint256 result of the pow
     */
    function _bpowApprox(uint256 _base, uint256 _exp, uint256 _precision) 
            internal 
            pure 
            returns (uint256 _sum)
        {
        uint256 _a = _exp;
        (uint256 _x, bool _xneg)  = _bsubSign(_base, BONE);
        uint256 _term = BONE;
        _sum = _term;
        bool _negative = false;
        for (uint256 _i = 1; _term >= _precision; _i++) {
            uint256 _bigK = _i * BONE;
            (uint256 _c, bool _cneg) = _bsubSign(_a, _bigK - BONE);
            _term = _bmul(_term, _bmul(_c, _x));
            _term = _bdiv(_term, _bigK);
            if (_term == 0) break;
            if (_xneg) _negative = !_negative;
            if (_cneg) _negative = !_negative;
            if (_negative) {
                _sum = _sum - _term;
            } else {
                _sum = _sum + _term;
            }
        }
    }

    /**
     * @dev raises one number to the other and adjusts as if decimals
     * @param _a base
     * @param _n exponent
     * @return _z uint256 result of pow
     */
    function _bpowi(uint256 _a, uint256 _n) internal pure returns (uint256 _z){
        _z = _n % 2 != 0 ? _a : BONE;
        for (_n /= 2; _n != 0; _n /= 2) {
            _a = _bmul(_a, _a);
            if (_n % 2 != 0) {
                _z = _bmul(_z, _a);
            }
        }
    }

    /**
     * @dev subtraction of a number from one, but turns into abs function if neg result
     * @param _a base
     * @param _b number to subtract
     * @return uint256 result and boolean if negative
     */
    function _bsubSign(uint256 _a, uint256 _b) internal pure returns (uint256, bool){
        if (_a >= _b) {
            return (_a - _b, false);
        } else {
            return (_b - _a, true);
        }
    }

    /**
     * @dev divides a number by BONE (1e18)
     * @param _a numerator
     * @return uint256 result
     */
    function _btoi(uint256 _a) internal pure returns (uint256){
        return _a / BONE;
    }
}

interface ICFC {
    function addFees(uint256 _amount, bool _isCHD) external;
}

interface IOracle {
    function getCommitment(uint256 _chain, address _partnerContract, uint256 _depositId) external view returns(bytes memory, address);
}

interface IERC20 {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from,address _to,uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IVerifier {
 function verifyProof(uint[2] memory _a,uint[2][2] memory _b,uint[2] memory _c,uint[8] memory _input) external view returns(bool);
 function verifyProof(uint[2] memory _a,uint[2][2] memory _b,uint[2] memory _c,uint[22] memory _input) external view returns(bool);
}

/**
 @title charon
 @dev charon is a decentralized protocol for a Privacy Enabled Cross-Chain AMM (PECCAMM). 
 * it achieves privacy by breaking the link between deposits on one chain and withdrawals on another. 
 * it creates AMM's on multiple chains, but LP deposits in one of the assets and all orders are 
 * only achieved via depositing in alternate chains and then withdrawing as either an LP or market order.
 * to acheive cross-chain functionality, Charon utilizes tellor to pass commitments between chains.
//                                            /                                      
//                               ...      ,%##                                     
//                             /#/,/.   (%#*.                                     
//                            (((aaaa(   /%&,                                      
//                           #&##aaaa#   &#                                        
//                        /%&%%a&aa%%%#/%(*                                        
//                    /%#%&(&%&%&%&##%/%((                                         
//                  ,#%%/#%%%&#&###%#a&/((                                         
//                     (#(##%&a#&&%&a%(((%.                                ,/.    
//                     (/%&&a&&&#%a&(#(&&&/                             ,%%%&&%#,  
//                    ,#(&&&a&&&&aa%(#%%&&/                            *#%%%&%&%(  
//                   *##/%%aaaaaaa/&&&(&*&(/                           (#&%,%%&/   
//                 #((((#&#aaa&aa/#aaaaa&(#(                           /#%#,..  .  
//                  /##%(##aaa&&(#&a#&#&&a&(                           ,%&a//##,,* 
//               ,(#%###&((%aa%#&a&aa#&&#a#,                            %%%/,    . 
//               ,(#%/a#&#%&aa%&a&&a&(##/                               ##(a%##%## 
//                   *   %%(/%%&&a&&&%&#*                               #&&*#(,%&#&
//                      ((#&%&%##a#&%&&#,*                              .##(%a%aa( 
//                    .(#&##&%%%a%&%%((a&/.                              %&a%&(((*,
//                    *#%(%&%&&a&&&##&/,&a%(                            .%&%%&a&%/ 
//               ((((%%&(#%%%%a#&&(%&%%#/aa&(                           %&%#(#*(   
//             (%((&/#%##&%#%a(aa(%a&%&(*&a&/                         #%&&&%(#&/(  
//                (&aa#%a&&a%&aa/%a&&&%%#(a                         #&&&##%a/a%(/  
//            ///(%aa#%aa&%%aa&a(&a&a#&#(%a#                     (%%%&&a#&((&&%    
//             %aaaaa%&a&(&a&&##&&aa%(&&##%&#/           ,(((%%%%%%&%%&%##%&%.    
//   /(((//(* ,#%%#(&%a%&&&##(%%aa&a&##&%%&aaaaaaaa&(#%%%%#%&%%%%#%&%##%%#%#.     
//    ###(((##(//((#%a(////((#((#####(##%#(%&%#%%%#(%&&%%%%%#/%%%%(//%(##%%#       
//      /(##&%%#(((%&a%%#%#########%%%%%%%%%&%%%#%((#(%&%%(##(///%#%#%%&%#         
//        ,&aaaa&&%&&&a&&%#####%%%%%%%&%%&%#%##(#####(####%&##%&&&&&&&&#           
//   ////(%&&aaa(%aaaaaaaaaaa&aaaaaaaaaaaaaaaaaa&&&&a&a&a&aaaaaaaaa&              
//  (((((#(//(#%##%&&a&&&&aaa&&aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa%////(//,.       
//         ,##%%%%%%%%%%#%####(((/(%&&&&&&%%&&&&&aaaa&&aa&&&&&aaa&#%%%#///**%%(    
//                             ./%%%#%%%%%%%%%%%%%%%%%%%(((####%###((((#(*,,*(*    
//                                                   ,*#%%###(##########(((,    
*/
contract Charon is Math, MerkleTreeWithHistory, Token{

    /*storage*/
    struct PartnerContract{
      uint256 chainID;//EVM chain ID
      address contractAddress;//contract address of partner contract on given chain
    }

    struct ExtData {
      address recipient;//party recieving CHD
      int256 extAmount;//amount being sent
      address relayer;//relayer of signed message (adds anonymity)
      uint256 fee;//fee given to relayer
      bytes encryptedOutput1;//encrypted UTXO output of txn
      bytes encryptedOutput2;//other encrypted UTXO of txn (must spend all in UTXO design)
    }

    struct Commitment{
      ExtData extData;
      Proof proof;
    }

    struct Proof {
      bytes proof;//proof generated by groth16.fullProve()
      bytes32 root;//root of the merkleTree that contains your commmitment
      uint256 extDataHash;//hash of extData (to prevent relayer tampering)
      uint256 publicAmount;//amount you expect out (extAmount - fee)
      bytes32[] inputNullifiers;//nullifiers of input UTXOs (hash of amount, keypair, blinding, index, etc.)
      bytes32[2] outputCommitments;//hash of amount,keypair, bindings of output UTXOs
    }

    CHD public chd;//address/implementation of chd token
    IERC20 public immutable token;//base token address/implementation for the charonAMM
    IOracle public immutable oracle;//address of the oracle to use for the system
    IVerifier public immutable verifier2; //implementation/address of the two input veriifier contract
    IVerifier public immutable verifier16;//implementation/address of the sixteen input veriifier contract
    Commitment[] depositCommitments;//all commitments deposited by tellor in an array.  depositID is the position in array
    PartnerContract[] partnerContracts;//list of connected contracts for this deployment
    address public controller;//controller adddress (used for initializing contracts, then should be CFC for accepting fees)
    bool public finalized;//bool if contracts are initialized
    uint256 public immutable chainID; //chainID of this charon instance
    uint256 public immutable fee;//fee when liquidity is withdrawn or trade happens (1e18 = 100% fee)
    uint256 public recordBalance;//balance of asset stored in this contract
    uint256 public recordBalanceSynth;//balance of asset bridged from other chain
    uint256 public userRewards;//amount of baseToken user rewards in contract
    uint256 public userRewardsCHD;//amount of chd user rewards in contract
    uint256 public oracleTokenFunds;//amount of token funds to be paid to reporters
    uint256 public oracleCHDFunds;//amount of chd funds to be paid to reporters
    mapping(bytes32 => uint256) public depositIdByCommitmentHash;//gives you a deposit ID (used by tellor) given a commitment
    mapping(bytes32 => bool) public nullifierHashes;//zk proof hashes to tell whether someone withdrew

    //events
    event DepositToOtherChain(bool _isCHD, address _sender, uint256 _timestamp, uint256 _tokenAmount);
    event LPDeposit(address _lp,uint256 _poolAmountOut);
    event RewardAdded(uint256 _amount,bool _isCHD);
    event LPWithdrawal(address _lp, uint256 _poolAmountIn);
    event NewCommitment(bytes32 _commitment, uint256 _index, bytes _encryptedOutput);
    event NewNullifier(bytes32 _nullifier);
    event OracleDeposit(uint256 _chain,address _contract, uint256[] _depositId);
    event Swap(address _user,bool _inIsCHD,uint256 _tokenAmountIn,uint256 _tokenAmountOut);

    //modifiers
    /**
     * @dev requires a function to be finalized or the caller to be the controlller
    */
    modifier _finalized_() {
      if(!finalized){require(msg.sender == controller);}_;
    }

    /**
     * @dev constructor to launch charon
     * @param _verifier2 address of the verifier contract (circom generated sol)
     * @param _verifier16 address of the verifier contract (circom generated sol)
     * @param _hasher address of the hasher contract (mimC precompile)
     * @param _token address of token on this chain of the system
     * @param _fee fee when withdrawing liquidity or trading (pct of tokens)
     * @param _oracle address of oracle contract
     * @param _merkleTreeHeight merkleTreeHeight (should match that of circom compile)
     * @param _chainID chainID of this chain
     * @param _name name of pool token
     * @param _symbol of pool token
     */
    constructor(address _verifier2,
                address _verifier16,
                address _hasher,
                address _token,
                uint256 _fee,
                address _oracle,
                uint32 _merkleTreeHeight,
                uint256 _chainID,
                string memory _name,
                string memory _symbol
                )
              MerkleTreeWithHistory(_merkleTreeHeight, _hasher)
              Token(_name,_symbol){
        verifier2 = IVerifier(_verifier2);
        verifier16 = IVerifier(_verifier16);
        token = IERC20(_token);
        fee = _fee;
        controller = msg.sender;
        chainID = _chainID;
        oracle = IOracle(_oracle);
    }

    /**
     * @dev allows the cfc (or anyone) to add LPrewards to the system
     * @param _toUsers uint256 of tokens to add to Users
     * @param _toLPs uint256 of tokens to add to LPs
     * @param _toOracle uint256 of tokens to add to Oracle
     * @param _isCHD bool if the token is chd (baseToken if false)
     */
    function addRewards(uint256 _toUsers, uint256 _toLPs, uint256 _toOracle,bool _isCHD) external{
      if(_isCHD){
        require(chd.transferFrom(msg.sender,address(this),_toUsers + _toLPs + _toOracle));
        recordBalanceSynth += _toLPs;
        oracleCHDFunds += _toOracle;
        userRewardsCHD += _toUsers;
      }
      else{
        require(token.transferFrom(msg.sender,address(this),_toUsers + _toLPs + _toOracle));
        recordBalance += _toLPs;
        oracleTokenFunds += _toOracle;
        userRewards += _toUsers;
      }
      emit RewardAdded(_toUsers + _toLPs + _toOracle,_isCHD);
    }

    /**
     * @dev Allows the controller to change their address
     * @param _newController new controller.  Should be CFC
     */
    function changeController(address _newController) external{
      require(msg.sender == controller,"should be controller");
      controller = _newController;
    }

    /**
     * @dev function for user to lock tokens for lp/trade on other chain
     * @param _proofArgs proofArgs of deposit commitment generated by zkproof
     * @param _extData data pertaining to deposit
     * @param _isCHD whether deposit is CHD, false if base asset deposit
     * @return _depositId returns the depositId (position in commitment array)
     */
    function depositToOtherChain(Proof memory _proofArgs,ExtData memory _extData, bool _isCHD) external _finalized_ returns(uint256 _depositId){
        Commitment memory _c = Commitment(_extData,_proofArgs);
        depositCommitments.push(_c);
        _depositId = depositCommitments.length;
        bytes32 _hashedCommitment = keccak256(abi.encode(_proofArgs.proof,_proofArgs.publicAmount,_proofArgs.root));
        depositIdByCommitmentHash[_hashedCommitment] = _depositId;
        uint256 _tokenAmount = 0;
        if (_isCHD){
          chd.burnCHD(msg.sender,uint256(_extData.extAmount));
        }
        else{
          _tokenAmount = calcInGivenOut(recordBalance,recordBalanceSynth,uint256(_extData.extAmount),0);
          require(token.transferFrom(msg.sender, address(this), _tokenAmount));
        }
        uint256 _min = userRewards / 1000;
        if(_min > 0){
          if (_min > _tokenAmount / 50){
            _min = _tokenAmount / 50;
          }
          token.transfer(msg.sender, _min);
          userRewards -= _min;
        }
        _min = userRewardsCHD / 1000;
        if(_min > 0){
          if (_min > _tokenAmount / 50){
            _min = _tokenAmount / 50;
          }
          chd.transfer(msg.sender, _min);
          userRewardsCHD -= _min;
        }
        recordBalance += _tokenAmount;
        emit DepositToOtherChain(_isCHD,msg.sender, block.timestamp, _tokenAmount);
    }

    /**
     * @dev Allows the controller to start the system
     * @param _partnerChains list of chainID's in this Charon system
     * @param _partnerAddys list of corresponding addresses of charon contracts on chains in _partnerChains
     * @param _balance balance of _token to initialize AMM pool
     * @param _synthBalance balance of token on other side of pool initializing pool (sets initial price)
     * @param _chd address of deployed chd token
     */
    function finalize(uint256[] memory _partnerChains,
                      address[] memory _partnerAddys,
                      uint256 _balance,
                      uint256 _synthBalance, 
                      address _chd) 
                      external{
        require(msg.sender == controller, "should be controller");
        require(!finalized, "should be finalized");
        finalized = true;
        recordBalance = _balance;
        recordBalanceSynth = _synthBalance;
        chd = CHD(_chd);
        require (token.transferFrom(msg.sender, address(this), _balance));
        chd.mintCHD(address(this),_synthBalance);
        _mint(msg.sender,100 ether);
        require(_partnerAddys.length == _partnerChains.length, "length should be the same");
        for(uint256 _i; _i < _partnerAddys.length; _i++){
          partnerContracts.push(PartnerContract(_partnerChains[_i],_partnerAddys[_i]));
        } 
    }

    /**
     * @dev Allows a user to deposit as an LP on this side of the AMM
     * @param _poolAmountOut amount of pool tokens to recieve
     * @param _maxCHDIn max amount of CHD to send to contract
     * @param _maxBaseAssetIn max amount of base asset to send in
     */
    function lpDeposit(uint256 _poolAmountOut, uint256 _maxCHDIn, uint256 _maxBaseAssetIn)
        external
        _finalized_
    {   
        uint256 _ratio = _bdiv(_poolAmountOut, supply);
        require(_ratio > 0, "should not be 0 for inputs");
        uint256 _baseAssetIn = _bmul(_ratio, recordBalance);
        require(_baseAssetIn <= _maxBaseAssetIn, "too big baseDeposit required");
        recordBalance = recordBalance + _baseAssetIn;
        uint256 _CHDIn = _bmul(_ratio, recordBalanceSynth);
        require(_CHDIn <= _maxCHDIn, "too big chd deposit required");
        recordBalanceSynth = recordBalanceSynth + _CHDIn;
        _mint(msg.sender,_poolAmountOut);
        require (token.transferFrom(msg.sender,address(this), _baseAssetIn));
        require(chd.transferFrom(msg.sender, address(this),_CHDIn));
        emit LPDeposit(msg.sender,_poolAmountOut);
    }

    /**
     * @dev allows a user to single-side LP CHD 
     * @param _tokenAmountIn amount of CHD to deposit
     * @param _minPoolAmountOut minimum number of pool tokens you need out
     */
    function lpSingleCHD(uint256 _tokenAmountIn,uint256 _minPoolAmountOut) external _finalized_{
        uint256 _poolAmountOut = calcPoolOutGivenSingleIn(
                            recordBalanceSynth,//pool tokenIn balance
                            supply,
                            _tokenAmountIn//amount of token In
                        );
        recordBalanceSynth += _tokenAmountIn;
        require(_poolAmountOut >= _minPoolAmountOut, "not enough squeeze");
        _mint(msg.sender,_poolAmountOut);
        require (chd.transferFrom(msg.sender,address(this), _tokenAmountIn));
        emit LPDeposit(msg.sender,_poolAmountOut);
    }

    /**
     * @dev Allows an lp to withdraw funds
     * @param _poolAmountIn amount of pool tokens to transfer in
     * @param _minCHDOut min aount of chd you need out
     * @param _minBaseAssetOut min amount of base token you need out
     * @return _tokenAmountOut amount of tokens recieved
     */
    function lpWithdraw(uint256 _poolAmountIn, uint256 _minCHDOut, uint256 _minBaseAssetOut)
        external
        _finalized_
        returns (uint256 _tokenAmountOut)
    {
        uint256 _exitFee = _bmul(_poolAmountIn, fee);
        uint256 _pAiAfterExitFee = _poolAmountIn - _exitFee;
        uint256 _ratio = _bdiv(_pAiAfterExitFee, supply);
        _burn(msg.sender,_pAiAfterExitFee);//burning the total amount, but not taking out the tokens that are fees paid to the LP
        _tokenAmountOut = _bmul(_ratio, recordBalance);
        require(_tokenAmountOut != 0, "ERR_MATH_APPROX");
        require(_tokenAmountOut >= _minBaseAssetOut, "ERR_LIMIT_OUT");
        recordBalance = recordBalance - _tokenAmountOut;
        uint256 _CHDOut = _bmul(_ratio, recordBalanceSynth);
        require(_CHDOut != 0, "ERR_MATH_APPROX");
        require(_CHDOut >= _minCHDOut, "ERR_LIMIT_OUT");
        recordBalanceSynth = recordBalanceSynth - _CHDOut;
        require(token.transfer(msg.sender, _tokenAmountOut));
        require(chd.transfer(msg.sender, _CHDOut));
        emit LPWithdrawal(msg.sender, _poolAmountIn);
        //now transfer exit fee to CFC
        if(_exitFee > 0){
          _ratio = _bdiv(_exitFee, supply);
          _burn(msg.sender,_exitFee);//burning the total amount, but not taking out the tokens that are fees paid to the LP
          _tokenAmountOut = _bmul(_ratio, recordBalance);
          recordBalance = recordBalance - _tokenAmountOut;
          _CHDOut = _bmul(_ratio, recordBalanceSynth);
           recordBalanceSynth = recordBalanceSynth - _CHDOut;
          token.approve(address(controller),_tokenAmountOut);
          ICFC(controller).addFees(_tokenAmountOut,false);
          chd.approve(address(controller),_CHDOut);
          ICFC(controller).addFees(_CHDOut,true);
        }
    }

   /**
     * @dev allows a user to single-side LP withdraw CHD 
     * @param _poolAmountIn amount of pool tokens to deposit
     * @param _minAmountOut minimum amount of CHD you need out
     */
    function lpWithdrawSingleCHD(uint256 _poolAmountIn, uint256 _minAmountOut) external _finalized_{
        uint256 _tokenAmountOut = calcSingleOutGivenPoolIn(
                            recordBalanceSynth,
                            supply,
                            _poolAmountIn,
                            fee
                        );
        recordBalanceSynth -= _tokenAmountOut;
        require(_tokenAmountOut >= _minAmountOut, "not enough squeeze");
        uint256 _exitFee = _bmul(_poolAmountIn, fee);
        _burn(msg.sender,_poolAmountIn - _exitFee);
        require(chd.transfer(msg.sender, _tokenAmountOut));
        emit LPWithdrawal(msg.sender,_poolAmountIn);
        if(_exitFee > 0){
          _burn(msg.sender,_exitFee);//burning the total amount, but not taking out the tokens that are fees paid to the LP
          uint256 _CHDOut =calcSingleOutGivenPoolIn(
                            recordBalanceSynth,
                            supply,
                            _exitFee,
                            fee
                        );
          recordBalanceSynth = recordBalanceSynth - _CHDOut;
          chd.approve(address(controller),_CHDOut);
          ICFC(controller).addFees(_CHDOut,true);
        }
    }

    /**
     * @dev reads tellor commitments to allow you to withdraw on this chain
     * @param _depositId depositId of deposit on that chain
    * @param _partnerIndex index of contract in partnerContracts array
     */
    function oracleDeposit(uint256[] memory _depositId,uint256 _partnerIndex) external{
        Proof memory _proof;
        ExtData memory _extData;
        bytes memory _value;
        address _reporter;
        PartnerContract storage _p = partnerContracts[_partnerIndex];
        for(uint256 _i; _i<=_depositId.length-1; _i++){
          (_value,_reporter) = oracle.getCommitment(_p.chainID, _p.contractAddress, _depositId[_i]);
          _proof.inputNullifiers = new bytes32[](2);
          (_proof.inputNullifiers[0], _proof.inputNullifiers[1], _proof.outputCommitments[0], _proof.outputCommitments[1], _proof.proof) = abi.decode(_value,(bytes32,bytes32,bytes32,bytes32,bytes));
          _transact(_proof, _extData);
          //you need this amount to be less than the stake amount, but if this is greater than the gas price to deposit and then report, you don't need to worry about it
          if(oracleCHDFunds > 1000){
            chd.transfer(_reporter,oracleCHDFunds/1000);
          }
          if(oracleTokenFunds > 1000){
            token.transfer(_reporter,oracleTokenFunds/1000);
          }
        }
        emit OracleDeposit(_p.chainID,_p.contractAddress,_depositId);
    }

    /**
     * @dev withdraw your tokens from deposit on alternate chain
     * @param _inIsCHD bool if token sending in is CHD
     * @param _tokenAmountIn amount of token to send in
     * @param _minAmountOut minimum amount of out token you need
     * @param _maxPrice max price you're willing to send the pool too
     */
    function swap(
        bool _inIsCHD,
        uint256 _tokenAmountIn,
        uint256 _minAmountOut,
        uint256 _maxPrice
    )
        external _finalized_
        returns (uint256 _tokenAmountOut, uint256 _spotPriceAfter){
        uint256 _inRecordBal;
        uint256 _outRecordBal;
        uint256 _exitFee = _bmul(_tokenAmountIn, fee);
        if(_inIsCHD){
           _inRecordBal = recordBalanceSynth;
           _outRecordBal = recordBalance;
        } 
        else{
          _inRecordBal = recordBalance;
          _outRecordBal = recordBalanceSynth;
        }
        require(_tokenAmountIn <= _bmul(_inRecordBal, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");
        uint256 _spotPriceBefore = calcSpotPrice(
                                    _inRecordBal,
                                    _outRecordBal,
                                    fee
                                );
        require(_spotPriceBefore <= _maxPrice, "ERR_BAD_LIMIT_PRICE");
        _tokenAmountOut = calcOutGivenIn(
                            _inRecordBal,
                            _outRecordBal,
                            _tokenAmountIn,
                            fee
                        );
        require(_tokenAmountOut >= _minAmountOut, "ERR_LIMIT_OUT");
        require(_spotPriceBefore <= _bdiv(_tokenAmountIn, _tokenAmountOut), "ERR_MATH_APPROX");
        _outRecordBal = _outRecordBal - _tokenAmountOut;
        if(_inIsCHD){
           require(chd.burnCHD(msg.sender,_tokenAmountIn));
           require(token.transfer(msg.sender,_tokenAmountOut));
           recordBalance -= _tokenAmountOut;
           if(_exitFee > 0){
            chd.approve(address(controller),_exitFee);
            ICFC(controller).addFees(_exitFee,true);
           }
        } 
        else{
          _inRecordBal = _inRecordBal + _tokenAmountIn;
          require(token.transferFrom(msg.sender,address(this), _tokenAmountIn));
          require(chd.transfer(msg.sender,_tokenAmountOut));
          recordBalance += _tokenAmountIn;
          recordBalanceSynth -= _tokenAmountOut;
          if(fee > 0){
            token.approve(address(controller),_exitFee);
            ICFC(controller).addFees(_exitFee,false);
          }
        }
        _spotPriceAfter = calcSpotPrice(
                                _inRecordBal,
                                _outRecordBal,
                                fee
                            );
        require(_spotPriceAfter >= _spotPriceBefore, "ERR_MATH_APPROX");     
        require(_spotPriceAfter <= _maxPrice, "ERR_LIMIT_PRICE");
        emit Swap(msg.sender,_inIsCHD,_tokenAmountIn,_tokenAmountOut);
      }

      /**
      * @dev allows users to send chd anonymously
      * @param _args proof data for sneding tokens
      * @param _extData external (visible data) to verify proof and pay relayer fee
      */
      function transact(Proof memory _args, ExtData memory _extData) external _finalized_{
        int256 _publicAmount = _extData.extAmount - int256(_extData.fee);
        if(_publicAmount < 0){
          _publicAmount = int256(FIELD_SIZE - uint256(-_publicAmount));
        } 
        require(_args.publicAmount == uint256(_publicAmount), "Invalid public amount");
        require(isKnownRoot(_args.root), "Invalid merkle root");
        require(_verifyProof(_args), "Invalid transaction proof");
        require(uint256(_args.extDataHash) == uint256(keccak256(abi.encode(_extData))) % FIELD_SIZE, "Incorrect external data hash");
        if (_extData.extAmount < 0){
          require(chd.mintCHD(_extData.recipient, uint256(-_extData.extAmount)));
        }
        if(_extData.fee > 0){
          require(chd.mintCHD(_extData.relayer,_extData.fee));
        }
        _transact(_args, _extData);
    }

    //getters
    /**
     * @dev allows you to find a commitment for a given depositId
     * @param _id deposidId of your commitment
     */
    function getDepositCommitmentsById(uint256 _id) external view returns(Commitment memory){
      return depositCommitments[_id - 1];
    }

    /**
     * @dev allows you to find a depositId for a given commitment
     * @param _commitment the commitment of your deposit
     */
    function getDepositIdByCommitmentHash(bytes32 _commitment) external view returns(uint256){
      return depositIdByCommitmentHash[_commitment];
    }

    /**
     * @dev returns the data for an oracle submission on another chain given a depositId
     */
    function getOracleSubmission(uint256 _depositId) external view returns(bytes memory _value){
      Proof memory _p = depositCommitments[_depositId-1].proof;
      _value = abi.encode(
        _p.inputNullifiers[0],
        _p.inputNullifiers[1],
        _p.outputCommitments[0],
        _p.outputCommitments[1],
        _p.proof);
    }

    /**
     * @dev returns the partner contracts in this charon system and their chains
     */
    function getPartnerContracts() external view returns(PartnerContract[] memory){
      return partnerContracts;
    }

    /**
     * @dev allows you to check the spot price of the token pair
     * @return _spotPrice uint256 price of the pair
     */
    function getSpotPrice() external view returns(uint256 _spotPrice){
      return calcSpotPrice(recordBalanceSynth,recordBalance, 0);
    }

    /**
     * @dev allows you to check the token pair addresses of the pool
     * @return _chd address of chd token
     * @return _token address of baseToken
     */
    function getTokens() external view returns(address _chd, address _token){
      return (address(chd), address(token));
    }

    /**
     * @dev allows a user to see if their deposit has been withdrawn
     * @param _nullifierHash hash of nullifier identifying withdrawal
     */
    function isSpent(bytes32 _nullifierHash) external view returns (bool) {
      return nullifierHashes[_nullifierHash];
    }

    //internal functions
    /**
     * @dev internal logic of secret transfers and chd mints
     * @param _args proof data for sneding tokens
     * @param _extData external (visible data) to verify proof and pay relayer fee
     */
    function _transact(Proof memory _args, ExtData memory _extData) internal{
      for (uint256 _i = 0; _i < _args.inputNullifiers.length; _i++) {
        require(!nullifierHashes[_args.inputNullifiers[_i]], "Input is already spent");
        nullifierHashes[_args.inputNullifiers[_i]] = true;
        emit NewNullifier(_args.inputNullifiers[_i]);
      }
      _insert(_args.outputCommitments[0], _args.outputCommitments[1]);
      emit NewCommitment(_args.outputCommitments[0], nextIndex - 2, _extData.encryptedOutput1);
      emit NewCommitment(_args.outputCommitments[1], nextIndex - 1, _extData.encryptedOutput2);
    }

    /**
     * @dev internal fucntion for verifying proof's for secret txns
     * @param _args proof data for seending tokens
     * @return bool of whether proof is verified
     */
    function _verifyProof(Proof memory _args) internal view returns (bool) {
      uint[2] memory _a;
      uint[2][2] memory _b;
      uint[2] memory _c;
      (_a,_b,_c) = abi.decode(_args.proof,(uint[2],uint[2][2],uint[2]));
      if (_args.inputNullifiers.length == 2) {
        return
          verifier2.verifyProof(
            _a,_b,_c,
            [
              uint256(_args.root),
              _args.publicAmount,
              chainID,
              uint256(_args.extDataHash),
              uint256(_args.inputNullifiers[0]),
              uint256(_args.inputNullifiers[1]),
              uint256(_args.outputCommitments[0]),
              uint256(_args.outputCommitments[1])
            ]
          );
      } else if (_args.inputNullifiers.length == 16) {
        return
          verifier16.verifyProof(
            _a,_b,_c,
            [
              uint256(_args.root),
              _args.publicAmount,
              chainID,
              uint256(_args.extDataHash),
              uint256(_args.inputNullifiers[0]),
              uint256(_args.inputNullifiers[1]),
              uint256(_args.inputNullifiers[2]),
              uint256(_args.inputNullifiers[3]),
              uint256(_args.inputNullifiers[4]),
              uint256(_args.inputNullifiers[5]),
              uint256(_args.inputNullifiers[6]),
              uint256(_args.inputNullifiers[7]),
              uint256(_args.inputNullifiers[8]),
              uint256(_args.inputNullifiers[9]),
              uint256(_args.inputNullifiers[10]),
              uint256(_args.inputNullifiers[11]),
              uint256(_args.inputNullifiers[12]),
              uint256(_args.inputNullifiers[13]),
              uint256(_args.inputNullifiers[14]),
              uint256(_args.inputNullifiers[15]),
              uint256(_args.outputCommitments[0]),
              uint256(_args.outputCommitments[1])
            ]
          );
      } else {
        revert("unsupported input count");
      }
  }
}