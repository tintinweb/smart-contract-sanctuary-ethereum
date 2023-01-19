/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view  returns (uint8);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}






contract LaundhPadMaking {

    struct ICO {
        uint ind;
        address _address;
        address[] _token_owner_admin_currency;
        string[] _title_symbol_SocialMedia;
        uint256[] _noOfTokens_price_max_min_vesting_month_start_end;
        string _hash;
        address[] _whitelist;
        uint investedBUSD;
        uint investedTokens;
     }
    

    address public admin;

    uint256 public ICOIndex;
    mapping(address=>uint256) public ICOMapping;
    ICO[] public ICOArray;



    constructor(){
        admin = 0xBC0f54cd2beAB10A0d5DC97f63B2Be1825F1E938;//0xF85ee861F7360E5882FE1efE8DFc29C204d4BfaE;//msg.sender;//0xF85ee861F7360E5882FE1efE8DFc29C204d4BfaE;
    }

    //Modifiers 
     modifier onlyAdmin {
      require(msg.sender == admin);
      _;
     }



     function createICO(
        address[]  memory _token_owner_admin_currency,
        string[] memory _title_symbol_SocialMedia,
        uint256[] memory _noOfTokens_price_max_min_vesting_month_start_end,
        string memory _hash,
        address[] memory _whitelist
        
     ) public  {

         ICOSale2 tx1 = new ICOSale2(
            _token_owner_admin_currency,_title_symbol_SocialMedia,_noOfTokens_price_max_min_vesting_month_start_end,_hash,_whitelist
             );
          ICOMapping[address(tx1)]=ICOIndex;
         ICO memory tx2 = ICO(
            ICOIndex,
            address(tx1),
            _token_owner_admin_currency,
            _title_symbol_SocialMedia,
            _noOfTokens_price_max_min_vesting_month_start_end,
            _hash,_whitelist,0,0             
         );
          ICOArray.push(tx2);
         ICOIndex++;
        IERC20 _Token = IERC20(_token_owner_admin_currency[0]);
        _Token.approve(address(tx1),_noOfTokens_price_max_min_vesting_month_start_end[0]);

     }

     struct IGOData{
         uint investedBUSD;
         uint investedTokens;
     }




     function getPoolDetails() public view returns(ICO[] memory, IGOData[] memory){
         IGOData[] memory arr1 = new IGOData[](ICOArray.length);
         for(uint i = 0 ; i < ICOArray.length ; i ++){
             ICOSale2 tx1 = ICOSale2(ICOArray[i]._address);
             (,,uint investedBUSD, uint investedTokens) = tx1.selfInfo();
             IGOData memory tx2 = IGOData(investedBUSD,investedTokens);
             arr1[i] = tx2;
            
         }
         return (ICOArray,arr1);
     }

}

