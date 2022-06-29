/// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.15;

import "./LiquidProtocolManager.sol";

/*

                                  .+...../////////////,.......                                      
                            .....+//////////////////////////////,....,                              
                        ...,/////////// //  /#/////  (//    //////////...                           
                    ,..////////  (//   ,//  #(//// #( //    (/  /(/  ,///+..                        
                  ../////   /// /  // (( /(  #///((//# / ////% ////  /////...                       
                ..//// , / ( #/ (////////   ////  //   %// (//////    ////+..                       
                ..///// &/ (/////% /// #./ %///(.( / / ,/ / /% /  /(///////...                      
               ...////////(#/+ ( /+/// /(,//////////////%// / //  % ///////./..                     
               .../////// /& (( ////+......,++////////+,.......//( ////////.//..                    
               .,./////////  //....//////////////////////////////....//////.+/...,                  
              ../.,////////...///////,........................,///////...//+.//.....+               
              +.//.////,..//////....................................//////...//..#,.....            
              ..//./.../////............................................/////..+.      ,..          
       ....(  ..//..,////..................................................////..........%..        
    ..,   .../..+.+///,...............         +/  #..+......................,/........... ..       
   .. ...........///,............,(/,     /+   .+(,            ...........................  ..      
   ., .....+ .................                                     .....................     .      
  (.. ..    .......,.......  #.         .  .  %    ..+.........  #   +................./     .      
   ..      +......+.......     .........................................................    #.,     
   ...   ................   .............../ + ........................................,    ..      
   ,../  .....   ........ , ....... ..#..       .....,....++.,.......................,    ,..       
    ,../  .....  ........  . .,      ,.+    /.......      ..(//  /+ .,................,,..(         
      ..(    ,# #........    ,         ( %       ...,#.          . /.+.+...............             
       ...      ........./             . ,     +      .+  .+(...+    .................              
          ................        +.. //     .           ...+#..  .++...............+               
             ,,...........(    .,#..//   #..        ..     ............+.......+.,..                
                .......,....    ./ .(    (...,++,....,    . +..........,,......, ...                
                  ......(..       ..            ...,  , (#    ...........#.....,...                 
                  +......#.,.  .                                #............,.....                 
                   ,......,......                                ........,........                  
                    +.......,...                                  ................                  
                     +..........                                 .,..............                   
                       .........    ,,           +(,.........(    ..............                    
                       ..........+       +.........,(.           . ..........,+                     
                       (........,.                               +,.........                        
                          ........                           +, .........+                          
                           .......                           ...........,                           
                              .......   #          ., %../...........+                              
                                 ,....(.. , .   +  +,. ..(,......+                                  
                                     ,..../  +. /............,..                                    
                                           (.............


                                     
                                      S e e   N o   E v i l 

*/

// SECTION LiquidToken implementation

/* ********************+******** 

Actual Implementation

****************************** */

