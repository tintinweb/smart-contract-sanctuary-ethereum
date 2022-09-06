/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface INFTFACTORY
{

    /****************************Author: CMarchese*********************************/
    /*******************Deployed: 0x0E995bbe4E86520E7e68C6fe14E6954842Eef503*******/

    //information
    function getPrice(uint256 _tokenId) external view returns(uint256 _price);
    function expiration(uint256 _tokenId) external view returns(uint256);

    // Wallets
    function nftProvider(uint256) external view returns (address);
    function nftEmbasador(uint256) external view returns (address);
    function nftOwner(uint256) external view returns (address);
    function ownerOf(uint256) external view returns (address);
    function nftDeveloper() external view returns (address);
    function nftDAO() external view returns (address);
    function nftCompany() external view returns (address);
    function nftUser() external view returns (address);


    //functions (write)
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

interface IVESTING
{
    function mintWithVesting(address _to,uint256 _amount, uint256 _tokenId, uint256 _vestingTime) external returns(bool _success);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract CMARKETPLACE
{
    INFTFACTORY private i_nft_factory_Contract;
    IVESTING private i_my_token_Contract;

    //Tokenomics set in the constructor
    uint32 public  OwnerBenefit; //90 %
    uint32 public  ProviderBenefit; // 0.2% -> in first time selling this amount goes to companyBenefit
    uint32 public  EmbasadorBenefit; // 2%
    uint32 public  DeveloperBenefit; // 2.5%
    uint32 public  DaoBenefit; // 1%
    uint32 public  CompanyBenefit; // 2.3%
    uint32 public  UserBenefit; // 2%

    //addresses
    address private Erc20; //address of marketplace
    address private NftFactory; //address of marketplace
    address private Owner;

    // modifiers
    modifier onlyOwner() 
    {
        require(msg.sender==Owner,"Your are not the market owner");
        _;
    }

    //set tokenomics
    function setOwnerBenefit(uint32 _perThousand) onlyOwner external returns(bool _success)
    {
        OwnerBenefit=_perThousand;
        _success=true;
        return(_success);
    }
    function setProviderBenefit(uint32 _perThousand) onlyOwner external returns(bool _success)
    {
        ProviderBenefit=_perThousand;
        _success=true;
        return(_success);
    }
    function setEmbasadorBenefit(uint32 _perThousand) onlyOwner external returns(bool _success)
    {
        EmbasadorBenefit=_perThousand;
        _success=true;
        return(_success);
    }
   function setDeveloperBenefit(uint32 _perThousand) onlyOwner external returns(bool _success)
    {
        DeveloperBenefit=_perThousand;
        _success=true;
        return(_success);
    }
   function setDaoBenefit(uint32 _perThousand) onlyOwner external returns(bool _success)
    {
       DaoBenefit=_perThousand;
        _success=true;
        return(_success);
    }
   function setCompanyBenefit(uint32 _perThousand) onlyOwner external returns(bool _success)
    {
       CompanyBenefit=_perThousand;
        _success=true;
        return(_success);
    }
    function setUserBenefit(uint32 _perThousand) onlyOwner external returns(bool _success)
    {
      UserBenefit=_perThousand;
        _success=true;
        return(_success);
    }


    // constructor
    constructor(address _ERC20, address _NFT)
    {
        // interface to talk to
        i_my_token_Contract=IVESTING(_ERC20);
        i_nft_factory_Contract= INFTFACTORY(_NFT);

        // benefits to the wallets (tokenimics)
        OwnerBenefit=900; // 900 per 1000   (90%)
        ProviderBenefit=50; // 2 per 1000   (5%)
        EmbasadorBenefit=50; // 20 per 1000 (5%)
        /*
        DeveloperBenefit=25; // 25 per 1000
        DaoBenefit=10; // 10 per 1000
        UserBenefit=20; // 20 per 1000
        CompanyBenefit=23; // 23 per 1000... (the rest after giving the tokens to each part)
        */
        Owner=msg.sender;

    }





    function getNftPrice(uint256 _tokenId) public  view returns(uint256 _price){
        _price=i_nft_factory_Contract.getPrice(_tokenId);
        return(_price);
    }
    function transferERC20( address _from, address _to, uint256 _amount) private  returns(bool _success){
        _success=i_my_token_Contract.transferFrom(_from, _to, _amount);
        if(_success!=true)
        {
            _success=false;
        }
        return(_success);
    }
    function burnERC20(uint256 _amount) private  returns(bool _success){
        _success=i_my_token_Contract.transferFrom(msg.sender, address(0x06Eb67071a06E676b678F5dd3614D852C129d460), _amount);
        if(_success!=true)
        {
            _success=false;
        }
        return(_success);
    }
    function mintERC20(address _to, uint256 _amount, uint256 _vestingTime,uint256 _tokenId) private  returns(bool _success){
        //uint256 _vestingTime= i_nft_factory_Contract.expiration(_tokenId);
        _success=i_my_token_Contract.mintWithVesting(_to, _amount, _tokenId, _vestingTime);
        if(_success!=true)
        {
            _success=false;
        }
        return(_success);
    }
    function getVestingTime(uint256 _tokenId) public view returns(uint256 _vestingTime){
        _vestingTime= i_nft_factory_Contract.expiration(_tokenId);
        return(_vestingTime);
    }
    function transferNft(address _from, uint256 _tokenId) private returns(bool _success){
        address _to=msg.sender;
        i_nft_factory_Contract.safeTransferFrom(_from, _to, _tokenId);
        _success=true;
        return(_success);
    }
    function getNftOwner(uint256 _tokenId) public view returns(address _owner){
        _owner= i_nft_factory_Contract.ownerOf(_tokenId);
        return(_owner);
    }

/*previously to this function the seller should have given permision to this contract to transfer the NFT in the NFT factory contract by calling: sellNft(uint256 _tokenId, uint256 _price).
Previously to this function the buyer should have given permision to this contract to  transfer the ERC20 token from their account in the ERC20 token contract by calling: approve(address spender, uint256 amount)// amount should be a huge value. sepnder is the address of this smart contract
*/
    function Buy(uint256 _tokenId) public returns(bool _success)
    {
        uint256 _BurningAmount;
        // we transfer the ERC20 tokens from the buyer to the 0x0 (we burn them)
        _BurningAmount=getNftPrice(_tokenId);
        _success=burnERC20(_BurningAmount);
        require(_success==true,"Tokens did not burn");
        // we transfer the NFT from the seller to the user
        address _from=getNftOwner(_tokenId);
        require( _from != address(0x0) ,"I could ot get the token Owner");
        address _to=msg.sender;
        _success=transferNft(_from,_tokenId);
        require(_success==true,"NFT could not be transfered");
        // then we mint ERC20 tokens to all the following addresses.
        // minting to owner
        _to=_from;
        uint256 _amount=( _BurningAmount*OwnerBenefit ) /1000;
        require(_amount!=0,"Tokens to be minted cannot be 0");
        uint256 _vestingTime= getVestingTime(_tokenId);
        require(_vestingTime!=0,"vesting time to be minted cannot be 0");
        _success=mintERC20(_to, _amount, _vestingTime, _tokenId);
        require(_success==true,"I could not mint ERC20 token to the NFT owner so I should revert");

        // minting to Provider
        _to=i_nft_factory_Contract.nftProvider(_tokenId);
        _amount=( _BurningAmount*ProviderBenefit ) /1000;
        _success=i_my_token_Contract.mintWithVesting(_to, _amount, _tokenId, _vestingTime);
        require(_success==true,"I could not mint ERC20 token to the NFT provider so I should revert");

        // minting to Embasador
        _to=i_nft_factory_Contract.nftEmbasador(_tokenId);
        _amount=( _BurningAmount*EmbasadorBenefit ) /1000;
        _success=i_my_token_Contract.mintWithVesting(_to, _amount, _tokenId, _vestingTime);
        require(_success==true,"I could not mint ERC20 token to the NFT embasador so I should revert");
/*
        // minting to Developer
        _to=i_nft_factory_Contract.nftDeveloper();
        _amount=( _BurningAmount*DeveloperBenefit ) /1000;
        _success=i_my_token_Contract.mintWithVesting(_to, _amount, _tokenId, _vestingTime);
        require(_success==true,"I could not mint ERC20 token to the NFT developers so I should revert");

        // minting to DAO
        _to=i_nft_factory_Contract.nftDAO();
        _amount=( _BurningAmount*DaoBenefit ) /1000;
        _success=i_my_token_Contract.mintWithVesting(_to, _amount, _tokenId, _vestingTime);
        require(_success==true,"I could not mint ERC20 token to the DAO so I should revert");

        // minting to Company
        _to=i_nft_factory_Contract.nftCompany();
        _amount=( _BurningAmount*CompanyBenefit ) /1000;
        _success=i_my_token_Contract.mintWithVesting(_to, _amount, _tokenId, _vestingTime);
        require(_success==true,"I could not mint ERC20 token to the NFT company so I should revert");

        // minting to User
        _to=i_nft_factory_Contract.nftUser();
        _amount=( _BurningAmount*UserBenefit ) /1000;
        _success=i_my_token_Contract.mintWithVesting(_to, _amount, _tokenId, _vestingTime);
        require(_success==true,"I could not mint ERC20 token to the NFT users so I should revert");
    */
        return(_success);
    }

/****************************End Author: CMarchese*********************************/

}