contract ICOSale2 {

    address public admin;
    address public factory;
//    IERC20 BUSD = IERC20(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684);
    //Modifiers 
     modifier onlyAdmin {
      require(msg.sender == admin);
      _;
     }

     mapping(address=>uint256) public userEntitlement;
     mapping(address=>uint256) public noOfClaims;
    mapping(address=>uint256) public totalClaimed;

    struct ICO {
      address _address;
        address[] _token_owner_admin_currency;
        string[] _title_symbol_SocialMedia;
        uint256[] _noOfTokens_price_max_min_vesting_month_start_end;
        string _hash;
        uint256 investedTokens;
        uint256 investedBUSD;
        address[] _whitelist;
    }

    ICO public selfInfo;

    constructor(
        address[] memory _token_owner_admin_currency,
        string[] memory _title_symbol_SocialMedia,
        uint256[] memory _noOfTokens_price_max_min_vesting_month_start_end,
        string memory _hash,
        address[] memory _whitelist
        ){
        selfInfo._address = address(this);
        selfInfo._title_symbol_SocialMedia = _title_symbol_SocialMedia;
        selfInfo._token_owner_admin_currency = _token_owner_admin_currency;
        selfInfo._hash = _hash;
        selfInfo._whitelist = _whitelist;
        selfInfo._noOfTokens_price_max_min_vesting_month_start_end = _noOfTokens_price_max_min_vesting_month_start_end; 
        admin = _token_owner_admin_currency[2];
        factory = msg.sender;
        selfInfo._whitelist = _whitelist;
        
   
    }


    function editPool(
        address[] memory _token_owner_admin_currency
        ,string[] memory _title_symbol_SocialMedia
        ,uint256[] memory _noOfTokens_price_max_min_vesting_month_start_end
        ,string memory _hash
        ,address[] memory _whitelist
        )public onlyAdmin{
        selfInfo._address = address(this);
        selfInfo._title_symbol_SocialMedia = _title_symbol_SocialMedia;
        selfInfo._token_owner_admin_currency = _token_owner_admin_currency;
        selfInfo._hash = _hash;
        selfInfo._whitelist = _whitelist;
        selfInfo._noOfTokens_price_max_min_vesting_month_start_end = _noOfTokens_price_max_min_vesting_month_start_end; 
        admin = _token_owner_admin_currency[2];
        factory = msg.sender;
        selfInfo._whitelist = _whitelist;
        
   
    }





    function claim() public {

        require(noOfClaims[msg.sender]<=selfInfo._noOfTokens_price_max_min_vesting_month_start_end[5],"You have already claimed");
        uint256 claimsNo = noOfClaims[msg.sender];
        require(selfInfo._noOfTokens_price_max_min_vesting_month_start_end[4]+(60*60*(claimsNo))<=block.timestamp,"you need to wait");
        uint256 noOfTokens = userEntitlement[msg.sender] / selfInfo._noOfTokens_price_max_min_vesting_month_start_end[5];
        require(noOfTokens<=(userEntitlement[msg.sender]-totalClaimed[msg.sender]),"You have already claimed more tokens");
        IERC20 Token = IERC20(selfInfo._token_owner_admin_currency[0]);
        noOfClaims[msg.sender]++;
        totalClaimed[msg.sender]+=noOfTokens;
        Token.transferFrom(selfInfo._token_owner_admin_currency[1],msg.sender,noOfTokens);
    }

    bool public publicSale = false;

    function Buy(uint _busd) public{
        IERC20 BUSD = IERC20(selfInfo._token_owner_admin_currency[3]);
        uint256 BUSDDecimals = BUSD.decimals();    
        IERC20 Token = IERC20(selfInfo._token_owner_admin_currency[0]);
        uint TokenDecimals = Token.decimals();

      
       if(!publicSale){
        require(whiteListCheck(msg.sender)==true,"you are not allowed to buy");
       }

        
 
        uint256 tokens = _busd * (10 ** TokenDecimals) / selfInfo._noOfTokens_price_max_min_vesting_month_start_end[1] ;
        uint256 NBUSD = _busd * (10 ** BUSDDecimals) / (10 ** 18);
        BUSD.transferFrom(msg.sender,selfInfo._token_owner_admin_currency[1],NBUSD);       
        userEntitlement[msg.sender]+=tokens;
        selfInfo.investedTokens+=tokens;
        selfInfo.investedBUSD+=_busd;
    }

    function getDetails() public view returns(address[]memory, uint[]memory,string[] memory,address[]memory, string memory) {
        return (
        selfInfo._token_owner_admin_currency,
        selfInfo._noOfTokens_price_max_min_vesting_month_start_end,
        selfInfo._title_symbol_SocialMedia,
        selfInfo._whitelist
        ,selfInfo._hash);
    }

    uint public whitelistCounter;
    mapping(address=>bool) public WhitelistMapping;

    function addWhiteListSingle(address _user) public onlyAdmin {
         WhitelistMapping[_user] = true;
         whitelistCounter++;
     }

    function removeWhiteListSingle(address _user) public onlyAdmin {
         WhitelistMapping[_user] = false;
         whitelistCounter--;
     }


    function addWhiteListBulk(address[] memory _users) public onlyAdmin {
         for(uint256 i = 0; i < _users.length; i++){
             WhitelistMapping[_users[i]]=true;
             whitelistCounter++;
         }
     }

    function removeWhiteListBulk(address[] memory _users) public onlyAdmin {
         for(uint256 i = 0; i < _users.length; i++){
             WhitelistMapping[_users[i]]=false;
             whitelistCounter--;
         }
     }

     function whiteListCheck(address _user) public view returns (bool _yes){
         for (uint i = 0 ; i < selfInfo._whitelist.length;i++){
              if(selfInfo._whitelist[i]==_user){
                  _yes = true;
              }  
         }
     }







}