contract LiquidToken is iNFToken {
  /// @dev Library using fast array manipulation methods for unsorted arrays
  using ArrayDegas for uint16[];

  bool SetRarityAtMint = false;
  uint256 MaxNftMintable;

  constructor(
    string memory _name_,
    string memory _symbol,
    uint256 max__
  ) ERC721E(NFTName, NFTicker) {

    // Bridging actors to manager
    derived.router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    derived.router = IUniswapV2Router02(derived.router_address);
    derived.factory_address = derived.router.factory();
    derived.factory = IUniswapV2Factory(derived.factory_address);
    derived.pair_address =  derived.factory.createPair(address(this), derived.router.WETH());
    derived.pair = IUniswapV2Pair(derived.pair_address);
    derived.owner = msg.sender;

    // Basic metadata
    name = _name_;
    symbol = _symbol;
    derived.owner = msg.sender;
    derived.is_auth[msg.sender] == true;

    // Specific NFT metadata
    MaxNftMintable = max__;
    NFTName = name;
    NFTicker = symbol;
    mint(1);
    _setBaseURI(
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    );
  }

  // SECTION Mixed Functions
  /* ==================================================================================================== */
  /* ==================================================================================================== */
  /* ========================================= Mixed Functions ========================================== */
  /* ==================================================================================================== */
  /* ==================================================================================================== */

  /*
    This first part defines the functions having the same name in both the standards
    so to avoid shadowing and to execute necessary functions together in any case.
    Also contains functions that applies to both the ERC20 and the ERC721 token sides.
    */


  // totalSupply() is reserved for ERC20 unless we overload that
  function totalSupply()
    public
    view
    override
    returns (uint256 tkn)
  {
    uint256 _tkn = ERCtotalSupply;

    return (_tkn);
  }

  function balanceOf(address _owner)
    public
    view
    override
    returns (uint256 tkn)
  {
    uint256 _tkn = ERCbalanceOf(_owner);
    // NOTE Is assumed that token balance is equal to NFT balance. Uncomment the following line to enforce a check
    // require(_tkn == NFTbalanceOf(_owner), "Token and NFT balances mismatch");
    return (_tkn);
  }

  // To support the compatible transferFrom function, we need to call _NFT_blk_transfer to derive X random IDs
  // NOTE Important: with such an implementation, is mandatory to take in account the fact that from != msg.sender once the contract calls a sub-method, thus allowances and permissions may need a tweak
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool tkn) {

    bool success;

    // msg.sender is the value to check as the "real" from, as to say the one that initiate the stuff
    bool is_liquidity_transfer = ((msg.sender == derived.pair_address && to == derived.router_address)
    || (to == derived.pair_address && msg.sender == derived.router_address));

    if(!is_liquidity_transfer) {
      // msg.sender is passed to the ERC function to enable allowance check for the real message sender
      success = ERCtransferFrom(from, to, amount, msg.sender);
    } else {
      // Liquidity transfers are handled differently so to make them as smooth as possible
      success = liquidityERCtransferFrom(from, to, amount);
    }
    // An equal amount of NFTs are transferred to the destination
    _NFT_controlled_transfer(from, to, amount, is_liquidity_transfer);

    return (success);
  }

  function owner_of_nft(uint256 id)
    public
    view
    returns (address ownerOfTokenId)
  {
    return address(uint160(_packedOwnershipOf(id)));
  }

  // REVIEW Liquidity can now be added
  // FIXME Liquidity can't be increased?
  function transfer(address _to, uint256 _value)
    public
    override
    safe
    returns (bool success)
  {
    // Standard ERC transfer
    bool _success = ERC_transfer(_to, _value);
    require(_success, "transfer failed");

    // Catch liquidity transfers
    bool is_liquidity_transfer = ((msg.sender == derived.pair_address  && _to == derived.router_address)
    || (_to == derived.pair_address && msg.sender == derived.router_address));

    // Allows to set multiple conditions
    bool is_auto_allowed = is_liquidity_transfer; 


    // Execute a NFT transfer for each token transferred: wrapper for _NFT_transfer
    _NFT_controlled_transfer(msg.sender, _to, _value, is_auto_allowed);

    return _success;
  }

  /* Admin Functions */

  /// @dev Native token paired price for target
  function getTokenPrice(uint256 amount) public view returns (uint256) {
    (uint256 Res0, uint256 Res1, uint256 timestamp) = derived.pair.getReserves();
    if (Res0 == 0 && Res1 == 0) {
      return 0;
    }
    uint256 res0 = Res0;
    delete timestamp;
    return ((amount * res0) / Res1); // return amount of token0 needed to buy token1
  }

  uint256 coinPrice;

  // !SECTION

  // SECTION ERC20 Compatibility
  /* ==================================================================================================== */
  /* ==================================================================================================== */
  /* ============================================ ERC20 Part ============================================ */
  /* ==================================================================================================== */
  /* ==================================================================================================== */

  /*
    This part defines all the ERC20 standard properties
    */

  address Dead = 0x000000000000000000000000000000000000dEaD;

  uint256 private constant MAX_UINT256 = 2**256 - 1;
  mapping(address => uint256) public _balances;
  mapping(address => mapping(address => uint256)) public allowed;
  uint256 public ERCtotalSupply;
  /*
    NOTE Default variables inclusion

    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
  string public name; // "LiquidToken";
  string public symbol; // "$LPT";

  string public NFTName;
  string public NFTicker;

  function ERC_transfer(address _to, uint256 _value)
    internal
    returns (bool success)
  {
    require(
      _balances[msg.sender] >= _value,
      "token balance is lower than the value requested"
    );
    _balances[msg.sender] -= _value;
    _balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
    return true;
  }

  /// @dev Internal minting to allow NFT and ERC20 sync
  function mintToken(address _to, uint256 _value) internal {
    _balances[_to] += _value;
    ERCtotalSupply += _value;
    emit Transfer(Dead, _to, _value);
  }

  /// @dev Internal burning to allow NFT and ERC20 sync
  function burnToken(address _from, uint256 _value) internal {
    require(
      (_balances[_from] >= _value) && (ERCtotalSupply >= _value),
      "Insufficient availability"
    );
    _balances[_from] -= _value;
    ERCtotalSupply -= _value;
    emit Transfer(_from, Dead, _value);
  }

  function ERCtransferFrom(
    address _from,
    address _to,
    uint256 _value,
    address _origin
  ) public override returns (bool success) {

    // Deriving allowances
    uint256 _allowance = allowed[_from][_origin];
    
    // Safety check
    require(_balances[_from] >= _value, "token balance is lower than amount requested");
    require(_allowance >= _value, "token allowance  is lower than amount requested");
    
    // Executing transfer
    _balances[_to] += _value;
    _balances[_from] -= _value;
    emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
    
    // Avoid decreasing allowance for system addresses
    if (_allowance < MAX_UINT256) {
      allowed[_from][_origin] -= _value;
    }

    return true;
  }

  // transferFrom for ERC20 interface reserved for liquidity transfers
  // allowance isn't even checked as liquidity transfers are always legit coming from either CA or LP
  function liquidityERCtransferFrom(
    address _from,
    address _to,
    uint256 _value
  ) internal returns (bool success) {

    // Safety check
    require(_balances[_from] >= _value, "token balance is lower than amount requested");
    
    // Executing transfer
    _balances[_to] += _value;
    _balances[_from] -= _value;
    emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars

    return true;
  }

  function ERCbalanceOf(address _owner)
    public
    view
    override
    returns (uint256 balance)
  {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender)
    public
    view
    override
    returns (uint256 remaining)
  {
    // REVIEW Auto allowance for system addresses
    uint MAX = MAX_UINT256;
    if(derived.is_auth[_spender]) {
      return MAX;
    } else {
      return allowed[_owner][_spender];
    }
  }

  function approve(address _spender, uint256 _value) public override returns (bool success) {
    bool result = ERCapprove(msg.sender, _spender, _value);
    return result;
  }

  function ERCapprove(address _from, address _spender, uint256 _value)
    internal
    returns (bool success)
  {
    allowed[_from][_spender] = _value;
    emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
    return true;
  }

  // TODO  Find a way to implement decimals (like 0.01 = 1 NFT)
  /// @dev Decimals must be 0 in this case, as every token is an NFT and so is not divisible
  /// WIP: Can be done in the opposite way, maybe. NFT can always represent 1*decimals but
  ///      how to manage transfers of half tokens?
  function decimals() public pure override returns (uint256) {
    return 0;
  }

  // !SECTION

  // SECTION ERC721 Compatibility

  /* ================================================================================================== */
  /* ================================================================================================== */
  /* ============================================ NFT Part ============================================ */
  /* ================================================================================================== */
  /* ================================================================================================== */

  /*
    NFT Properties are defined here and are compliant with ERC721 standard
    */

  function _setBaseURI(string memory newURI) public onlyAuth {
    baseURI = newURI;
  }

  function _baseURI() internal view returns (string memory) {
    return baseURI;
  }

  function NFT_mint(uint256 quantity) internal {
    coinPrice = getTokenPrice(1);
    // _safeMint's second argument now takes in a quantity, not a tokenId.
    if (!(coinPrice == 0)) {
      require(msg.value == coinPrice, "Price not reached");
    }
    if (!(MaxNftMintable == 0)) {
      require(
        (NFTtotalSupply() + quantity) <= MaxNftMintable,
        "Max emission reached"
      );
    }
    _mint(msg.sender, quantity);
  }

  // !SECTION

  // SECTION Liquid Functions

  /* ==================================================================================================== */
  /* ==================================================================================================== */
  /* ======================================== Liquid Functions ========================================== */
  /* ==================================================================================================== */
  /* ==================================================================================================== */

  struct LIQUID_STAKE {
    uint256[] staked_ids;
  }

  mapping(address => LIQUID_STAKE) Liquid_Stakes;

  mapping(uint256 => uint8) token_rarities;

  /// @dev Set max number of mintable Liquid Tokens
  // @param max Max number of mintable Liquid Tokens
  function setMaxMintable(uint256 max) public onlyAuth {
    MaxNftMintable = max;
  }

  ///@dev Set rarity at mint
  //@param Boolean
  function SetRarityAtMintControl(bool setter) public onlyAuth {
    SetRarityAtMint = setter;
  }

  /// @dev Manual rarity assign for an array of tokens
  // @param tokens A list of tokens to assign rarity to
  function setRarityBatch(uint256[] calldata tokens)
    public
    onlyAuth
    returns (bool success)
  {
    assign_rarity_batch(tokens);
    return true;
  }

  /// @dev Linking NFT mint and token creation
  function mint(uint256 quantity) public payable {
    if (SetRarityAtMint) {
      assign_rarity(quantity);
    }
    NFT_mint(quantity);
    mintToken(msg.sender, quantity);
  }

  /// @dev Very near to random function (supports up to 8 bit)
  function random_8bit(uint8 max) private view returns (uint8) {
    // sha3 and now have been deprecated
    uint256 r_uint = uint256(
      keccak256(
        abi.encodePacked(block.difficulty, block.timestamp, _totalMinted())
      )
    );
    while (r_uint > max) {
      r_uint -= max;
    }
    uint8 result = uint8(r_uint);
    return result;
    // convert hash to integer
    // players is an array of entrants
  }

  function calculate_luck(address target) public view returns (uint16 luck) {
    uint16 target_luck = 0;
    /// To catch all the NFTs of an user, i will increase only when ownership is asserted through
    //  bitwise operations (to be more efficient than bool).
    /// In the same case, with just another operation on 8 bit, we automatically increase the luck
    /// value through rarity retrieving
    for (uint8 i; i < (NFTbalanceOf(target)); i) {
      address owner_of = owner_of_nft(i);
      i += ((owner_of == msg.sender) ? 1 : 0);
      target_luck += ((owner_of == msg.sender) ? get_rarity(i) : 0);
    }
    return target_luck;
  }

  /// Assigning rarity is lightened by:
  /// - Using a 8 bit random generated fully in memory
  /// - Assigning to the 8 bit mapping (so saving on packed gas)
  ///     the random value without evaluations
  /// We are doing this because we let to get_rarity the evaluation task
  /// of returning the rarity without even storing it through bitwise operations

  /// @dev Assigning rarity
  // @param tokens Number of tokens to assign to
  function assign_rarity(uint256 quantity) internal {
    uint256 starting_point = _totalMinted() + 1;
    uint8 rand;

    for (uint256 i = starting_point; i < quantity; i++) {
      rand = random_8bit(100);
      token_rarities[i] = rand;
    }
  }

  /// @dev Assigning rarity in batch
  // @param tokens A list of tokens to assign rarity to
  function assign_rarity_batch(uint256[] calldata tokens) internal {
    uint8 rand;

    for (uint256 i = 0; i < tokens.length; i++) {
      rand = random_8bit(100);
      token_rarities[tokens[i]] = rand;
    }
  }

  /// Rarity isn't statically stored but is obtained with almost no effort from
  /// in-memory variables and constants through bitwise operations adding 1 or 0
  /// to the rarity based on boundaries defining N types of rarity
  function get_rarity(uint256 id) public view returns (uint8 rarity) {
    /// Adding 0 for every boundary crossed (ex. if out of rare range, add 0), otherwise is 1
    uint8 _rarity = token_rarities[id];
    uint16 luck = calculate_luck(msg.sender);
    return (((_rarity < (3 + luck)) ? 1 : 0) +
      ((_rarity < (7 + luck)) ? 1 : 0) +
      ((_rarity < (10 + luck)) ? 1 : 0)); /// Ex.: _rarity = 8
    ///      rarity = 0 (common) +
    ///               1 (as is < 10) +
    ///               0 (as is >= 7) +
    ///               0 (as is >= 3) =
    ///
    ///               1 (meaning Uncommon 1)
    ///
    /// Ex.: _rarity = 2
    ///      rarity = 0 (common) +
    ///               1 (as is < 10) +
    ///               1 (as is < 7) +
    ///               1 (as is < 3) =
    ///
    ///               3 (meaning Rare)
  }

  function stake_common_liquids(uint256 amount) public payable safe {}

  function stake_special_liquids(uint256[] calldata ids) public payable safe {}

  // !SECTION
}

