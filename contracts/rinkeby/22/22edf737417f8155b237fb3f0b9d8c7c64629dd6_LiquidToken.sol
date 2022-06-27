/// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;


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


/* ********************+******** 

Actual Implementation

****************************** */



contract LiquidToken is iNFToken {
                              
    /// @dev Library using fast array manipulation methods for unsorted arrays
    using ArrayDegas for uint16[];

    bool SetRarityAtMint = false;
    uint MaxNftMintable;

   constructor(string memory _name_, string memory _symbol,  uint max__) 
    ERC721E(NFTName, NFTicker) {  
        owner = msg.sender;
        MaxNftMintable = max__;
        is_auth[owner] == true;
        router = IUniswapV2Router02(router_address);
        factory_address  = router.factory();
        factory = IUniswapV2Factory(factory_address);
        ERC_Liquidity_Address = factory.createPair(address(this), router.WETH());
        pair = IUniswapV2Pair(ERC_Liquidity_Address);
        
        name = _name_;
        symbol = _symbol;
        
        NFTName = name;
        NFTicker = symbol;
        mint(1);
        _setBaseURI("https://tcsenpai.mypinata.cloud/ipfs/Qmd6UvKHVjphJdj6JvgFdgt6nEQfAxwvk2kRMZiZf3Rwnh/");
    }

  

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

    function totalSupply() public view override returns(uint tkn, uint nftkn){
        uint _tkn = ERCtotalSupply;
        uint _nftkn = NFTtotalSupply();

        return(_tkn, _nftkn);
    }

    function balanceOf(address _owner) public view override returns(uint tkn, uint nftkn) {
        uint _tkn = ERCbalanceOf(_owner);
        uint _nftkn = NFTbalanceOf(_owner);
        return(_tkn, _nftkn);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId) public override returns(bool tkn) {

            bool success = ERCtransferFrom(from, to, 1);
            NFTtransferFrom(from, to, tokenId);
            return(success);
    }


    function owner_of_nft(uint id) public view returns (address ownerOfTokenId) {
        return address(uint160(_packedOwnershipOf(id)));
    }

    function transfer(address _to, uint256 _value) public override safe returns (bool success) {
      // Standard ERC transfer
      bool _success = ERC_transfer(_to, _value);
      require(_success, "transfer failed");
       
      // TODO CHECK Transfer a corresponding number of NFTs
      _NFT_derive_transfer(msg.sender, _to, _value);

      return _success;
    }

    /* Admin Functions */


    /// @dev Native token paired price for target
    function getTokenPrice(uint amount) public view returns(uint)
    {
            
                (uint Res0, uint Res1,uint timestamp) = pair.getReserves();
                if(Res0==0 && Res1==0) {
                  return 0;
                }
                uint res0 = Res0;
                delete timestamp;
                return((amount*res0)/Res1); // return amount of token0 needed to buy token1
    }

    uint coinPrice;


  /* ==================================================================================================== */
  /* ==================================================================================================== */
  /* ============================================ ERC20 Part ============================================ */
  /* ==================================================================================================== */
  /* ==================================================================================================== */

    /*
    This part defines all the ERC20 standard properties
    */

  address Dead = 0x000000000000000000000000000000000000dEaD;

  uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public ERCtotalSupply;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name; // "The Altairian Dollar";                   //fancy name: eg Simon Bucks
    string public symbol; // "$AD";                 //An identifier: eg SBX

    string public NFTName;
    string public NFTicker;

    address router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 router;
    address factory_address;
    IUniswapV2Factory factory;
    address ERC_Liquidity_Address;
    IUniswapV2Pair pair;

    function ERC_transfer(address _to, uint256 _value) internal returns (bool success) {
        require(_balances[msg.sender] >= _value, "token balance is lower than the value requested");
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
      require((_balances[_from] >= _value) && (ERCtotalSupply >= _value), "Insufficient availability");
      _balances[_from] -= _value;
      ERCtotalSupply -= _value;
      emit Transfer(_from, Dead, _value);
    }

    function ERCtransferFrom(address _from, address _to, uint256 _value) public override onlyContract returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];
        require(_balances[_from] >= _value && _allowance >= _value, "token balance or allowance is lower than amount requested");
        _balances[_to] += _value;
        _balances[_from] -= _value;
        if (_allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function ERCbalanceOf(address _owner) public override view returns (uint256 balance) {
        return _balances[_owner];
    }


    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function ERCapprove(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    /// @dev Decimals must be 0 in this case, as every token is an NFT and so is not divisible
    /// WIP: Can be done in the opposite way, maybe. NFT can always represent 1*decimals but
    ///      how to manage transfers of half tokens?
    function decimals() public pure override returns (uint) {
        return 0;
    }

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
    if(!(coinPrice==0)) {
      require(msg.value==coinPrice, "Price not reached");
    }
    if(!(MaxNftMintable==0)) {
      require((NFTtotalSupply()+quantity) <= MaxNftMintable, "Max emission reached");
    }
    _mint(msg.sender, quantity);

  }


  /* ==================================================================================================== */
  /* ==================================================================================================== */
  /* ======================================== Machine Functions ========================================= */
  /* ==================================================================================================== */
  /* ==================================================================================================== */

    
    struct LIQUID_STAKE {
        uint[] staked_ids;
    }

    mapping(address => LIQUID_STAKE) Liquid_Stakes;
    
    mapping(uint => uint8) token_rarities;

    /// @dev Set max number of mintable Liquid Tokens
    // @param max Max number of mintable Liquid Tokens
    function setMaxMintable(uint max) public onlyAuth {
      MaxNftMintable = max;
    }

    ///@dev Set rarity at mint
    //@param Boolean
    function SetRarityAtMintControl(bool setter) public onlyAuth {
      SetRarityAtMint = setter;
    }

   /// @dev Manual rarity assign for an array of tokens
   // @param tokens A list of tokens to assign rarity to 
   function setRarityBatch(uint[] calldata tokens) public onlyAuth returns(bool success) {
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
        uint r_uint = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _totalMinted())));
        while (r_uint > max) {
            r_uint -= max;
        }
        uint8 result = uint8(r_uint);
        return result;
        // convert hash to integer
        // players is an array of entrants
    
    }

    function calculate_luck(address target) public view returns(uint16 luck) {
        uint16 target_luck = 0;
        /// To catch all the NFTs of an user, i will increase only when ownership is asserted through 
        //  bitwise operations (to be more efficient than bool).
        /// In the same case, with just another operation on 8 bit, we automatically increase the luck
        /// value through rarity retrieving
        for(uint8 i; i < (NFTbalanceOf(target)); i) {
                address owner_of = owner_of_nft(i);
                i += ((owner_of==msg.sender) ? 1 : 0);
                target_luck += ((owner_of==msg.sender) ? get_rarity(i) : 0);
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
    function assign_rarity(uint quantity) internal {
        uint starting_point = _totalMinted()+1;
        uint8 rand;

        for(uint i = starting_point; i < quantity; i++) {
            rand = random_8bit(100);
            token_rarities[i] = rand;
        } 
    }

    /// @dev Assigning rarity in batch 
    // @param tokens A list of tokens to assign rarity to 
    function assign_rarity_batch(uint[] calldata tokens) internal {
        uint8 rand;

        for(uint i = 0; i < tokens.length; i++) {
            rand = random_8bit(100);
            token_rarities[tokens[i]] = rand;
        } 
    }

    /// Rarity isn't statically stored but is obtained with almost no effort from
    /// in-memory variables and constants through bitwise operations adding 1 or 0
    /// to the rarity based on boundaries defining N types of rarity
    function get_rarity(uint id) public view returns(uint8 rarity) {
        /// Adding 0 for every boundary crossed (ex. if out of rare range, add 0), otherwise is 1
        uint8 _rarity = token_rarities[id];
        uint16 luck = calculate_luck(msg.sender);
        return ( ((_rarity < (3+luck)) ? 1 : 0) + 
                 ((_rarity < (7+luck)) ? 1 : 0) + 
                 ((_rarity < (10+luck)) ? 1 : 0) );  /// Ex.: _rarity = 8
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

    function stake_common_liquids(uint amount) public payable safe {

    }

    function stake_special_liquids(uint[] calldata ids) public payable safe {
    
    }

  
}

contract FluidFactory {

    mapping(address => bool) public owner;
    bool public PrivateDeploy = true;
    string public MakerIdentifier;
    uint public DeployPrice;
    address initialDeploy;

    constructor(string memory name__, string memory ticker__, uint max__, 
                string memory identifier, uint price) {
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

    function change_deploy_price(uint price) public {
        require(owner[msg.sender], "403");
        DeployPrice = price;
    }

    function emit_a_different_token(string memory _name, string memory _ticker,  uint max__) 
    public payable returns(address deployed) {
        if(PrivateDeploy) {
            require(owner[msg.sender], "403");
        }
        if(DeployPrice > 0) {
            require(msg.value>=DeployPrice);
        }
        address new_address = address(new LiquidToken(_name, _ticker, max__));
        return new_address;
    }

}