/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
//import "@openzeppelin/contracts/access/Ownable.sol";
pragma solidity ^0.8.9;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: openzeppelin-solidity\contracts\access\Ownable.sol

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


interface StonkerNFT{

  function getHour(uint256 timestamp_) view external returns(uint256);
  function totalSupply() view external returns(uint256);
  function ownerOf(uint256 tokenId_) view external returns(address);
  struct stonkerNFTDetail {
    uint256 id;
		uint256 yieldEffectivity;
    uint256 mintedTimeStamp;
    uint256 mintBatch;
  }

  function stonkers(uint256 tokenId_) view external returns(uint256,uint256,uint256,uint256 );
  function stonkersOfOwner(address addr_) view external returns(stonkerNFTDetail[] memory);
  function mintedSpecies(uint256 species) view external returns(uint256);
}

interface USDCContract{
  function transfer (address recipient, uint256 amount) external;
  function balanceOf (address address_) external view returns(uint256);

}
contract StonkerDividend  is Ownable {
 
        //StonkerNFT internal stonkerNFT = StonkerNFT(0x3D9DD42643e30007C4d726051D04427E89eC2B49); //goerli
        //USDCContract internal USDC_ = USDCContract(0x07865c6E87B9F70255377e024ace6630C1Eaa37F); //goerli

//mainnet

        StonkerNFT internal stonkerNFT = StonkerNFT(0x6BdD2353D12a78FEa7487829adaB30bf391ae336); //mainnet
        USDCContract internal USDC_ = USDCContract(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //mainnet
        

        
        uint256 excludedYield;
        //address stonkerAddress  ;
        //address USDCAddress;
        uint256 lastDisbursementTime;
        address public stonkerTreasury;
        address public stonkerTax;
        
        //address [] excluded;
        mapping (address=>bool) isExcluded;
        mapping (address=>uint256) dividends;
        //mapping (address=>uint256) percentOwnership;
        uint256 totalClaimedDividends;
        mapping (address=>uint256) claimedDividends;
        mapping (uint256=>uint256) dividendHistory;
        uint256 [] dividendHistoryIndex;
        //uint256 [] population=[0,0,0,0];
        //uint256 totalYield = 0;

        struct claimDetail {
          uint256 claimTime;
          uint256 claimAmount;
        }
        struct dividendDetail {
          uint256 distributionTime;
          uint256 distributionAmount;
          uint256 stonkerId;
        }
        mapping (address=>dividendDetail[]) distributedDividends;
        mapping (address=>claimDetail[]) claimedDividendHistory;
  
        constructor(){
            isExcluded[0x2c3269b8eEb629d05C50f234baE1e5cBA0ff3062]=true;
            stonkerTax=0x2c3269b8eEb629d05C50f234baE1e5cBA0ff3062;
            stonkerTreasury=0x44e4c656d7E92Ea05a3ce8206387bf298637534f;
            lastDisbursementTime = block.timestamp;

        }
        function excludeAddress(address addr_) external onlyOwner{
          isExcluded[addr_]=true;
        }

        function includeAddress(address addr_) external onlyOwner{
          isExcluded[addr_]=false;
        }
        function getTotalDividendHistoryIndex() public view returns(uint256[] memory){
          return dividendHistoryIndex;
        }
        function setTreasuryAddress(address addr_) onlyOwner public {
          stonkerTreasury = addr_;
        }
        function setTaxAddress(address addr_) onlyOwner public {
          stonkerTax = addr_;
        }

        function getClaimableDividend(address addr_) public view returns(uint256){
          return dividends[addr_];
        }

        function getStonkerUSDCBalance() public view returns(uint256){
          return USDC_.balanceOf(address(this));
        }
        

        function getTotalClaimedDividends(address addr_) public view returns(uint256){
          return claimedDividends[addr_];
        }

        function getAllTotalClaimedDividends() public view returns(uint256){
          return totalClaimedDividends;
        }

        function getClaimHistory(address addr_) public view returns(claimDetail[] memory){
          return claimedDividendHistory[addr_];
        }
        function getDistributionHistory(address addr_) public view returns(dividendDetail[] memory){
          return distributedDividends[addr_];
        }

        function claim() public {
          //require(enableclaim,"claim disabled");
          require(dividends[msg.sender]>0,"zero dividend");
          uint256 amountToClaim = (70*dividends[msg.sender])/100;
          uint256 tax = (15*dividends[msg.sender])/100;
          USDC_.transfer(msg.sender, amountToClaim);
          USDC_.transfer(stonkerTreasury, tax);
          USDC_.transfer(stonkerTax, tax);
          claimedDividends[msg.sender]+=amountToClaim;
          claimDetail memory cd;
          cd.claimTime=block.timestamp;
          cd.claimAmount=amountToClaim;
          claimedDividendHistory[msg.sender].push(cd);
          totalClaimedDividends+=amountToClaim;
          dividends[msg.sender]=0;
        }

        function withdrawMoney() external onlyOwner{
          USDC_.transfer(msg.sender, USDC_.balanceOf(address(this)));
        }
        function getPopulationYield() public view returns(uint256){
          uint256 populationYield = stonkerNFT.mintedSpecies(0)*20+stonkerNFT.mintedSpecies(1)*16+stonkerNFT.mintedSpecies(2)*13+stonkerNFT.mintedSpecies(3)*10 - excludedYield;
          return populationYield;
        }

        function calculateAndDisburse(uint256 dividend) onlyOwner public {
            
            uint256 totalYield = 0;
            excludedYield = 0;
              for(uint256 i=0;i<stonkerNFT.totalSupply();i++){
                //address stonkerOwner = stonkerNFT.ownerOf(i);
                (, uint256 yieldEffectivity, uint256 mintedTimeStamp, ) = stonkerNFT.stonkers(i);
                if(isExcluded[stonkerNFT.ownerOf(i)]){
                  excludedYield+=yieldEffectivity;
                  continue;
                }
                if(mintedTimeStamp>lastDisbursementTime)continue;
                totalYield += yieldEffectivity;
              }
              
              uint256 dividendPerYield = dividend/totalYield;
              
              for(uint256 j=0;j<stonkerNFT.totalSupply();j++){
                
                (, uint256 yieldEffectivity, uint256 mintedTimeStamp, ) = stonkerNFT.stonkers(j);

                if(isExcluded[stonkerNFT.ownerOf(j)])continue;
                if(mintedTimeStamp>lastDisbursementTime)continue;
                dividends[stonkerNFT.ownerOf(j)]+=yieldEffectivity*dividendPerYield;
                dividendDetail memory dd;
                dd.stonkerId = j;
                dd.distributionTime = block.timestamp;
                dd.distributionAmount = yieldEffectivity*dividendPerYield;
                distributedDividends[stonkerNFT.ownerOf(j)].push(dd);
              } 

              lastDisbursementTime = block.timestamp;
              dividendHistory[lastDisbursementTime]=dividend;
              dividendHistoryIndex.push(lastDisbursementTime);

        }

}