// !SECTION

// SECTION Smart Liquid Launchpad

contract FluidFactory {
  mapping(address => bool) public owner;
  bool public PrivateDeploy = true;
  string public MakerIdentifier;
  uint256 public DeployPrice;
  address initialDeploy;

  uint256 max__ = 5000;

  constructor(
    string memory name__,
    string memory ticker__,
    string memory identifier,
    uint256 price
  ) {
    owner[msg.sender] = true;
    DeployPrice = price;
    MakerIdentifier = identifier;
    name__ = string.concat(name__, " - ", MakerIdentifier);
    initialDeploy = emit_a_different_token(name__, ticker__, max__);
  }

  function set_private_deploy(bool is_private) public {
    require(owner[msg.sender], "403");
    PrivateDeploy = is_private;
  }

  function address_is_owner(bool is_it) public {
    require(owner[msg.sender], "403");
    owner[msg.sender] = is_it;
  }

  function change_deploy_price(uint256 price) public {
    require(owner[msg.sender], "403");
    DeployPrice = price;
  }

  function emit_a_different_token(
    string memory _name,
    string memory _ticker,
    uint256 __max__
  ) public payable returns (address deployed) {
    if (PrivateDeploy) {
      require(owner[msg.sender], "403");
    }
    if (DeployPrice > 0) {
      require(msg.value >= DeployPrice);
    }
    // REVIEW Is this even needed at this point? Temporarily setting max__ to the desired value
    uint256 oldMax = max__;
    max__ = __max__;
    address new_address = address(new LiquidToken(_name, _ticker, max__));
    max__ = oldMax;

    return new_address;
  }
}

// !SECTION