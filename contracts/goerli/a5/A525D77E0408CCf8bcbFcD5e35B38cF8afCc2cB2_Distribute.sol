/**
 *Submitted for verification at polygonscan.com on 2022-06-22
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

// SPDX-License-Identifier: MIT

// File: GGDAO/contracts/Distribute Contract/ownable.sol

pragma solidity 0.8.7;

contract Ownable 
{

  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor()
  {
    owner = msg.sender;
  }
  
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}
// File: GGDAO/contracts/Distribute Contract/distribute.sol

pragma solidity ^0.8.7;

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface ERC20 {
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
    function balanceOf(address account) external view returns (uint256);
}

interface GG {
    function mint(uint256 _amount, address _to) external;
}

interface HOLDERS {
    function getHolders() external view returns (address[] memory);
}

contract Distribute is Ownable {

    mapping(address => bool) kycStatus;
    mapping(address => uint256) foundersWETHBalance;
    mapping(address => uint256) foundersGGBalance;
    mapping(address => uint256) genesisWETHBalance;
    mapping(address => uint256) genesisGGBalance;
    mapping(uint256 => uint256) genesisBalance;
    mapping(uint256 => uint256) genesisTimestamp;
    mapping(uint256 => uint256) foundersBalance;
    mapping(uint256 => uint256) foundersTimestamp;

    address[] public teamAddresses;
    address[] public partners;
    address genContract;
    address founderContract;
    address GGContract;
    address WETHContract;
    address CommunityWallet;
    uint256 public foundersAccrualPerSecond;
    uint256 public genesisAccrualPerSecond;

    constructor() {
        genesisAccrualPerSecond = 1188966400000000;
        foundersAccrualPerSecond = 158428390000000;
    }


    function setGenContract(address _contract) public onlyOwner {
        genContract = _contract;
    }
    function setCommunityWallet(address _contract) public onlyOwner {
        CommunityWallet = _contract;
    }

    function setFounderContract(address _contract) public onlyOwner {
        founderContract = _contract;
    }

    function setWETHContract(address _addy) public onlyOwner {
        WETHContract = _addy;
    }

    function setGGContract(address _contract) public onlyOwner {
        GGContract = _contract;
    }

    function setPartners(address[] memory _addresses) public onlyOwner {
        partners = _addresses;
    }

    function genesisHolders() public view returns(uint256) {
        return HOLDERS(0x78F4e05580C4703C48Df7DBB5a9FFdC9a804C76B).getHolders().length;
    }

    function addClaimableWETHFounders(uint256 amount) public {
        ERC20(WETHContract).transferFrom(msg.sender, address(this), amount);
        uint256 individualAmount = amount/99;
        for(uint256 i=1;i<100;i++){ foundersWETHBalance[ERC721(founderContract).ownerOf(i)] += individualAmount; }
    }

    function addClaimableGGFounders(uint256 amount) public {
        ERC20(GGContract).transferFrom(msg.sender, address(this), amount);
        uint256 individualAmount = amount/99;
        for(uint256 i=1;i<100;i++){ foundersGGBalance[ERC721(founderContract).ownerOf(i)] += individualAmount; }
    }

    function addClaimableWETHGenesis(uint256 amount) public {
        ERC20(WETHContract).transferFrom(msg.sender, address(this), amount);
        uint256 holders = genesisHolders();
        uint256 individualAmount = amount/holders; 
        for(uint256 i=1;i<(holders+1);i++){ genesisWETHBalance[ERC721(genContract).ownerOf(i)] += individualAmount; }
    }

    function addClaimableGGGenesis(uint256 amount) public {
        ERC20(GGContract).transferFrom(msg.sender, address(this), amount);
        uint256 holders = genesisHolders();
        uint256 individualAmount = amount/holders; 
        for(uint256 i=1;i<(holders+1);i++){ genesisGGBalance[ERC721(genContract).ownerOf(i)] += individualAmount; }
    }

    function characterSecondary(uint256 amount) public {
        ERC20(WETHContract).transferFrom(msg.sender, address(this), amount);
        uint256 foundersSplit = (amount*2)/990;
        uint256 holders = genesisHolders();
        uint256 genesisSplit = ((amount*2)/10)/holders;
        for(uint256 i=1;i<100;i++){ foundersWETHBalance[ERC721(founderContract).ownerOf(i)] += foundersSplit; }
        for(uint256 i=1;i<(holders+1);i++){ genesisWETHBalance[ERC721(genContract).ownerOf(i)] += genesisSplit; }
        ERC20(WETHContract).transfer(partners[0], (amount*15)/100);
        ERC20(WETHContract).transfer(partners[1], (amount*15)/100);
        ERC20(WETHContract).transfer(partners[2], (amount*15)/100);
        ERC20(WETHContract).transfer(partners[3], (amount*15)/100);
    } 

    function foundersSecondary(uint256 amount) public {
        ERC20(WETHContract).transferFrom(msg.sender, address(this), amount);
        uint256 Split = ((amount*2)/10)/99;
        for(uint256 i=1;i<100;i++){ foundersWETHBalance[ERC721(founderContract).ownerOf(i)] += Split; }
        ERC20(WETHContract).transfer(partners[0], (amount*2)/10);
        ERC20(WETHContract).transfer(partners[1], (amount*2)/10);
        ERC20(WETHContract).transfer(partners[2], (amount*2)/10);
        ERC20(WETHContract).transfer(partners[3], (amount*2)/10);
    } 

    function genesisSecondary(uint256 amount) public {
        ERC20(WETHContract).transferFrom(msg.sender, address(this), amount);
        uint256 holders = genesisHolders();
        uint256 Split = ((amount*2)/10)/holders; 
        for(uint256 i=1;i<(holders+1);i++){ genesisWETHBalance[ERC721(genContract).ownerOf(i)] += Split; }
        ERC20(WETHContract).transfer(partners[0], (amount*2)/10);
        ERC20(WETHContract).transfer(partners[1], (amount*2)/10);
        ERC20(WETHContract).transfer(partners[2], (amount*2)/10);
        ERC20(WETHContract).transfer(partners[3], (amount*2)/10);
    } 

    function setGenesisAccrualPerSecond(uint256 _amount) public {
        require(isTeam(msg.sender));
        genesisAccrualPerSecond = _amount;
    }

    function setFoundersAccrualPerSecond(uint256 _amount) public {
        require(isTeam(msg.sender));
        foundersAccrualPerSecond = _amount;
    }

    function getGGAccrualFounder(uint256 _tokenID) public view returns(uint256) {
        if(foundersTimestamp[_tokenID] > 0){
            uint256 _seconds = block.timestamp - foundersTimestamp[_tokenID];
            uint256 amount = _seconds*foundersAccrualPerSecond;
            return(amount);
        }
        else{ return (62500000000000000000000); }
    }

    function getGGAccrualGenesis(uint256 _tokenID) public view returns(uint256) {
        if(genesisTimestamp[_tokenID] > 0){
            uint256 _seconds = block.timestamp - genesisTimestamp[_tokenID];
            uint256 amount = _seconds*genesisAccrualPerSecond;
            return(amount);
        }
        else{ return (1563000000000000000000); }
    }

    function getBalance(address _address) public view returns(uint256, uint256) {
        uint256 WETH;
        uint256 GG;
        if(foundersWETHBalance[_address] > 0){ WETH += foundersWETHBalance[_address]; }
        if(genesisWETHBalance[_address] > 0){ WETH += genesisWETHBalance[_address]; }
        if(foundersGGBalance[_address] > 0){ GG += foundersGGBalance[_address]; }
        if(genesisGGBalance[_address] > 0){ GG += genesisGGBalance[_address]; }
        return (WETH, GG);
    }

    function claimBalance(address _address) public{
        require(msg.sender == _address);
        // require(kycStatus[_address]);
        (uint256 _WETH, uint256 _GG) = getBalance(_address);
        foundersWETHBalance[_address] = 0;
        foundersGGBalance[_address] = 0;
        genesisWETHBalance[_address] = 0;
        genesisGGBalance[_address] = 0;
        ERC20(GGContract).transfer(msg.sender, _GG);
        ERC20(WETHContract).transfer(msg.sender, _WETH);
    }

    function setKYCAddress(address _address) public {
        require(isTeam(msg.sender));
        kycStatus[_address] = true;
    }

    function claimGGGenesis(uint256 _tokenID) public {
        require(msg.sender == ERC721(genContract).ownerOf(_tokenID), 'You do not own this token');
        // require(kycStatus[msg.sender]);
        uint256 amount = getGGAccrualGenesis(_tokenID);
        genesisTimestamp[_tokenID] = block.timestamp; 
        if (amount > 70000000000000000000000) {
            GG(GGContract).mint(70000000000000000000000, msg.sender);
            GG(GGContract).mint(((amount-70000000000000000000000)/2), CommunityWallet);
        } else {
        GG(GGContract).mint(amount, msg.sender);
        }
    }

    function claimGGFounder(uint256 _tokenID) public {
        require(msg.sender == ERC721(founderContract).ownerOf(_tokenID), 'You do not own this token');
        // require(kycStatus[msg.sender]); 
        uint256 amount = getGGAccrualFounder(_tokenID);
        foundersTimestamp[_tokenID] = block.timestamp;
        if (amount > 70000000000000000000000) {
            GG(GGContract).mint(70000000000000000000000, msg.sender);
            GG(GGContract).mint(((amount-70000000000000000000000)/2), CommunityWallet);
        } else {
        GG(GGContract).mint(amount, msg.sender);
        }
    }

    function batchClaimGGGenesis(uint256[] memory _tokenIds) public {
       for(uint8 i = 0; i < _tokenIds.length; i++){
            require(msg.sender == ERC721(genContract).ownerOf(_tokenIds[i]), 'You do not own this token');
            // require(kycStatus[msg.sender]);
            uint256 amount = getGGAccrualGenesis(_tokenIds[i]);
            genesisTimestamp[_tokenIds[i]] = block.timestamp; 
            if (amount > 70000000000000000000000) {
                GG(GGContract).mint(70000000000000000000000, msg.sender);
                GG(GGContract).mint(((amount-70000000000000000000000)/2), CommunityWallet);
            } else {
            GG(GGContract).mint(amount, msg.sender);
            }

       }

    }

    function batchClaimGGFounder(uint256[] memory _tokenIds) public {

     for(uint8 i = 0; i < _tokenIds.length; i++){
        require(msg.sender == ERC721(founderContract).ownerOf(_tokenIds[i]), 'You do not own this token');
        // require(kycStatus[msg.sender]); 
        uint256 amount = getGGAccrualFounder(_tokenIds[i]);
        foundersTimestamp[_tokenIds[i]] = block.timestamp;
        if (amount > 70000000000000000000000) {
            GG(GGContract).mint(70000000000000000000000, msg.sender);
            GG(GGContract).mint(((amount-70000000000000000000000)/2), CommunityWallet);
        } else {
        GG(GGContract).mint(amount, msg.sender);
        }
     }

    }
    
    function isTeam(address[] calldata _users) public onlyOwner {
      delete teamAddresses;
      teamAddresses = _users;
    }

    function isTeam(address _user) public view returns (bool) {
      for (uint i=0;i<teamAddresses.length;i++) { 
          if (teamAddresses[i] == _user) { return true; } }
      return false;
    }


    function extractWETH() external onlyOwner {
      ERC20(WETHContract).transfer(msg.sender, ERC20(WETHContract).balanceOf(address(this)));
    }

    function extractGG() external onlyOwner {
      ERC20(GGContract).transfer(msg.sender, ERC20(WETHContract).balanceOf(address(this)));
    }

}